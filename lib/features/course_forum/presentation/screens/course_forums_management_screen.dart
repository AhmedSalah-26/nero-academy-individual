import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/shared_widgets/loading_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/course_forums_management_models.dart';
import 'course_group_members_screen.dart';

class CourseForumsManagementScreen extends StatefulWidget {
  const CourseForumsManagementScreen({super.key});

  @override
  State<CourseForumsManagementScreen> createState() =>
      _CourseForumsManagementScreenState();
}

class _CourseForumsManagementScreenState
    extends State<CourseForumsManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;
  String? _busyCourseId;
  List<ManagedCourse> _courses = const [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .rpc('get_instructor_forum_courses', params: {'p_user_id': userId});

      final rows = (response as List)
          .map((row) => ManagedCourse.fromJson(row as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _courses = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleCourseGroup(ManagedCourse course, bool enabled) async {
    setState(() {
      _busyCourseId = course.id;
    });

    try {
      await _supabase.rpc('set_course_group_enabled', params: {
        'p_course_id': course.id,
        'p_enabled': enabled,
      });

      if (!mounted) return;
      setState(() {
        _courses = _courses
            .map((c) => c.id == course.id ? c.copyWith(hasGroup: enabled) : c)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyCourseId = null;
        });
      }
    }
  }

  Future<void> _openGroupMembers(ManagedCourse course) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseGroupMembersScreen(
          courseId: course.id,
          courseTitleAr: course.titleAr,
          courseTitleEn: course.titleEn,
        ),
      ),
    );
    await _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          isArabic ? 'إدارة منتديات الكورسات' : 'Course Forums Management',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: _buildBody(isDark, isArabic),
      ),
    );
  }

  Widget _buildBody(bool isDark, bool isArabic) {
    if (_isLoading) {
      return const AppLoadingState();
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _loadCourses,
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ),
        ],
      );
    }

    if (_courses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              isArabic ? 'لا توجد كورسات لإدارتها' : 'No courses to manage yet',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final course = _courses[index];
        final isBusy = _busyCourseId == course.id;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: ListTile(
            title: Text(
              course.displayTitle(isArabic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              course.hasGroup
                  ? (isArabic ? 'الجروب مفعل' : 'Group enabled')
                  : (isArabic ? 'الجروب غير مفعل' : 'Group disabled'),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBusy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (course.hasGroup)
                  IconButton(
                    tooltip: isArabic ? 'إدارة الجروب' : 'Manage group',
                    icon: const Icon(Icons.manage_accounts_outlined),
                    onPressed: isBusy ? null : () => _openGroupMembers(course),
                  ),
                Switch.adaptive(
                  value: course.hasGroup,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  onChanged: isBusy
                      ? null
                      : (value) => _toggleCourseGroup(course, value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
