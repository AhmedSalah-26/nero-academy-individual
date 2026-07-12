import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';
import 'availability_schedule_card.dart';
import 'course_summary_card.dart';
import 'publish_checklist_card.dart';

/// Settings Step – review, availability scheduling, and publish/draft actions.
class SettingsStep extends StatelessWidget {
  const SettingsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<CourseEditorCubit>();

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'إعدادات الكورس' : 'Course Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'راجع إعدادات الكورس قبل النشر'
                    : 'Review your course settings before publishing',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 32),
              PublishChecklistCard(
                state: state,
                isArabic: isArabic,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              CourseSummaryCard(
                state: state,
                isArabic: isArabic,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              AvailabilityScheduleCard(
                state: state,
                cubit: cubit,
                isArabic: isArabic,
                isDark: isDark,
              ),
              const SizedBox(height: 32),
              if (!state.isEditing)
                _buildActionButtons(context, cubit, state, isArabic),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    CourseEditorCubit cubit,
    CourseEditorState state,
    bool isArabic,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: () => cubit.setStep(3),
          icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
          label: Text(isArabic ? 'السابق' : 'Previous'),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: () async {
                AppLogger.i('📝 [SettingsStep] Save Draft pressed');
                final success = await cubit.saveDraft();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? (isArabic ? 'تم حفظ المسودة' : 'Draft saved')
                          : (isArabic ? 'فشل في الحفظ' : 'Failed to save')),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: Text(isArabic ? 'حفظ كمسودة' : 'Save as Draft'),
            ),
            ElevatedButton.icon(
              onPressed: () => _handlePublish(context, cubit, state, isArabic),
              icon: const Icon(Icons.publish),
              label: Text('course_editor.publish_course'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handlePublish(
    BuildContext context,
    CourseEditorCubit cubit,
    CourseEditorState state,
    bool isArabic,
  ) async {
    final missingItems = state.publishValidationMessages(isArabic: isArabic);
    if (missingItems.isNotEmpty) {
      await showDialog<void>(
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
                        const Icon(Icons.error_outline,
                            size: 18, color: AppColors.warning),
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
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('course_editor.publish_confirm_title'.tr()),
        content: Text('course_editor.publish_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text('course_editor.publish_course'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await cubit.publishCourse();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'course_editor.publish_success'.tr()
            : 'course_editor.publish_failed'.tr()),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
