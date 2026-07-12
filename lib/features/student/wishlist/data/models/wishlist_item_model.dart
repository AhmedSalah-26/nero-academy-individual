import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';

/// Wishlist Item Model - Data Model with JSON serialization
class WishlistItemModel extends WishlistItemEntity {
  const WishlistItemModel({
    required super.id,
    required super.courseId,
    super.titleAr,
    super.titleEn,
    super.thumbnailUrl,
    super.instructorName,
    super.rating,
    super.ratingCount,
    super.price,
    super.discountPrice,
    super.currency,
    super.isFree,
    super.isEnrolled,
    super.isBestseller,
    required super.addedAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>?;

    // Handle instructor name from profiles
    String? instructorName;
    final profiles = course?['profiles'] as Map<String, dynamic>?;
    if (profiles != null) {
      instructorName = profiles['name'] as String?;
    } else {
      instructorName = json['instructor_name'] as String?;
    }

    // Check enrollment status
    final enrollments = course?['enrollments'] as List?;
    final isEnrolled = enrollments != null && enrollments.isNotEmpty;

    return WishlistItemModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      titleAr: course?['title_ar'] as String? ?? json['title_ar'] as String?,
      titleEn: course?['title_en'] as String? ?? json['title_en'] as String?,
      thumbnailUrl: course?['thumbnail_url'] as String? ??
          json['thumbnail_url'] as String?,
      instructorName: instructorName,
      rating: (course?['rating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0,
      ratingCount:
          course?['rating_count'] as int? ?? json['rating_count'] as int? ?? 0,
      price: (course?['price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      discountPrice: _resolveEffectiveDiscountPrice(course, json),
      currency: course?['currency'] as String? ??
          json['currency'] as String? ??
          'EGP',
      isFree: course?['is_free'] as bool? ?? json['is_free'] as bool? ?? false,
      isEnrolled: isEnrolled,
      isBestseller: false, // Column doesn't exist in DB yet
      addedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'thumbnail_url': thumbnailUrl,
      'instructor_name': instructorName,
      'rating': rating,
      'rating_count': ratingCount,
      'price': price,
      'discount_price': discountPrice,
      'currency': currency,
      'is_free': isFree,
      'is_enrolled': isEnrolled,
      'is_bestseller': isBestseller,
      'created_at': addedAt.toIso8601String(),
    };
  }

  static double? _resolveEffectiveDiscountPrice(
    Map<String, dynamic>? course,
    Map<String, dynamic> json,
  ) {
    final baseDiscountPrice = (course?['discount_price'] as num?)?.toDouble() ??
        (json['discount_price'] as num?)?.toDouble();

    final isFlashSale = (course?['is_flash_sale'] as bool?) ??
        (json['is_flash_sale'] as bool?) ??
        false;

    if (!isFlashSale) {
      return baseDiscountPrice;
    }

    final flashSaleStart =
        _parseDateTime(course?['flash_sale_start'] ?? json['flash_sale_start']);
    final flashSaleEnd =
        _parseDateTime(course?['flash_sale_end'] ?? json['flash_sale_end']);
    final now = DateTime.now();
    final isFlashSaleActive =
        (flashSaleStart == null || !now.isBefore(flashSaleStart)) &&
            (flashSaleEnd == null || !now.isAfter(flashSaleEnd));

    return isFlashSaleActive ? baseDiscountPrice : null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
