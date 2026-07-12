// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/animations/widgets/feedback/animated_snackbar.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_students/enrollment_card_widgets.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_students/enrollment_dialogs.dart';

/// Student Enrollments Screen - Full page for managing student enrollments
class StudentEnrollmentsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final List<StudentEnrollmentDetail> enrollments;
  final Future<bool> Function(String enrollmentId, int days) onExtendAccess;
  final Future<bool> Function(String enrollmentId) onResetProgress;
  final Future<bool> Function(String enrollmentId, String status)
      onUpdateStatus;
  final Future<bool> Function(String enrollmentId) onUnenroll;
  final Future<bool> Function(String courseId) onEnrollInCourse;
  final List<AvailableCourseForEnrollment> availableCourses;
  final Future<List<StudentEnrollmentDetail>> Function() onRefreshEnrollments;
  final Future<List<AvailableCourseForEnrollment>> Function()
      onRefreshAvailableCourses;

  const StudentEnrollmentsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.enrollments,
    required this.onExtendAccess,
    required this.onResetProgress,
    required this.onUpdateStatus,
    required this.onUnenroll,
    required this.onEnrollInCourse,
    required this.availableCourses,
    required this.onRefreshEnrollments,
    required this.onRefreshAvailableCourses,
  });

  @override
  State<StudentEnrollmentsScreen> createState() =>
      _StudentEnrollmentsScreenState();
}

class _StudentEnrollmentsScreenState extends State<StudentEnrollmentsScreen> {
  late List<StudentEnrollmentDetail> _enrollments;
  late List<AvailableCourseForEnrollment> _availableCourses;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _enrollments = List.from(widget.enrollments);
    _availableCourses = List.from(widget.availableCourses);
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.onRefreshEnrollments(),
        widget.onRefreshAvailableCourses(),
      ]);
      if (mounted) {
        setState(() {
          _enrollments = results[0] as List<StudentEnrollmentDetail>;
          _availableCourses = results[1] as List<AvailableCourseForEnrollment>;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'تسجيلات الطالب' : 'Student Enrollments'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: isArabic ? 'تحديث' : 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Student Header
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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    widget.studentName.isNotEmpty
                        ? widget.studentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_enrollments.length} ${isArabic ? 'كورس' : 'courses'}',
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
                if (_availableCourses.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showAddCourseDialog(context, isArabic),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isArabic ? 'إضافة كورس' : 'Add Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Enrollments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _enrollments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isArabic
                                  ? 'لا توجد تسجيلات'
                                  : 'No enrollments found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_availableCourses.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showAddCourseDialog(context, isArabic),
                                icon: const Icon(Icons.add),
                                label: Text(
                                    isArabic ? 'إضافة كورس' : 'Add Course'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _enrollments.length,
                        itemBuilder: (context, index) {
                          final enrollment = _enrollments[index];
                          return EnrollmentCard(
                            enrollment: enrollment,
                            isDark: isDark,
                            isArabic: isArabic,
                            dateFormat: dateFormat,
                            onExtend: () =>
                                _handleExtend(context, enrollment, isArabic),
                            onReset: () =>
                                _handleReset(context, enrollment, isArabic),
                            onStatus: () =>
                                _handleStatus(context, enrollment, isArabic),
                            onUnenroll: () =>
                                _handleUnenroll(context, enrollment, isArabic),
                            onRefresh: _refreshData, // Add refresh callback
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context, bool isArabic) {
    showAddCourseDialog(
      context: context,
      isArabic: isArabic,
      availableCourses: _availableCourses,
      onEnroll: (courseId) async {
        final success = await widget.onEnrollInCourse(courseId);
        if (success && mounted) {
          AnimatedSnackbar.showSuccess(
            context: context,
            message: isArabic ? 'تم التسجيل بنجاح' : 'Enrolled successfully',
          );
          await _refreshData();
        }
      },
    );
  }

  void _handleExtend(
      BuildContext context, StudentEnrollmentDetail enrollment, bool isArabic) {
    showExtendDialog(
      context: context,
      isArabic: isArabic,
      enrollmentId: enrollment.enrollmentId,
      onExtend: (enrollmentId, days) async {
        final success = await widget.onExtendAccess(enrollmentId, days);
        if (success && mounted) {
          AnimatedSnackbar.showSuccess(
            context: context,
            message: isArabic ? 'تم تمديد الوصول' : 'Access extended',
          );
          await _refreshData();
        }
        return success;
      },
    );
  }

  void _handleReset(
      BuildContext context, StudentEnrollmentDetail enrollment, bool isArabic) {
    confirmResetProgress(
      context: context,
      isArabic: isArabic,
      enrollmentId: enrollment.enrollmentId,
      onReset: (enrollmentId) async {
        final success = await widget.onResetProgress(enrollmentId);
        if (success && mounted) {
          AnimatedSnackbar.showSuccess(
            context: context,
            message: isArabic ? 'تم إعادة تعيين التقدم' : 'Progress reset',
          );
          await _refreshData();
        }
        return success;
      },
    );
  }

  void _handleStatus(
      BuildContext context, StudentEnrollmentDetail enrollment, bool isArabic) {
    showStatusDialog(
      context: context,
      isArabic: isArabic,
      enrollmentId: enrollment.enrollmentId,
      currentStatus: enrollment.status,
      onUpdateStatus: (enrollmentId, status) async {
        final success = await widget.onUpdateStatus(enrollmentId, status);
        if (success && mounted) {
          AnimatedSnackbar.showSuccess(
            context: context,
            message: isArabic ? 'تم تحديث الحالة' : 'Status updated',
          );
          await _refreshData();
        }
        return success;
      },
    );
  }

  void _handleUnenroll(
      BuildContext context, StudentEnrollmentDetail enrollment, bool isArabic) {
    confirmUnenroll(
      context: context,
      isArabic: isArabic,
      enrollmentId: enrollment.enrollmentId,
      onUnenroll: (enrollmentId) async {
        final success = await widget.onUnenroll(enrollmentId);
        if (success && mounted) {
          AnimatedSnackbar.showSuccess(
            context: context,
            message: isArabic ? 'تم إلغاء التسجيل' : 'Unenrolled successfully',
          );
          await _refreshData();
        }
        return success;
      },
      onSuccess: () {
        if (mounted) {
          _refreshData();
        }
      },
    );
  }
}
