import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';

/// Question Navigation - Previous, Next, Submit buttons
class QuestionNavigation extends StatelessWidget {
  final bool isFirstQuestion;
  final bool isLastQuestion;
  final bool isSubmitting;
  final bool isDark;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const QuestionNavigation({
    super.key,
    required this.isFirstQuestion,
    required this.isLastQuestion,
    required this.isSubmitting,
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Button
          if (!isFirstQuestion)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: Text(LocaleKeys.quiz_previous.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (!isFirstQuestion) const SizedBox(width: AppSpacing.md),

          // Next/Submit Button
          Expanded(
            flex: isFirstQuestion ? 1 : 1,
            child: isLastQuestion
                ? ElevatedButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            LocaleKeys.quiz_submit.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )
                : ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          LocaleKeys.quiz_next.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
