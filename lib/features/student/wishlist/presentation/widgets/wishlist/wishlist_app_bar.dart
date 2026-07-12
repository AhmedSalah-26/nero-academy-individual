import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Wishlist App Bar - Header with title and clear button
class WishlistAppBar extends StatelessWidget {
  final bool isDark;
  final bool hasItems;
  final VoidCallback? onClear;

  const WishlistAppBar({
    super.key,
    required this.isDark,
    this.hasItems = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.95)
              : AppColors.backgroundLight.withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppColors.grey800.withValues(alpha: 0.5)
                  : AppColors.grey200.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 44,
                  iconSize: 19,
                  borderRadius: 14,
                  iconColor:
                      isDark ? AppColors.grey400 : AppColors.textMainLight,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'wishlist.title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
            if (hasItems && onClear != null)
              GlassIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: onClear,
                size: 44,
                iconSize: 22,
                borderRadius: 14,
                iconColor: AppColors.error,
              ),
          ],
        ),
      ),
    );
  }
}
