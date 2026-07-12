import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Cart App Bar Widget
class CartAppBar extends StatelessWidget {
  final int itemsCount;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final bool isDark;

  const CartAppBar({
    super.key,
    required this.itemsCount,
    required this.onBack,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: AppBackButton(onPressed: onBack),
      title: Text(
        'cart.cart'.tr(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
      centerTitle: true,
      actions: [
        if (itemsCount > 0)
          TextButton(
            onPressed: onClear,
            child: Text(
              'common.delete'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
