import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/course_forum/data/models/forum_models.dart';
import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';
import 'forums_list_state.dart';

/// Forums List Cubit - loads conversations for the current user
class ForumsListCubit extends Cubit<ForumsListState> {
  final SupabaseClient _supabase;
  static const _tag = 'ForumsListCubit';
  bool _isSetCourseGroupEnabledRpcAvailable = true;
  bool _isGetInstructorForumCoursesRpcAvailable = true;

  ForumsListCubit(this._supabase) : super(const ForumsListState());

  /// Load conversations list
  Future<void> loadConversations({
    String? search,
    String? typeFilter,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: ForumsListStatus.loading,
        conversations: [],
        hasMore: false,
        searchQuery: search,
        typeFilter: typeFilter,
        clearTypeFilter: typeFilter == null,
      ));
    } else {
      emit(state.copyWith(status: ForumsListStatus.loading));
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(state.copyWith(
          status: ForumsListStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      final isInstructor = await _isInstructorUser(userId);
      final instructorCourses = isInstructor
          ? await _fetchInstructorForumCourses(userId)
          : const <InstructorForumCourse>[];

      final conversations = await _fetchConversations(
        typeFilter: typeFilter,
        search: search,
      );

      emit(state.copyWith(
        status: ForumsListStatus.success,
        conversations: conversations,
        isInstructor: isInstructor,
        instructorCourses: instructorCourses,
        hasMore: false, // RPC returns all at once
        clearTogglingCourseId: true,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadConversations error', e, s);
      emit(state.copyWith(
        status: ForumsListStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Set type filter and reload
  void setTypeFilter(String? typeFilter) {
    loadConversations(
      search: state.searchQuery,
      typeFilter: typeFilter,
      refresh: true,
    );
  }

  Future<void> toggleCourseGroup({
    required String courseId,
    required bool enabled,
  }) async {
    emit(state.copyWith(togglingCourseId: courseId));

    try {
      if (_isSetCourseGroupEnabledRpcAvailable) {
        await _supabase.rpc('set_course_group_enabled', params: {
          'p_course_id': courseId,
          'p_enabled': enabled,
        });
      } else {
        await _toggleCourseGroupFallback(courseId: courseId, enabled: enabled);
      }
    } catch (e, s) {
      if (_isMissingRpcFunction(e, 'set_course_group_enabled')) {
        _isSetCourseGroupEnabledRpcAvailable = false;
        AppLogger.w(
            '[$_tag] set_course_group_enabled rpc not found, using fallback');
      } else {
        AppLogger.w(
            '[$_tag] set_course_group_enabled rpc failed, trying fallback: $e');
      }
      try {
        await _toggleCourseGroupFallback(courseId: courseId, enabled: enabled);
      } catch (fallbackError, fallbackStack) {
        AppLogger.e('[$_tag] toggleCourseGroup fallback failed', fallbackError,
            fallbackStack);
      }
      if (!_isMissingRpcFunction(e, 'set_course_group_enabled')) {
        AppLogger.e('[$_tag] toggleCourseGroup error', e, s);
      }
    }

    await loadConversations(
      search: state.searchQuery,
      typeFilter: state.typeFilter,
      refresh: true,
    );
  }

  /// Fetch conversations using RPC
  Future<List<Conversation>> _fetchConversations({
    String? typeFilter,
    String? search,
  }) async {
    AppLogger.d(
        '[$_tag] _fetchConversations: type=$typeFilter, search=$search');

    final response = await _supabase.rpc('get_user_conversations', params: {
      'p_type': typeFilter,
    });

    var results = (response as List).map((r) {
      return ConversationModel.fromJson(r as Map<String, dynamic>);
    }).toList();

    // Client-side search filtering
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      results = results.where((c) {
        final title = c.displayTitle.toLowerCase();
        return title.contains(searchLower);
      }).toList();
    }

    AppLogger.success(
        '[$_tag] _fetchConversations: ${results.length} conversations');
    return results;
  }

  Future<bool> _isInstructorUser(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    final role = profile?['role'] as String?;
    return role == 'instructor' || role == 'admin';
  }

  Future<List<InstructorForumCourse>> _fetchInstructorForumCourses(
      String userId) async {
    if (_isGetInstructorForumCoursesRpcAvailable) {
      try {
        final response = await _supabase
            .rpc('get_instructor_forum_courses', params: {'p_user_id': userId});

        return (response as List).map((row) {
          return InstructorForumCourse(
            id: row['course_id'] as String,
            titleAr: row['title_ar'] as String? ?? '',
            titleEn: row['title_en'] as String? ?? '',
            hasGroup: row['has_group'] as bool? ?? false,
          );
        }).toList();
      } catch (e) {
        if (_isMissingRpcFunction(e, 'get_instructor_forum_courses')) {
          _isGetInstructorForumCoursesRpcAvailable = false;
          AppLogger.w(
              '[$_tag] get_instructor_forum_courses rpc not found, using fallback');
        } else {
          AppLogger.w(
              '[$_tag] get_instructor_forum_courses rpc failed, using fallback query: $e');
        }
      }
    }

    try {
      final coursesResponse = await _supabase
          .from('courses')
          .select('id, title_ar, title_en')
          .eq('instructor_id', userId)
          .order('created_at', ascending: false);

      final courses = coursesResponse as List;
      if (courses.isEmpty) return const [];

      final courseIds = courses.map((c) => c['id'] as String).toList();
      final groupsResponse = await _supabase
          .from('conversations')
          .select('course_id')
          .eq('type', 'multi')
          .inFilter('course_id', courseIds);

      final groupedCourseIds = (groupsResponse as List)
          .map((g) => g['course_id'] as String?)
          .whereType<String>()
          .toSet();

      return courses.map((c) {
        final courseId = c['id'] as String;
        return InstructorForumCourse(
          id: courseId,
          titleAr: c['title_ar'] as String? ?? '',
          titleEn: c['title_en'] as String? ?? '',
          hasGroup: groupedCourseIds.contains(courseId),
        );
      }).toList();
    } catch (fallbackError, fallbackStack) {
      AppLogger.e('[$_tag] fallback instructor course load failed',
          fallbackError, fallbackStack);
      return const [];
    }
  }

  Future<void> _toggleCourseGroupFallback({
    required String courseId,
    required bool enabled,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (enabled) {
      await _supabase.rpc('get_or_create_course_conversation', params: {
        'p_course_id': courseId,
      });
      return;
    }

    await _supabase
        .from('conversations')
        .delete()
        .eq('course_id', courseId)
        .eq('type', 'multi');
  }

  bool _isMissingRpcFunction(Object error, String functionName) {
    if (error is! PostgrestException) return false;
    if (error.code != 'PGRST202') return false;
    return error.message.contains(functionName);
  }
}
