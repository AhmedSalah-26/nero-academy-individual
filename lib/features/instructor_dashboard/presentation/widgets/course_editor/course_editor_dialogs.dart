// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/responsive_dialog.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Saves the current course as a draft, showing a loading dialog while doing so.
Future<void> showSaveDraftDialog(
  BuildContext context,
) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    barrierDismissible: false,
    builder: (ctx) => ResponsiveDialog(
      maxWidth: 300,
      content: Row(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(width: 20),
          Expanded(child: Text(isArabic ? 'جاري الحفظ...' : 'Saving...')),
        ],
      ),
    ),
  );

  final success = await context.read<CourseEditorCubit>().saveDraft();

  if (context.mounted) {
    Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (isArabic ? 'تم حفظ المسودة' : 'Draft saved')
            : (isArabic ? 'فشل في الحفظ' : 'Failed to save')),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}

/// Validates, confirms, then publishes the course – showing appropriate
/// loading / success / error dialogs throughout.
Future<void> showPublishDialog(
  BuildContext context,
) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final missingItems = context
      .read<CourseEditorCubit>()
      .state
      .publishValidationMessages(isArabic: isArabic);

  if (missingItems.isNotEmpty) {
    await showPublishValidationDialog(context, missingItems);
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => ResponsiveAlertDialog(
      title: 'course_editor.publish_confirm_title'.tr(),
      content: 'course_editor.publish_confirm_message'.tr(),
      confirmText: 'course_editor.publish_course'.tr(),
      cancelText: 'common.cancel'.tr(),
      confirmColor: AppColors.success,
      onConfirm: () => Navigator.pop(ctx, true),
      onCancel: () => Navigator.pop(ctx, false),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // Show loading dialog
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    barrierDismissible: false,
    builder: (ctx) => ResponsiveDialog(
      maxWidth: 350,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'course_editor.publishing'.tr(),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'يرجى الانتظار' : 'Please wait',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  final success = await context.read<CourseEditorCubit>().publishCourse();

  if (!context.mounted) return;
  Navigator.pop(context); // Close loading dialog

  if (success) {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'course_editor.publish_success'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'course_editor.published_available'.tr(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('course_editor.publish_failed'.tr()),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Shows a dialog listing the checklist items still missing before publishing.
Future<void> showPublishValidationDialog(
  BuildContext context,
  List<String> missingItems,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('course_editor.publish_missing_title'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('course_editor.publish_missing_message'.tr()),
            const SizedBox(height: 12),
            ...missingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('common.ok'.tr()),
        ),
      ],
    ),
  );
}
