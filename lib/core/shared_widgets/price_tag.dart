import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Price Tag Size
enum PriceSize { sm, md, lg }

/// Unified Price Tag Widget
class PriceTag extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final String currency;
  final PriceSize size;
  final bool showFreeLabel;

  const PriceTag({
    super.key,
    required this.price,
    this.originalPrice,
    this.currency = 'EGP',
    this.size = PriceSize.md,
    this.showFreeLabel = true,
  });

  bool get isFree => price == 0;
  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  int get discountPercent => hasDiscount
      ? (((originalPrice! - price) / originalPrice!) * 100).round()
      : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isFree && showFreeLabel) {
      return _buildFreeLabel(isDark);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$currency${price.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: _getPriceFontSize(),
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '$currency${originalPrice!.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: _getOriginalFontSize(),
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
              decoration: TextDecoration.lineThrough,
              decorationColor: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
          const SizedBox(width: 8),
          _buildDiscountBadge(isDark),
        ],
      ],
    );
  }

  Widget _buildFreeLabel(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getFreePadding(),
        vertical: _getFreePadding() / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'FREE',
        style: TextStyle(
          fontFamily: 'Almarai',
          fontSize: _getFreeFontSize(),
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildDiscountBadge(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getBadgePadding(),
        vertical: _getBadgePadding() / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-$discountPercent%',
        style: TextStyle(
          fontFamily: 'Almarai',
          fontSize: _getBadgeFontSize(),
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    );
  }

  double _getPriceFontSize() {
    switch (size) {
      case PriceSize.sm:
        return 14;
      case PriceSize.md:
        return 18;
      case PriceSize.lg:
        return 24;
    }
  }

  double _getOriginalFontSize() {
    switch (size) {
      case PriceSize.sm:
        return 12;
      case PriceSize.md:
        return 14;
      case PriceSize.lg:
        return 18;
    }
  }

  double _getFreeFontSize() {
    switch (size) {
      case PriceSize.sm:
        return 11;
      case PriceSize.md:
        return 13;
      case PriceSize.lg:
        return 16;
    }
  }

  double _getBadgeFontSize() {
    switch (size) {
      case PriceSize.sm:
        return 10;
      case PriceSize.md:
        return 11;
      case PriceSize.lg:
        return 13;
    }
  }

  double _getFreePadding() {
    switch (size) {
      case PriceSize.sm:
        return 6;
      case PriceSize.md:
        return 8;
      case PriceSize.lg:
        return 12;
    }
  }

  double _getBadgePadding() {
    switch (size) {
      case PriceSize.sm:
        return 4;
      case PriceSize.md:
        return 6;
      case PriceSize.lg:
        return 8;
    }
  }
}
