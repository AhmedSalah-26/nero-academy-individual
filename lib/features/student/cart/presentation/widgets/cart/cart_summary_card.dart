import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Cart Summary Card - Professional Design
class CartSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double total;
  final String currency;
  final int itemsCount;
  final VoidCallback onCheckout;

  const CartSummaryCard({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.currency,
    required this.itemsCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Summary rows
          _buildRow(
            'cart.subtotal'.tr(),
            '$currency ${subtotal.toStringAsFixed(0)}',
            isDark,
          ),
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildRow(
              'cart.discount'.tr(),
              '-$currency ${discountAmount.toStringAsFixed(0)}',
              isDark,
              valueColor: AppColors.success,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.grey200,
            ),
          ),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cart.total'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              Text(
                '$currency ${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'cart.checkout'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (isDark ? AppColors.textMainDark : AppColors.textMainLight),
          ),
        ),
      ],
    );
  }
}
