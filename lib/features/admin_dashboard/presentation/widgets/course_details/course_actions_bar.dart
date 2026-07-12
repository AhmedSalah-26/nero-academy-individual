import 'package:flutter/material.dart';

import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_course_model.dart';

class CourseActionsBar extends StatelessWidget {
  final AdminCourseModel course;
  final bool isDark;
  final bool isArabic;
  final VoidCallback? onPublish;
  final VoidCallback? onUnpublish;
  final VoidCallback? onFeature;
  final VoidCallback? onUnfeature;
  final Function(String)? onSuspend;
  final VoidCallback? onUnsuspend;
  final VoidCallback? onDelete;
  final VoidCallback? onViewEnrollments;

  const CourseActionsBar({
    super.key,
    required this.course,
    required this.isDark,
    required this.isArabic,
    this.onPublish,
    this.onUnpublish,
    this.onFeature,
    this.onUnfeature,
    this.onSuspend,
    this.onUnsuspend,
    this.onDelete,
    this.onViewEnrollments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            // View Enrollments
            _buildActionButton(
              icon: Icons.people_rounded,
              label: isArabic ? 'المسجلين' : 'Enrollments',
              color: AppColors.info,
              onPressed: () {
                onViewEnrollments?.call();
              },
            ),
            // Publish/Unpublish
            if (!course.isSuspended)
              course.isPublished
                  ? _buildActionButton(
                      icon: Icons.unpublished_rounded,
                      label: isArabic ? 'إلغاء النشر' : 'Unpublish',
                      color: AppColors.warning,
                      onPressed: () {
                        onUnpublish?.call();
                      },
                    )
                  : _buildActionButton(
                      icon: Icons.publish_rounded,
                      label: isArabic ? 'نشر' : 'Publish',
                      color: AppColors.success,
                      onPressed: () {
                        onPublish?.call();
                      },
                    ),
            // Feature/Unfeature
            course.isFeatured
                ? _buildActionButton(
                    icon: Icons.star_outline_rounded,
                    label: isArabic ? 'إلغاء التمييز' : 'Unfeature',
                    color: const Color(0xFF9E9E9E),
                    onPressed: () {
                      onUnfeature?.call();
                    },
                  )
                : _buildActionButton(
                    icon: Icons.star_rounded,
                    label: isArabic ? 'تمييز' : 'Feature',
                    color: const Color(0xFFFFB300),
                    onPressed: () {
                      onFeature?.call();
                    },
                  ),
            // Suspend/Unsuspend
            course.isSuspended
                ? _buildActionButton(
                    icon: Icons.play_circle_rounded,
                    label: isArabic ? 'إلغاء الإيقاف' : 'Unsuspend',
                    color: AppColors.success,
                    onPressed: () {
                      onUnsuspend?.call();
                    },
                  )
                : _buildActionButton(
                    icon: Icons.pause_circle_rounded,
                    label: isArabic ? 'إيقاف' : 'Suspend',
                    color: const Color(0xFFFF9800),
                    onPressed: () {
                      _showSuspendDialog(context, course.id, isArabic);
                    },
                  ),
            // Delete
            _buildActionButton(
              icon: Icons.delete_rounded,
              label: isArabic ? 'حذف' : 'Delete',
              color: AppColors.error,
              onPressed: () {
                _showDeleteConfirmation(context, isArabic);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuspendDialog(
      BuildContext context, String courseId, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardInputDialog(
        title: isArabic ? 'إيقاف الكورس' : 'Suspend Course',
        message: isArabic
            ? 'أدخل سبب إيقاف الكورس'
            : 'Enter the reason for suspending this course',
        hintText: isArabic ? 'سبب الإيقاف...' : 'Suspension reason...',
        confirmText: isArabic ? 'إيقاف' : 'Suspend',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        maxLines: 3,
      ),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty) {
        onSuspend?.call(reason);
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'حذف الكورس' : 'Delete Course'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف هذا الكورس؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete this course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
