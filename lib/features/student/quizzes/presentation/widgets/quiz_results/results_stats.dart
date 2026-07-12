import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';

/// Results Stats - Shows total points and time spent
class ResultsStats extends StatelessWidget {
  final int score;
  final int totalPoints;
  final String timeSpent;
  final bool isDark;

  const ResultsStats({
    super.key,
    required this.score,
    required this.totalPoints,
    required this.timeSpent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Total Points
          Expanded(
            child: Column(
              children: [
                Text(
                  LocaleKeys.quiz_total_points.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$score/$totalPoints',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 50,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Time Spent
          Expanded(
            child: Column(
              children: [
                Text(
                  LocaleKeys.quiz_time_spent.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  timeSpent.isNotEmpty ? timeSpent : '--',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
