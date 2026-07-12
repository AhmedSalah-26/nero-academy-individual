import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';

/// Question Header - Shows progress and question number
class QuestionHeader extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final double progress;
  final bool isDark;

  const QuestionHeader({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          // Question Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${LocaleKeys.quiz_question.tr()} ${currentIndex + 1} ${LocaleKeys.quiz_of.tr()} $totalQuestions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.grey700 : AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
