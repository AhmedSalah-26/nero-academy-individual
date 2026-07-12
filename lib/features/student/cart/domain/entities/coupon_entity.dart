import 'package:equatable/equatable.dart';

/// Discount Type Enum
enum DiscountType {
  percentage,
  fixed;

  static DiscountType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'percentage':
        return DiscountType.percentage;
      case 'fixed':
        return DiscountType.fixed;
      default:
        return DiscountType.percentage;
    }
  }
}

/// Coupon Entity - Pure Dart Object
class CouponEntity extends Equatable {
  final String id;
  final String code;
  final String? nameAr;
  final String? nameEn;
  final DiscountType discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderAmount;
  final int? usageLimit;
  final int usageCount;
  final int usageLimitPerUser;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const CouponEntity({
    required this.id,
    required this.code,
    this.nameAr,
    this.nameEn,
    this.discountType = DiscountType.percentage,
    this.discountValue = 0,
    this.maxDiscountAmount,
    this.minOrderAmount,
    this.usageLimit,
    this.usageCount = 0,
    this.usageLimitPerUser = 1,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  /// Get name based on locale
  String getName(String locale) =>
      locale == 'ar' ? (nameAr ?? nameEn ?? code) : (nameEn ?? nameAr ?? code);

  /// Calculate discount amount for a given subtotal
  double calculateDiscount(double subtotal) {
    if (!isActive) return 0;
    if (minOrderAmount != null && subtotal < minOrderAmount!) return 0;

    double discount;
    if (discountType == DiscountType.percentage) {
      discount = subtotal * (discountValue / 100);
    } else {
      discount = discountValue;
    }

    if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
      discount = maxDiscountAmount!;
    }

    return discount > subtotal ? subtotal : discount;
  }

  /// Check if coupon is valid
  bool get isValid {
    if (!isActive) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(_effectiveStartDate(startDate!))) {
      return false;
    }
    if (endDate != null && now.isAfter(_effectiveEndDate(endDate!))) {
      return false;
    }
    return true;
  }

  DateTime _effectiveStartDate(DateTime value) {
    // Existing coupons may have been saved about one hour in the future due to
    // timezone conversion. Treat near-future start dates as active immediately.
    final now = DateTime.now();
    if (value.isAfter(now) && value.difference(now).inHours < 2) {
      return now;
    }

    return value;
  }

  DateTime _effectiveEndDate(DateTime value) {
    final isDateOnly = value.hour == 0 &&
        value.minute == 0 &&
        value.second == 0 &&
        value.millisecond == 0 &&
        value.microsecond == 0;
    if (!isDateOnly) return value;

    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999, 999);
  }

  @override
  List<Object?> get props => [
        id,
        code,
        discountType,
        discountValue,
        usageLimit,
        usageCount,
        usageLimitPerUser,
        isActive,
      ];
}
