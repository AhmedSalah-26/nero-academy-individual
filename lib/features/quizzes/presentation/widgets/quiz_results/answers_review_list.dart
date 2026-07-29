import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/arabic_utils.dart';
import '../../../domain/entities/quiz_question_entity.dart';
import '../../../domain/entities/quiz_attempt_entity.dart';

/// Answers Review List - Shows all questions with correct/incorrect status
class AnswersReviewList extends StatelessWidget {
  final List<QuizQuestionEntity> questions;
  final Map<String, QuizAnswerEntity> answers;
  final String locale;
  final bool isDark;

  const AnswersReviewList({
    super.key,
    required this.questions,
    required this.answers,
    required this.locale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        final answer = answers[question.id];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < questions.length - 1 ? AppSpacing.md : 0,
          ),
          child: _AnswerReviewCard(
            question: question,
            answer: answer,
            questionNumber: index + 1,
            locale: locale,
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }
}

class _AnswerReviewCard extends StatelessWidget {
  final QuizQuestionEntity question;
  final QuizAnswerEntity? answer;
  final int questionNumber;
  final String locale;
  final bool isDark;

  const _AnswerReviewCard({
    required this.question,
    required this.answer,
    required this.questionNumber,
    required this.locale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = _checkIsCorrect();
    final statusColor = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          // Subtle glow effect
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Question number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$questionNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Status text
                Expanded(
                  child: Text(
                    isCorrect
                        ? (locale == 'ar' ? 'إجابة صحيحة' : 'Correct')
                        : (locale == 'ar' ? 'إجابة خاطئة' : 'Incorrect'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Points badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${answer?.pointsEarned ?? 0}/${question.points}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Question content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                if (question.getQuestion(locale).isNotEmpty)
                  Directionality(
                    textDirection:
                        ArabicUtils.containsArabic(question.getQuestion(locale))
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        question.getQuestion(locale),
                        textAlign: TextAlign.start,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                // Question image
                if (question.imageUrl != null &&
                    question.imageUrl!.isNotEmpty) ...[
                  if (question.getQuestion(locale).isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      question.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 32, color: Colors.grey),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // Your answer
                _buildAnswerRow(
                  context,
                  label: locale == 'ar' ? 'إجابتك' : 'Your answer',
                  value: _getUserAnswerText(),
                  color: isCorrect ? AppColors.success : AppColors.error,
                  icon: isCorrect ? Icons.check_circle : Icons.cancel,
                ),
                // Correct answer (if wrong)
                if (!isCorrect) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildAnswerRow(
                    context,
                    label:
                        locale == 'ar' ? 'الإجابة الصحيحة' : 'Correct answer',
                    value: _getCorrectAnswerText(),
                    color: AppColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                ],
                // Explanation (if available and wrong)
                if (!isCorrect && question.getExplanation(locale) != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            question.getExplanation(locale)!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        Expanded(
          child: Directionality(
            textDirection: ArabicUtils.containsArabic(value)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _checkIsCorrect() {
    if (answer == null) return false;
    // Use pointsEarned as primary indicator (more reliable)
    // If pointsEarned > 0, the answer is correct
    if (answer!.pointsEarned > 0) return true;
    // Fallback to isCorrect flag
    if (answer!.isCorrect) return true;
    // Final fallback: compare selected options with correct options
    if (answer!.selectedOptionIds.isEmpty) return false;
    final correctOptionIds = question.correctOptions.map((o) => o.id).toSet();
    final selectedIds = answer!.selectedOptionIds.toSet();
    return correctOptionIds.length == selectedIds.length &&
        correctOptionIds.containsAll(selectedIds);
  }

  String _getCorrectAnswerText() {
    final correctOptions = question.correctOptions;
    if (correctOptions.isEmpty) return '-';
    return correctOptions.map((o) => o.getText(locale)).join(', ');
  }

  String _getUserAnswerText() {
    if (answer == null || answer!.selectedOptionIds.isEmpty) {
      return locale == 'ar' ? 'لم تجب' : 'Not answered';
    }

    final selectedTexts = answer!.selectedOptionIds.map((id) {
      final option = question.options.where((o) => o.id == id).firstOrNull;
      return option?.getText(locale) ?? '';
    }).where((t) => t.isNotEmpty);

    return selectedTexts.isEmpty ? '-' : selectedTexts.join(', ');
  }
}
