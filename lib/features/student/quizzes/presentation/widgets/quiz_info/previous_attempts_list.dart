import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';

/// Previous Attempts List - Shows history of quiz attempts
class PreviousAttemptsList extends StatelessWidget {
  final List<QuizAttemptEntity> attempts;
  final int passingScore;
  final bool isDark;
  final void Function(QuizAttemptEntity attempt)? onAttemptTap;

  const PreviousAttemptsList({
    super.key,
    required this.attempts,
    required this.passingScore,
    required this.isDark,
    this.onAttemptTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.quiz_history.tr(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...attempts.asMap().entries.map((entry) {
          final index = entry.key;
          final attempt = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < attempts.length - 1 ? AppSpacing.md : 0,
            ),
            child: _buildAttemptItem(context, attempt, index + 1),
          );
        }),
      ],
    );
  }

  Widget _buildAttemptItem(
    BuildContext context,
    QuizAttemptEntity attempt,
    int attemptNumber,
  ) {
    final theme = Theme.of(context);
    final isPassed = attempt.passed;
    final statusColor = isPassed ? AppColors.success : AppColors.error;

    return InkWell(
      onTap: attempt.isCompleted ? () => onAttemptTap?.call(attempt) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Row(
          children: [
            // Attempt Number Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.3 : 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$attemptNumber',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Attempt Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${attempt.formattedPercentage} - ${isPassed ? LocaleKeys.quiz_passed.tr() : LocaleKeys.quiz_failed.tr()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (attempt.completedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(attempt.completedAt!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: statusColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
