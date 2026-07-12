import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';

/// Submit Dialog - Confirmation before submitting quiz
class SubmitDialog extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;
  final VoidCallback onSubmit;

  const SubmitDialog({
    super.key,
    required this.answeredCount,
    required this.totalQuestions,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unansweredCount = totalQuestions - answeredCount;
    final hasUnanswered = unansweredCount > 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            hasUnanswered ? Icons.warning_amber_rounded : Icons.check_circle,
            color: hasUnanswered ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(LocaleKeys.quiz_submit_title.tr()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasUnanswered
                ? LocaleKeys.quiz_submit_warning.tr(
                    args: ['$unansweredCount'],
                  )
                : LocaleKeys.quiz_submit_confirm.tr(),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  context,
                  LocaleKeys.quiz_answered.tr(),
                  '$answeredCount',
                  AppColors.success,
                  isDark,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? AppColors.borderDark : AppColors.grey300,
                ),
                _buildStat(
                  context,
                  LocaleKeys.quiz_unanswered.tr(),
                  '$unansweredCount',
                  hasUnanswered ? AppColors.warning : AppColors.grey400,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.quiz_review.tr()),
        ),
        ElevatedButton(
          onPressed: onSubmit,
          child: Text(LocaleKeys.quiz_submit.tr()),
        ),
      ],
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
