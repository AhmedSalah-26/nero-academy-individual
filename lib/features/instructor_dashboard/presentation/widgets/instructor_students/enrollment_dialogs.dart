import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/animations/widgets/feedback/animated_snackbar.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

/// Enrollment Dialogs - Add course, extend, reset, status, certificate, unenroll

void showAddCourseDialog({
  required BuildContext context,
  required bool isArabic,
  required List<AvailableCourseForEnrollment> availableCourses,
  required Future<void> Function(String courseId) onEnroll,
}) {
  if (availableCourses.isEmpty) {
    AnimatedSnackbar.showWarning(
      context: context,
      message: isArabic
          ? 'لا توجد كورسات متاحة للإضافة'
          : 'No courses available to add',
    );
    return;
  }
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (dialogContext) => ResponsiveDialog(
      title: Text(isArabic ? 'إضافة كورس' : 'Add Course'),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableCourses.length,
          itemBuilder: (_, index) {
            final course = availableCourses[index];
            return ListTile(
              leading: course.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        course.thumbnailUrl!,
                        width: 40,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 30,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.play_circle_outline,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.play_circle_outline,
                          size: 16, color: AppColors.primary),
                    ),
              title: Text(isArabic ? course.titleAr : course.titleEn),
              onTap: () {
                Navigator.pop(dialogContext);
                onEnroll(course.id);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'))
      ],
    ),
  );
}

void showExtendDialog({
  required BuildContext context,
  required bool isArabic,
  required String enrollmentId,
  required Future<bool> Function(String, int) onExtend,
}) {
  int selectedDays = 30;
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => ResponsiveDialog(
        title: Text(isArabic ? 'تمديد الوصول' : 'Extend Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isArabic ? 'اختر عدد الأيام:' : 'Select days:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [7, 14, 30, 60, 90]
                  .map((days) => ChoiceChip(
                        label: Text('$days'),
                        selected: selectedDays == days,
                        onSelected: (s) {
                          if (s) setState(() => selectedDays = days);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await onExtend(enrollmentId, selectedDays);
              if (context.mounted) {
                if (success) {
                  AnimatedSnackbar.showSuccess(
                    context: context,
                    message: isArabic ? 'تم التمديد' : 'Extended',
                  );
                } else {
                  AnimatedSnackbar.showError(
                    context: context,
                    message: isArabic ? 'فشل' : 'Failed',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isArabic ? 'تمديد' : 'Extend'),
          ),
        ],
      ),
    ),
  );
}

void confirmResetProgress({
  required BuildContext context,
  required bool isArabic,
  required String enrollmentId,
  required Future<bool> Function(String) onReset,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => ResponsiveAlertDialog(
      title: isArabic ? 'إعادة تعيين التقدم' : 'Reset Progress',
      content: isArabic
          ? 'سيتم حذف جميع بيانات التقدم. متأكد؟'
          : 'All progress will be deleted. Are you sure?',
      confirmText: isArabic ? 'إعادة تعيين' : 'Reset',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmColor: AppColors.warning,
      onConfirm: () async {
        Navigator.pop(ctx);
        final success = await onReset(enrollmentId);
        if (context.mounted) {
          if (success) {
            AnimatedSnackbar.showSuccess(
              context: context,
              message: isArabic ? 'تم إعادة التعيين' : 'Reset done',
            );
          } else {
            AnimatedSnackbar.showError(
              context: context,
              message: isArabic ? 'فشل' : 'Failed',
            );
          }
        }
      },
    ),
  );
}

void showStatusDialog({
  required BuildContext context,
  required bool isArabic,
  required String enrollmentId,
  required String currentStatus,
  required Future<bool> Function(String, String) onUpdateStatus,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => ResponsiveDialog(
      title: Text(isArabic ? 'تغيير الحالة' : 'Change Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['active', 'completed', 'expired', 'pending'].map((status) {
          final labels = {
            'active': isArabic ? 'نشط' : 'Active',
            'completed': isArabic ? 'مكتمل' : 'Completed',
            'expired': isArabic ? 'منتهي' : 'Expired',
            'pending': isArabic ? 'معلق' : 'Pending'
          };
          return ListTile(
            leading: Icon(
                currentStatus == status
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentStatus == status ? AppColors.primary : null),
            title: Text(labels[status]!),
            onTap: currentStatus == status
                ? null
                : () async {
                    Navigator.pop(ctx);
                    final success = await onUpdateStatus(enrollmentId, status);
                    if (context.mounted) {
                      if (success) {
                        AnimatedSnackbar.showSuccess(
                          context: context,
                          message: isArabic ? 'تم التحديث' : 'Updated',
                        );
                      } else {
                        AnimatedSnackbar.showError(
                          context: context,
                          message: isArabic ? 'فشل' : 'Failed',
                        );
                      }
                    }
                  },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'))
      ],
    ),
  );
}

void confirmMarkAsCompleted({
  required BuildContext context,
  required bool isArabic,
  required String enrollmentId,
  required Future<bool> Function(String) onMarkCompleted,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => ResponsiveAlertDialog(
      title: isArabic ? 'تحديد كمكتمل' : 'Mark as Completed',
      content: isArabic
          ? 'سيتم تحديث الحالة إلى مكتمل. متأكد؟'
          : 'Status will be set to completed. Sure?',
      confirmText: isArabic ? 'تأكيد' : 'Confirm',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmColor: AppColors.success,
      onConfirm: () async {
        Navigator.pop(ctx);
        final success = await onMarkCompleted(enrollmentId);
        if (context.mounted) {
          if (success) {
            AnimatedSnackbar.showSuccess(
              context: context,
              message: isArabic ? 'تم التحديث' : 'Marked as completed',
            );
          } else {
            AnimatedSnackbar.showError(
              context: context,
              message: isArabic ? 'فشل' : 'Failed',
            );
          }
        }
      },
    ),
  );
}

void confirmUnenroll({
  required BuildContext context,
  required bool isArabic,
  required String enrollmentId,
  required Future<bool> Function(String) onUnenroll,
  required VoidCallback onSuccess,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => ResponsiveAlertDialog(
      title: isArabic ? 'إزالة التسجيل' : 'Remove Enrollment',
      content: isArabic
          ? 'سيتم حذف جميع البيانات. متأكد؟'
          : 'All data will be deleted. Sure?',
      confirmText: isArabic ? 'إزالة' : 'Remove',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        Navigator.pop(ctx);
        final success = await onUnenroll(enrollmentId);
        if (success) onSuccess();
        if (context.mounted) {
          if (success) {
            AnimatedSnackbar.showSuccess(
              context: context,
              message: isArabic ? 'تم الإزالة' : 'Removed',
            );
          } else {
            AnimatedSnackbar.showError(
              context: context,
              message: isArabic ? 'فشل' : 'Failed',
            );
          }
        }
      },
    ),
  );
}
