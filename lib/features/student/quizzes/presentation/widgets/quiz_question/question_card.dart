import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';
import 'option_item.dart';

/// Question Card - Displays question and options
class QuestionCard extends StatelessWidget {
  final QuizQuestionEntity question;
  final List<String> selectedOptions;
  final String locale;
  final bool isDark;
  final Function(String) onOptionSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedOptions,
    required this.locale,
    required this.isDark,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionText = question.getQuestion(locale);
    final hasImage = question.imageUrl != null && question.imageUrl!.isNotEmpty;
    final hasText = questionText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Meta (Points & Type)
        Row(
          children: [
            _buildBadge(
              context,
              '${question.points} ${question.points > 1 ? 'نقاط' : 'نقطة'}',
              AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildBadge(
              context,
              question.questionType.displayNameAr,
              isDark ? AppColors.grey600 : AppColors.grey400,
              isOutlined: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Question Image (if exists)
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              question.imageUrl!,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Question Text (if exists)
        if (hasText) ...[
          Text(
            questionText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ] else if (hasImage) ...[
          // Add some spacing if only image
          const SizedBox(height: AppSpacing.md),
        ],

        // Options
        ...question.options.map((option) {
          final isSelected = selectedOptions.contains(option.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: OptionItem(
              option: option,
              isSelected: isSelected,
              isMultiple: question.questionType == QuestionType.multiple,
              locale: locale,
              isDark: isDark,
              onTap: () => onOptionSelected(option.id),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String text,
    Color color, {
    bool isOutlined = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            isOutlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isOutlined
              ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
              : color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
