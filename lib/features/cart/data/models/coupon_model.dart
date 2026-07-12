import '../../domain/entities/coupon_entity.dart';

/// Coupon Model - Data Model with JSON serialization
class CouponModel extends CouponEntity {
  const CouponModel({
    required super.id,
    required super.code,
    super.nameAr,
    super.nameEn,
    super.discountType,
    super.discountValue,
    super.maxDiscountAmount,
    super.minOrderAmount,
    super.usageLimit,
    super.usageCount,
    super.usageLimitPerUser,
    super.startDate,
    super.endDate,
    super.isActive,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      nameAr: json['name_ar'] as String?,
      nameEn: json['name_en'] as String?,
      discountType: DiscountType.fromString(json['discount_type'] as String?),
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      usageLimitPerUser: json['usage_limit_per_user'] as int? ?? 1,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_ar': nameAr,
      'name_en': nameEn,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'max_discount_amount': maxDiscountAmount,
      'min_order_amount': minOrderAmount,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'usage_limit_per_user': usageLimitPerUser,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
