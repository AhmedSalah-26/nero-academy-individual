import '../../../../core/models/course_commerce_models.dart';
import '../../domain/entities/course_entity.dart';

/// Course Model - Data Model with JSON serialization
class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    super.titleAr,
    super.titleEn,
    super.subtitleAr,
    super.subtitleEn,
    super.thumbnailUrl,
    super.previewVideoUrl,
    required super.instructorId,
    super.instructorName,
    super.instructorAvatarUrl,
    super.categoryId,
    super.level,
    super.language,
    super.price,
    super.discountPrice,
    super.currency,
    super.isFree,
    super.isFlashSale,
    super.flashSaleStart,
    super.flashSaleEnd,
    super.rating,
    super.ratingCount,
    super.enrolledCount,
    super.totalDuration,
    super.totalLessons,
    super.isFeatured,
    super.isPublished,
    super.publishedAt,
    super.availableFrom,
    super.availableUntil,
    required super.createdAt,
    super.badge,
    super.pricingOptions,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    // Handle nested instructor profile
    final instructor = json['profiles'] as Map<String, dynamic>?;

    return CourseModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      previewVideoUrl: json['preview_video_url'] as String?,
      instructorId: json['instructor_id'] as String,
      instructorName: instructor?['name'] as String?,
      instructorAvatarUrl: instructor?['avatar_url'] as String?,
      categoryId: json['category_id'] as String?,
      level: CourseLevel.fromString(json['level'] as String?),
      language: json['language'] as String? ?? 'ar',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      isFree: json['is_free'] as bool? ?? false,
      isFlashSale: json['is_flash_sale'] as bool? ?? false,
      flashSaleStart: json['flash_sale_start'] != null
          ? DateTime.parse(json['flash_sale_start'] as String)
          : null,
      flashSaleEnd: json['flash_sale_end'] != null
          ? DateTime.parse(json['flash_sale_end'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
      totalDuration: json['total_duration'] as int? ?? 0,
      totalLessons: json['total_lessons'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : null,
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      badge: json['badge'] as String?,
      pricingOptions: parseCoursePricingOptions(json['pricing_options']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'subtitle_ar': subtitleAr,
      'subtitle_en': subtitleEn,
      'thumbnail_url': thumbnailUrl,
      'preview_video_url': previewVideoUrl,
      'instructor_id': instructorId,
      'category_id': categoryId,
      'level': level.toJson(),
      'language': language,
      'price': price,
      'discount_price': discountPrice,
      'currency': currency,
      'is_free': isFree,
      'is_flash_sale': isFlashSale,
      'flash_sale_start': flashSaleStart?.toIso8601String(),
      'flash_sale_end': flashSaleEnd?.toIso8601String(),
      'rating': rating,
      'rating_count': ratingCount,
      'enrolled_count': enrolledCount,
      'total_duration': totalDuration,
      'total_lessons': totalLessons,
      'is_featured': isFeatured,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'available_from': availableFrom?.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'badge': badge,
    };
  }
}
