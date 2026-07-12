import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Filter Chip Widget - Horizontal scrollable filter chips
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDropdown;
  final VoidCallback onTap;
  final IconData? icon;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.hasDropdown = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white
                        : AppColors.grey700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.grey500,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Filter Chips Row - Horizontal scrollable row of filter chips
class FilterChipsRow extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final VoidCallback onPriceTap;
  final VoidCallback onRatingTap;
  final VoidCallback onDurationTap;

  const FilterChipsRow({
    super.key,
    required this.activeFilterCount,
    required this.onFilterTap,
    required this.onSortTap,
    required this.onPriceTap,
    required this.onRatingTap,
    required this.onDurationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Main Filter Button
            FilterChipWidget(
              label: activeFilterCount > 0
                  ? '${'search.filter'.tr()} ($activeFilterCount)'
                  : 'search.filter'.tr(),
              isSelected: activeFilterCount > 0,
              icon: Icons.filter_list_rounded,
              onTap: onFilterTap,
            ),

            // Divider
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDark ? AppColors.grey700 : AppColors.grey200,
            ),

            // Sort
            FilterChipWidget(
              label: 'search.sort_by'.tr(),
              hasDropdown: true,
              onTap: onSortTap,
            ),
            const SizedBox(width: 8),

            // Price
            FilterChipWidget(
              label: 'search.price_range'.tr(),
              hasDropdown: true,
              onTap: onPriceTap,
            ),
            const SizedBox(width: 8),

            // Rating
            FilterChipWidget(
              label: 'search.min_rating'.tr(),
              hasDropdown: true,
              onTap: onRatingTap,
            ),
            const SizedBox(width: 8),

            // Duration
            FilterChipWidget(
              label: 'search.duration'.tr(),
              hasDropdown: true,
              onTap: onDurationTap,
            ),
          ],
        ),
      ),
    );
  }
}
