import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_state.dart';

/// Wishlist Filter Tabs - Tab bar for filtering wishlist items
class WishlistFilterTabs extends StatelessWidget {
  final WishlistFilter currentFilter;
  final ValueChanged<WishlistFilter> onFilterChanged;
  final bool isDark;

  const WishlistFilterTabs({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = Theme.of(context).colorScheme.tertiary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: WishlistFilter.values.map((filter) {
            final isSelected = filter == currentFilter;
            return _FilterTab(
              label: _getFilterLabel(filter),
              isSelected: isSelected,
              onTap: () => onFilterChanged(filter),
              isDark: isDark,
              actionColor: actionColor,
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getFilterLabel(WishlistFilter filter) {
    switch (filter) {
      case WishlistFilter.all:
        return 'wishlist.filter_all'.tr();
      case WishlistFilter.priceDrops:
        return 'wishlist.filter_price_drops'.tr();
      case WishlistFilter.enrolled:
        return 'wishlist.filter_enrolled'.tr();
    }
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color actionColor;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? actionColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? actionColor
                : (isDark ? AppColors.grey400 : AppColors.grey500),
          ),
        ),
      ),
    );
  }
}
