import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'dashboard_nav_item.dart';

/// Dashboard Sidebar - Collapsible navigation sidebar
/// Width: 250px expanded, 70px collapsed
class DashboardSidebar extends StatelessWidget {
  final List<DashboardNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final String headerTitle;
  final String headerTitleAr;
  final bool showCollapseButton;
  final bool showHeader;

  // Dimensions
  static const double expandedWidth = 250;
  static const double collapsedWidth = 70;
  static const Duration animationDuration = Duration(milliseconds: 200);

  const DashboardSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.headerTitle,
    required this.headerTitleAr,
    this.showCollapseButton = true,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          right: isArabic
              ? BorderSide.none
              : BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
          left: isArabic
              ? BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                )
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          if (showHeader) _buildHeader(context, isDark, isArabic),
          Expanded(child: _buildNavItems(context, isDark, isArabic)),
          _buildBackToUserButton(context, isDark, isArabic),
          if (showCollapseButton) _buildCollapseButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isArabic) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16),
      child: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dashboard_rounded,
                color: AppColors.primary, size: 24),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? headerTitleAr : headerTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  height: 1.2,
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItems(BuildContext context, bool isDark, bool isArabic) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedIndex;
        return _NavItemTile(
          item: item,
          isSelected: isSelected,
          isCollapsed: isCollapsed,
          isDark: isDark,
          isArabic: isArabic,
          onTap: () => onItemSelected(index),
        );
      },
    );
  }

  Widget _buildCollapseButton(BuildContext context, bool isDark) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onToggleCollapse,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCollapsed
                ? (isArabic
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded)
                : (isArabic
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded),
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildBackToUserButton(
      BuildContext context, bool isDark, bool isArabic) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: 8,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go('/home');
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.exit_to_app_rounded,
                  size: 20,
                  color: AppColors.info,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isArabic ? 'الرجوع للوضع العادي' : 'Back to User Mode',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                        height: 1.2,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      textDirection:
                          isArabic ? TextDirection.rtl : TextDirection.ltr,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemTile extends StatelessWidget {
  final DashboardNavItem item;
  final bool isSelected;
  final bool isCollapsed;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.isDark,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = AppColors.primary;
    final unselectedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildIcon(selectedColor, unselectedColor),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _buildLabel(selectedColor, unselectedColor)),
                  if (item.badge != null) _buildBadge(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color selectedColor, Color unselectedColor) {
    return Icon(
      item.icon,
      size: 22,
      color: isSelected ? selectedColor : unselectedColor,
    );
  }

  Widget _buildLabel(Color selectedColor, Color unselectedColor) {
    return Text(
      item.getLabel(isArabic),
      style: TextStyle(
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? selectedColor : unselectedColor,
        height: 1.2,
      ),
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        item.badge!,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
