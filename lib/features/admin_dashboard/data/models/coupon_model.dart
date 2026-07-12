/// Coupon Model
class CouponModel {
  final String id;
  final String code;
  final String? description;
  final CouponDiscountType discountType;
  final double discountValue;
  final double? minPurchase;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? instructorId;
  final String? instructorName;
  final String? courseId;
  final String? courseTitle;
  final DateTime createdAt;

  const CouponModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minPurchase,
    this.maxDiscount,
    this.usageLimit,
    required this.usedCount,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.instructorId,
    this.instructorName,
    this.courseId,
    this.courseTitle,
    required this.createdAt,
  });

  bool get isGlobal => instructorId == null;
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get isLimitReached => usageLimit != null && usedCount >= usageLimit!;

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: _parseDiscountType(json['discount_type'] as String?),
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      minPurchase: (json['min_purchase'] as num?)?.toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      usageLimit: json['usage_limit'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      instructorId: json['instructor_id'] as String?,
      instructorName: json['instructor']?['name'] as String?,
      courseId: json['course_id'] as String?,
      courseTitle: json['course']?['title_ar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static CouponDiscountType _parseDiscountType(String? type) {
    switch (type) {
      case 'percentage':
        return CouponDiscountType.percentage;
      case 'fixed':
        return CouponDiscountType.fixed;
      default:
        return CouponDiscountType.percentage;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'min_purchase': minPurchase,
      'max_discount': maxDiscount,
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'start_date': startDate?.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'is_active': isActive,
      'instructor_id': instructorId,
      'course_id': courseId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Coupon Discount Type
enum CouponDiscountType { percentage, fixed }

extension CouponDiscountTypeExtension on CouponDiscountType {
  String getLabel(bool isArabic) {
    switch (this) {
      case CouponDiscountType.percentage:
        return isArabic ? 'نسبة مئوية' : 'Percentage';
      case CouponDiscountType.fixed:
        return isArabic ? 'مبلغ ثابت' : 'Fixed Amount';
    }
  }
}
