import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_entity.dart';

/// Quiz Meta Grid - Shows time, questions, pass score, attempts
class QuizMetaGrid extends StatelessWidget {
  final QuizEntity quiz;
  final int remainingAttempts;
  final bool isDark;

  const QuizMetaGrid({
    super.key,
    required this.quiz,
    required this.remainingAttempts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.85,
      children: [
        _buildMetaItem(
          context,
          icon: Icons.timer_outlined,
          label: LocaleKeys.quiz_time_limit.tr(),
          value: quiz.hasTimeLimit
              ? '${quiz.timeLimit} ${LocaleKeys.quiz_minutes.tr()}'
              : LocaleKeys.quiz_no_limit.tr(),
          color: AppColors.info,
        ),
        _buildMetaItem(
          context,
          icon: Icons.help_outline_rounded,
          label: LocaleKeys.quiz_questions.tr(),
          value: '${quiz.totalQuestions} ${LocaleKeys.quiz_question.tr()}',
          color: Theme.of(context).colorScheme.primary,
        ),
        _buildMetaItem(
          context,
          icon: Icons.emoji_events_outlined,
          label: LocaleKeys.quiz_pass_score.tr(),
          value: '${quiz.passingScore}%',
          color: AppColors.success,
        ),
        _buildMetaItem(
          context,
          icon: Icons.replay_rounded,
          label: LocaleKeys.quiz_attempts.tr(),
          value: _getAttemptsText(),
          color: AppColors.warning,
        ),
      ],
    );
  }

  String _getAttemptsText() {
    if (!quiz.hasAttemptLimit) {
      return LocaleKeys.quiz_unlimited.tr();
    }
    if (remainingAttempts <= 0) {
      return LocaleKeys.quiz_no_attempts.tr();
    }
    return '$remainingAttempts ${LocaleKeys.quiz_remaining.tr()}';
  }

  Widget _buildMetaItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : color.withValues(alpha: 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
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
