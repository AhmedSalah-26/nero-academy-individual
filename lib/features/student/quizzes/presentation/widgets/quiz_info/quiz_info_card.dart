import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_entity.dart';

/// Quiz Info Card - Displays quiz title and description
class QuizInfoCard extends StatelessWidget {
  final QuizEntity quiz;
  final String locale;
  final bool isDark;

  const QuizInfoCard({
    super.key,
    required this.quiz,
    required this.locale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : AppColors.borderLight,
          width: isDark ? 1.2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            quiz.getTitle(locale),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          // Description
          if (quiz.getDescription(locale) != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              quiz.getDescription(locale)!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
