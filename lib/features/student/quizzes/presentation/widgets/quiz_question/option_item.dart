import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';

/// Option Item - Single option for a question
class OptionItem extends StatelessWidget {
  final QuizOptionEntity option;
  final bool isSelected;
  final bool isMultiple;
  final String locale;
  final bool isDark;
  final VoidCallback onTap;

  const OptionItem({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isMultiple,
    required this.locale,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.15 : 0.05)
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Radio/Checkbox indicator
            _buildIndicator(context),
            const SizedBox(width: AppSpacing.md),

            // Option Text
            Expanded(
              child: Text(
                option.getText(locale),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? primary
                      : (isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight),
                ),
              ),
            ),

            // Check icon when selected
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (isMultiple) {
      // Checkbox style
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? AppColors.grey600 : AppColors.grey300),
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                size: 16,
                color: AppColors.white,
              )
            : null,
      );
    } else {
      // Radio style
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? AppColors.grey600 : AppColors.grey300),
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                  ),
                ),
              )
            : null,
      );
    }
  }
}
