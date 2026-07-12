import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Dashboard Header - Top bar with title and actions
/// Height: 64px desktop, 56px mobile
class DashboardHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final Widget? actions;

  // Dimensions
  static const double desktopHeight = 64;
  static const double mobileHeight = 56;
  static const double mobileBreakpoint = 768;

  const DashboardHeader({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < mobileBreakpoint;
    final height = isMobile ? mobileHeight : desktopHeight;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              onPressed: onMenuPressed,
              icon: Icon(
                Icons.menu_rounded,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              tooltip: 'Menu',
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) actions!,
        ],
      ),
    );
  }
}
