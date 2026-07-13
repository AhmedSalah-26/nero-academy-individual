import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Wishlist Bottom Bar - Shows total value and add all to cart button
class WishlistBottomBar extends StatelessWidget {
  final double totalValue;
  final double totalSavings;
  final String currency;
  final int itemsCount;
  final VoidCallback onAddAllToCart;
  final bool isDark;

  const WishlistBottomBar({
    super.key,
    required this.totalValue,
    required this.totalSavings,
    required this.currency,
    required this.itemsCount,
    required this.onAddAllToCart,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = Theme.of(context).colorScheme.tertiary;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total value
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'wishlist.total_value'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${totalValue.toStringAsFixed(0)}',
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
              // Savings
              if (totalSavings > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'wishlist.you_save'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currency ${totalSavings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Add all to cart button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: itemsCount > 0 ? onAddAllToCart : null,
              icon: const Icon(Icons.shopping_cart_rounded, size: 20),
              label: Text(
                'wishlist.add_all_to_cart'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDark ? AppColors.grey700 : AppColors.grey200,
                disabledForegroundColor:
                    isDark ? AppColors.grey500 : AppColors.grey400,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: actionColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
