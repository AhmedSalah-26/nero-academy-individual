import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_student_model.dart';
import 'package:lms_platform/core/routing/app_router.dart';

/// Instructor Course Enrollments Screen - Shows all students enrolled in a specific course
class InstructorCourseEnrollmentsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const InstructorCourseEnrollmentsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<InstructorCourseEnrollmentsScreen> createState() =>
      _InstructorCourseEnrollmentsScreenState();
}

class _InstructorCourseEnrollmentsScreenState
    extends State<InstructorCourseEnrollmentsScreen> {
  List<CourseEnrollmentItem> _enrollments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get enrollments from database with student profiles
      final response = await Supabase.instance.client
          .from('enrollments')
          .select('''
            id,
            user_id,
            enrolled_at,
            last_accessed_at,
            progress_percentage,
            profiles!enrollments_user_id_fkey!inner(
              id,
              name,
              email,
              avatar_url
            )
          ''')
          .eq('course_id', widget.courseId)
          .order('enrolled_at', ascending: false);

      final enrollments = <CourseEnrollmentItem>[];

      for (final item in response as List) {
        final profile = item['profiles'];

        enrollments.add(CourseEnrollmentItem(
          enrollmentId: item['id'] as String,
          studentId: item['user_id'] as String,
          studentName: profile['name'] as String? ?? 'Unknown',
          studentEmail: profile['email'] as String? ?? '',
          progressPercentage:
              (item['progress_percentage'] as num?)?.round() ?? 0,
          enrolledAt: DateTime.parse(item['enrolled_at'] as String),
          lastAccessedAt: item['last_accessed_at'] != null
              ? DateTime.parse(item['last_accessed_at'] as String)
              : null,
        ));
      }

      setState(() {
        _enrollments = enrollments;
        _isLoading = false;
      });
    } catch (e) {
      String message = e.toString();
      // Simplify error message for user
      if (e is PostgrestException) {
        message = 'Error Code: ${e.code}';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
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
          isArabic ? 'الطلاب المسجلين' : 'Enrolled Students',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        leading: const AppBackButton(fallbackLocation: '/instructor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEnrollments,
            tooltip: isArabic ? 'تحديث' : 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {
              // Preview course as student
              context.push('/course/${widget.courseId}');
            },
            tooltip: isArabic ? 'معاينة الكورس' : 'Preview Course',
          ),
        ],
      ),
      body: Column(
        children: [
          // Course Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.courseTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_enrollments.length} ${isArabic ? 'طالب' : 'students'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Enrollments List
          Expanded(
            child: _buildBody(isDark, isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, bool isArabic) {
    if (_isLoading) {
      return const AppLoadingState();
    }

    if (_errorMessage != null) {
      return ErrorState(
        type: ErrorType.server,
        display: ErrorStateDisplay.section,
        message: _errorMessage!,
        onRetry: _loadEnrollments,
      );
    }

    if (_enrollments.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: isArabic ? 'لا يوجد طلاب' : 'No Students',
        message: isArabic
            ? 'لم يسجل أي طالب في هذا الكورس بعد'
            : 'No students have enrolled in this course yet',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEnrollments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _enrollments.length,
        itemBuilder: (context, index) {
          final enrollment = _enrollments[index];
          return _buildEnrollmentCard(enrollment, isDark, isArabic);
        },
      ),
    );
  }

  Widget _buildEnrollmentCard(
    CourseEnrollmentItem enrollment,
    bool isDark,
    bool isArabic,
  ) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToStudentDetails(context, enrollment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  enrollment.studentName.isNotEmpty
                      ? enrollment.studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.studentName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isArabic ? 'التقدم:' : 'Progress:'} ${enrollment.progressPercentage}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isArabic ? 'تاريخ التسجيل:' : 'Enrolled:'} ${dateFormat.format(enrollment.enrolledAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToStudentDetails(
    BuildContext context,
    CourseEnrollmentItem enrollment,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fetch full student details
      final response =
          await Supabase.instance.client.from('profiles').select('''
            id,
            name,
            email,
            phone,
            avatar_url,
            role,
            interests,
            is_active,
            is_banned,
            banned_until,
            ban_reason,
            created_at,
            updated_at
          ''').eq('id', enrollment.studentId).single();

      // Get enrollment stats
      final enrollmentsResponse = await Supabase.instance.client
          .from('enrollments')
          .select('id, progress_percentage, enrolled_at, last_accessed_at')
          .eq('user_id', enrollment.studentId);

      final enrollments = enrollmentsResponse as List;
      final enrolledCount = enrollments.length;
      final completedCount = enrollments
          .where((e) => (e['progress_percentage'] ?? 0) >= 100)
          .length;
      final totalProgress = enrollments.isEmpty
          ? 0.0
          : enrollments
                  .map((e) =>
                      (e['progress_percentage'] as num?)?.toDouble() ?? 0)
                  .reduce((a, b) => a + b) /
              enrollments.length;

      final firstEnrolledAt = enrollments.isNotEmpty
          ? enrollments
              .map((e) => DateTime.parse(e['enrolled_at'] as String))
              .reduce((a, b) => a.isBefore(b) ? a : b)
          : null;

      final lastActivityAt = enrollments
          .where((e) => e['last_accessed_at'] != null)
          .map((e) => DateTime.parse(e['last_accessed_at'] as String))
          .fold<DateTime?>(null,
              (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev);

      // Create student model
      final student = InstructorStudentModel(
        id: response['id'] as String,
        name: response['name'] as String? ?? 'Unknown',
        email: response['email'] as String?,
        phone: response['phone'] as String?,
        avatarUrl: response['avatar_url'] as String?,
        role: response['role'] as String? ?? 'student',
        enrolledCoursesCount: enrolledCount,
        totalProgress: totalProgress,
        firstEnrolledAt: firstEnrolledAt,
        lastActivityAt: lastActivityAt,
        interests: (response['interests'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isActive: response['is_active'] as bool? ?? true,
        isBanned: response['is_banned'] as bool? ?? false,
        bannedUntil: response['banned_until'] != null
            ? DateTime.tryParse(response['banned_until'] as String)
            : null,
        banReason: response['ban_reason'] as String?,
        createdAt: response['created_at'] != null
            ? DateTime.tryParse(response['created_at'] as String)
            : null,
        updatedAt: response['updated_at'] != null
            ? DateTime.tryParse(response['updated_at'] as String)
            : null,
        completedCoursesCount: completedCount,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navigate to student details
      if (context.mounted) {
        AppRouter.goToStudentDetails(
          context,
          student: student,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'فشل تحميل بيانات الطالب'
                  : 'Failed to load student details',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Course Enrollment Item Model
class CourseEnrollmentItem {
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final int progressPercentage;
  final DateTime enrolledAt;
  final DateTime? lastAccessedAt;

  CourseEnrollmentItem({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.progressPercentage,
    required this.enrolledAt,
    this.lastAccessedAt,
  });
}
