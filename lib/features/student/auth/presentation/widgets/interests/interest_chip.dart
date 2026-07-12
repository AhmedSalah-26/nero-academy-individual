import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Interest Chip - Selectable interest pill
class InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const InterestChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.grey800.withValues(alpha: 0.5)
                  : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.grey700 : AppColors.grey200),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.white
                    : (isDark ? AppColors.grey300 : AppColors.grey700),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isSelected ? Icons.check : Icons.add,
              size: 18,
              color: isSelected
                  ? AppColors.white
                  : (isDark ? AppColors.grey500 : AppColors.grey400),
            ),
          ],
        ),
      ),
    );
  }
}
