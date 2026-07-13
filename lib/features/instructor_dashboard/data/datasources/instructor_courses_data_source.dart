import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_models.dart';

/// Instructor Courses Data Source - Course management
class InstructorCoursesDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorCoursesDS';

  InstructorCoursesDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<String?> _resolveTeacherId() async {
    final teacher = await _client
        .from('teachers')
        .select('id')
        .eq('profile_id', _userId)
        .maybeSingle();
    return teacher?['id'] as String?;
  }

  /// Get my courses
  Future<List<InstructorCourseModel>> getMyCourses({
    InstructorCourseStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getMyCourses: status=$status, page=$page');
    try {
      final teacherId = await _resolveTeacherId();
      if (teacherId == null) return const [];

      var query = _client.from('courses').select('''
        id, title_ar, title_en, thumbnail_url, price, discount_price,
        is_published, is_suspended, suspension_reason, created_at, published_at,
        rating, rating_count, enrolled_count,
        lesson_count, section_count, total_revenue
      ''').eq('teacher_id', teacherId);

      if (status != null && status != InstructorCourseStatus.all) {
        switch (status) {
          case InstructorCourseStatus.published:
            query = query.eq('is_published', true).eq('is_suspended', false);
            break;
          case InstructorCourseStatus.draft:
            query = query.eq('is_published', false);
            break;
          case InstructorCourseStatus.suspended:
            query = query.eq('is_suspended', true);
            break;
          default:
            break;
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getMyCourses: ${(response as List).length} courses');
      return response.map((e) => InstructorCourseModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getMyCourses error', e, s);
      rethrow;
    }
  }

  /// Publish course
  Future<bool> publishCourse(String courseId) async {
    AppLogger.d('[$_tag] publishCourse: $courseId');
    try {
      final teacherId = await _resolveTeacherId();
      if (teacherId == null) return false;
      await _client
          .from('courses')
          .update({
            'is_published': true,
            'published_at': DateTime.now().toIso8601String(),
            'teacher_id': teacherId,
          })
          .eq('id', courseId)
          .eq('teacher_id', teacherId);
      AppLogger.success('[$_tag] publishCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] publishCourse error', e, s);
      rethrow;
    }
  }

  /// Unpublish course
  Future<bool> unpublishCourse(String courseId) async {
    AppLogger.d('[$_tag] unpublishCourse: $courseId');
    try {
      final teacherId = await _resolveTeacherId();
      if (teacherId == null) return false;
      await _client
          .from('courses')
          .update({'is_published': false})
          .eq('id', courseId)
          .eq('teacher_id', teacherId);
      AppLogger.success('[$_tag] unpublishCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unpublishCourse error', e, s);
      rethrow;
    }
  }

  /// Delete course (only if not published or has no enrollments)
  Future<bool> deleteCourse(String courseId) async {
    AppLogger.d('[$_tag] deleteCourse: $courseId');
    try {
      final teacherId = await _resolveTeacherId();
      if (teacherId == null) return false;
      await _client
          .from('courses')
          .delete()
          .eq('id', courseId)
          .eq('teacher_id', teacherId);
      AppLogger.success('[$_tag] deleteCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteCourse error', e, s);
      rethrow;
    }
  }
}
