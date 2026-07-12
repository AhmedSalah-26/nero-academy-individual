/// Admin Coupon Model - Complete schema fields
class AdminCouponModel {
  final String id;
  final String code;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String discountType; // 'percentage' | 'fixed'
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int? usageLimit;
  final int usageCount;
  final int usageLimitPerUser;
  final DateTime startDate;
  final DateTime? endDate;
  final String scope; // 'all' | 'categories' | 'courses' | 'instructors'
  final String? instructorId;
  final String? instructorName;
  final bool isActive;
  final bool isSuspended;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Related data
  final List<String>? categoryIds;
  final List<String>? courseIds;

  const AdminCouponModel({
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
    this.instructorId,
    this.instructorName,
    this.isActive = true,
    this.isSuspended = false,
    required this.createdAt,
    DateTime? updatedAt,
    this.categoryIds,
    this.courseIds,
  }) : updatedAt = updatedAt ?? createdAt;

  factory AdminCouponModel.fromJson(Map<String, dynamic> json) {
    return AdminCouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      usageLimitPerUser: json['usage_limit_per_user'] as int? ?? 1,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      scope: json['scope'] as String? ?? 'all',
      instructorId: json['instructor_id'] as String?,
      instructorName: _extractInstructorName(json['instructor']),
      isActive: json['is_active'] as bool? ?? true,
      isSuspended: json['is_suspended'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      categoryIds: (json['category_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      courseIds: (json['course_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  static String? _extractInstructorName(dynamic instructor) {
    if (instructor == null) return null;
    if (instructor is Map<String, dynamic>) {
      return instructor['name'] as String?;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount_amount': maxDiscountAmount,
      'min_order_amount': minOrderAmount,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'usage_limit_per_user': usageLimitPerUser,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'scope': scope,
      'instructor_id': instructorId,
      'is_active': isActive,
      'is_suspended': isSuspended,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if coupon is expired
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);

  /// Check if coupon has reached usage limit
  bool get isUsageLimitReached =>
      usageLimit != null && usageCount >= usageLimit!;

  /// Check if coupon is currently valid
  bool get isValid =>
      isActive &&
      !isSuspended &&
      !isExpired &&
      !isUsageLimitReached &&
      DateTime.now().isAfter(startDate);

  /// Get status label
  String get statusLabel {
    if (isSuspended) return 'suspended';
    if (!isActive) return 'inactive';
    if (isExpired) return 'expired';
    if (isUsageLimitReached) return 'limit_reached';
    if (DateTime.now().isBefore(startDate)) return 'scheduled';
    return 'active';
  }

  /// Get discount display text
  String get discountDisplay {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}%';
    }
    return '\$${discountValue.toStringAsFixed(0)}';
  }

  AdminCouponModel copyWith({
    String? id,
    String? code,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? discountType,
    double? discountValue,
    double? maxDiscountAmount,
    double? minOrderAmount,
    int? usageLimit,
    int? usageCount,
    int? usageLimitPerUser,
    DateTime? startDate,
    DateTime? endDate,
    String? scope,
    String? instructorId,
    String? instructorName,
    bool? isActive,
    bool? isSuspended,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? categoryIds,
    List<String>? courseIds,
  }) {
    return AdminCouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      scope: scope ?? this.scope,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryIds: categoryIds ?? this.categoryIds,
      courseIds: courseIds ?? this.courseIds,
    );
  }
}

/// DTO for creating/updating coupons
class CreateCouponDto {
  final String code;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int? usageLimit;
  final int usageLimitPerUser;
  final DateTime startDate;
  final DateTime? endDate;
  final String scope;
  final List<String>? categoryIds;
  final List<String>? courseIds;

  const CreateCouponDto({
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
    this.usageLimitPerUser = 1,
    required this.startDate,
    this.endDate,
    this.scope = 'all',
    this.categoryIds,
    this.courseIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code.toUpperCase(),
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount_amount': maxDiscountAmount,
      'min_order_amount': minOrderAmount,
      'usage_limit': usageLimit,
      'usage_limit_per_user': usageLimitPerUser,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'scope': scope,
    };
  }

  /// Validate the DTO
  String? validate() {
    if (code.isEmpty) return 'Coupon code is required';
    if (code.length < 3) return 'Coupon code must be at least 3 characters';
    if (nameAr.isEmpty) return 'Arabic name is required';
    if (discountValue <= 0) return 'Discount value must be greater than 0';
    if (discountType == 'percentage' && discountValue > 100) {
      return 'Percentage discount cannot exceed 100%';
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      return 'End date must be after start date';
    }
    if (scope == 'categories' &&
        (categoryIds == null || categoryIds!.isEmpty)) {
      return 'Select at least one category';
    }
    if (scope == 'courses' && (courseIds == null || courseIds!.isEmpty)) {
      return 'Select at least one course';
    }
    return null;
  }
}

/// Model for coupon usage statistics
class CouponUsageModel {
  final String id;
  final String couponId;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? enrollmentId;
  final String? courseTitleAr;
  final double discountAmount;
  final DateTime usedAt;

  const CouponUsageModel({
    required this.id,
    required this.couponId,
    required this.userId,
    this.userName,
    this.userEmail,
    this.enrollmentId,
    this.courseTitleAr,
    required this.discountAmount,
    required this.usedAt,
  });

  factory CouponUsageModel.fromJson(Map<String, dynamic> json) {
    return CouponUsageModel(
      id: json['id'] as String,
      couponId: json['coupon_id'] as String,
      userId: json['user_id'] as String,
      userName: _extractUserName(json['user']),
      userEmail: _extractUserEmail(json['user']),
      enrollmentId: json['enrollment_id'] as String?,
      courseTitleAr: _extractCourseName(json['enrollment']),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      usedAt: DateTime.parse(json['used_at'] as String),
    );
  }

  static String? _extractUserName(dynamic user) {
    if (user == null) return null;
    if (user is Map<String, dynamic>) {
      return user['name'] as String?;
    }
    return null;
  }

  static String? _extractUserEmail(dynamic user) {
    if (user == null) return null;
    if (user is Map<String, dynamic>) {
      return user['email'] as String?;
    }
    return null;
  }

  static String? _extractCourseName(dynamic enrollment) {
    if (enrollment == null) return null;
    if (enrollment is Map<String, dynamic>) {
      final course = enrollment['course'];
      if (course is Map<String, dynamic>) {
        return course['title_ar'] as String?;
      }
    }
    return null;
  }
}
