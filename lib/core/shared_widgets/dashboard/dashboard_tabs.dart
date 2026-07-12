import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Dashboard Tab Item
class DashboardTabItem {
  final String label;
  final String labelAr;
  final String? badge;
  final IconData? icon;

  const DashboardTabItem({
    required this.label,
    required this.labelAr,
    this.badge,
    this.icon,
  });

  String getLabel(bool isArabic) => isArabic ? labelAr : label;
}

/// Dashboard Tabs - Tab bar with badge support
class DashboardTabs extends StatelessWidget {
  final List<DashboardTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;

  const DashboardTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final screenWidth = MediaQuery.of(context).size.width;

    // Auto-detect if scrollable is needed based on screen width and tab count
    final shouldScroll = isScrollable || screenWidth < 600 || tabs.length > 5;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: shouldScroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildTabs(isDark, isArabic),
              ),
            )
          : Row(
              children: _buildTabs(isDark, isArabic)
                  .map((tab) => Expanded(child: tab))
                  .toList(),
            ),
    );
  }

  List<Widget> _buildTabs(bool isDark, bool isArabic) {
    return tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final isSelected = index == selectedIndex;

      return _TabButton(
        tab: tab,
        isSelected: isSelected,
        isDark: isDark,
        isArabic: isArabic,
        onTap: () => onTabSelected(index),
      );
    }).toList();
  }
}

class _TabButton extends StatelessWidget {
  final DashboardTabItem tab;
  final bool isSelected;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.isSelected,
    required this.isDark,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(
          minWidth: 60,
          maxWidth: 200,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cardDark : AppColors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tab.icon != null) ...[
              Icon(
                tab.icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                tab.getLabel(isArabic),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            if (tab.badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tab.badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
