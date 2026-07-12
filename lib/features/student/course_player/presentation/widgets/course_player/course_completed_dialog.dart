import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/animations/widgets/feedback/completion_animation.dart';

/// Course Completed Dialog Widget
class CourseCompletedDialog extends StatelessWidget {
  final bool isDark;
  final String? courseId;
  final String? courseTitle;

  const CourseCompletedDialog({
    super.key,
    required this.isDark,
    this.courseId,
    this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use CompletionAnimation instead of static icon
          const CompletionAnimation(
            type: CompletionType.trophy,
            size: 100,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            'course_player.course_completed_title'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'course_player.course_completed_message'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Certificate info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'course_player.certificate_earned'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // Go back to My Learning
          },
          child: Text(
            'course_player.back_to_learning'.tr(),
            style: TextStyle(
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            context.pushNamed('certificates');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('course_player.view_certificate'.tr()),
        ),
      ],
    );
  }
}

/// Show course completed dialog
void showCourseCompletedDialog(
  BuildContext context, {
  String? courseId,
  String? courseTitle,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => CourseCompletedDialog(
      isDark: isDark,
      courseId: courseId,
      courseTitle: courseTitle,
    ),
  );
}
