import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/my_learning/presentation/cubit/my_learning_state.dart';

/// Filter Tabs Widget for My Learning Screen
class FilterTabs extends StatelessWidget {
  final MyLearningFilter currentFilter;
  final int inProgressCount;
  final int completedCount;
  final ValueChanged<MyLearningFilter> onFilterChanged;

  const FilterTabs({
    super.key,
    required this.currentFilter,
    required this.inProgressCount,
    required this.completedCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'my_learning.in_progress'.tr(),
            count: inProgressCount,
            isSelected: currentFilter == MyLearningFilter.inProgress,
            onTap: () => _onTap(MyLearningFilter.inProgress),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'my_learning.completed'.tr(),
            count: completedCount,
            isSelected: currentFilter == MyLearningFilter.completed,
            onTap: () => _onTap(MyLearningFilter.completed),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'my_learning.all'.tr(),
            isSelected: currentFilter == MyLearningFilter.all,
            onTap: () => _onTap(MyLearningFilter.all),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  void _onTap(MyLearningFilter filter) {
    HapticFeedback.lightImpact();
    onFilterChanged(filter);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.grey700 : AppColors.grey200,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.white
                    : (isDark ? AppColors.grey300 : AppColors.grey600),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
