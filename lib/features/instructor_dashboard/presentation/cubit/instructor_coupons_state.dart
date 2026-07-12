part of 'instructor_coupons_cubit.dart';

/// Instructor Coupons Status
enum InstructorCouponsStatus { initial, loading, success, error }

/// Coupon Status Filter
enum CouponStatusFilter { all, active, expired }

/// Instructor Coupons State
class InstructorCouponsState extends Equatable {
  final InstructorCouponsStatus status;
  final List<InstructorCouponModel> coupons;
  final CouponStatusFilter filter;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const InstructorCouponsState({
    this.status = InstructorCouponsStatus.initial,
    this.coupons = const [],
    this.filter = CouponStatusFilter.all,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorCouponsStatus.loading;

  List<InstructorCouponModel> get filteredCoupons {
    switch (filter) {
      case CouponStatusFilter.active:
        return coupons.where((c) => c.isActive && !c.isExpired).toList();
      case CouponStatusFilter.expired:
        return coupons.where((c) => c.isExpired || !c.isActive).toList();
      case CouponStatusFilter.all:
        return coupons;
    }
  }

  InstructorCouponsState copyWith({
    InstructorCouponsStatus? status,
    List<InstructorCouponModel>? coupons,
    CouponStatusFilter? filter,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorCouponsState(
      status: status ?? this.status,
      coupons: coupons ?? this.coupons,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, coupons, filter, isLoadingMore, hasMore, errorMessage];
}

/// Instructor Coupon Model
class InstructorCouponModel extends Equatable {
  final String id;
  final String code;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String discountType; // percentage, fixed
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int? usageLimit;
  final int usageCount;
  final int usageLimitPerUser;
  final DateTime startDate;
  final DateTime? endDate;
  final String scope; // all, categories, courses, instructors
  final List<String> courseIds;
  final bool isActive;
  final bool isSuspended;
  final DateTime createdAt;

  const InstructorCouponModel({
    required this.id,
    required this.code,
    required this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.minOrderAmount = 0,
    this.usageLimit,
    this.usageCount = 0,
    this.usageLimitPerUser = 1,
    required this.startDate,
    this.endDate,
    this.scope = 'all',
    this.courseIds = const [],
    this.isActive = true,
    this.isSuspended = false,
    required this.createdAt,
  });

  bool get isExpired =>
      endDate != null && DateTime.now().isAfter(_effectiveEndDate(endDate!));

  DateTime _effectiveEndDate(DateTime value) {
    final isDateOnly = value.hour == 0 &&
        value.minute == 0 &&
        value.second == 0 &&
        value.millisecond == 0 &&
        value.microsecond == 0;
    if (!isDateOnly) return value;

    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999, 999);
  }

  bool get isMaxUsesReached => usageLimit != null && usageCount >= usageLimit!;

  factory InstructorCouponModel.fromJson(Map<String, dynamic> json) {
    final couponCourses = json['coupon_courses'] as List?;

    return InstructorCouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      discountType: json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      usageLimitPerUser: json['usage_limit_per_user'] as int? ?? 1,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      scope: json['scope'] as String? ?? 'all',
      courseIds: couponCourses == null
          ? const []
          : couponCourses
              .map((item) => item['course_id'] as String?)
              .whereType<String>()
              .toList(),
      isActive: json['is_active'] as bool? ?? true,
      isSuspended: json['is_suspended'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        nameAr,
        discountType,
        discountValue,
        usageLimit,
        usageCount,
        endDate,
        courseIds,
        isActive,
        createdAt,
      ];
}
