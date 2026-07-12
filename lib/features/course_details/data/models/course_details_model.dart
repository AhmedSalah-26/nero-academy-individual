import '../../../home/domain/entities/course_entity.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../../domain/entities/course_details_entity.dart';
import 'instructor_model.dart';
import 'section_model.dart';

/// Course Details Model - Data Model with JSON serialization
class CourseDetailsModel extends CourseDetailsEntity {
  const CourseDetailsModel({
    required super.id,
    super.titleAr,
    super.titleEn,
    super.subtitleAr,
    super.subtitleEn,
    super.descriptionAr,
    super.descriptionEn,
    super.thumbnailUrl,
    super.previewVideoUrl,
    super.level,
    super.language,
    super.price,
    super.discountPrice,
    super.currency,
    super.isFree,
    super.isFlashSale,
    super.flashSaleStart,
    super.flashSaleEnd,
    super.badge,
    super.pricingOptions,
    super.groupLinks,
    super.rating,
    super.ratingCount,
    super.enrolledCount,
    super.totalDuration,
    super.totalLessons,
    super.totalQuizzes,
    super.isFeatured,
    super.updatedAt,
    super.publishedAt,
    super.objectives,
    super.requirements,
    super.targetAudience,
    super.hasCertificate,
    super.instructor,
    super.sections,
    super.ratingSummary,
    super.topReviews,
    super.enrollmentStatus,
    super.enrollmentId,
    super.progressPercentage,
    super.isInWishlist,
    super.isInCart,
  });

  factory CourseDetailsModel.fromJson(Map<String, dynamic> json) {
    // Parse instructor
    InstructorModel? instructor;
    if (json['instructor_profiles'] != null) {
      instructor = InstructorModel.fromJson(
          json['instructor_profiles'] as Map<String, dynamic>);
    }

    // Parse objectives, requirements, target_audience from JSON arrays
    List<String> objectives = [];
    if (json['objectives'] != null) {
      objectives = (json['objectives'] as List).cast<String>();
    }

    List<String> requirements = [];
    if (json['requirements'] != null) {
      requirements = (json['requirements'] as List).cast<String>();
    }

    List<String> targetAudience = [];
    if (json['target_audience'] != null) {
      targetAudience = (json['target_audience'] as List).cast<String>();
    }

    // Parse sections
    List<SectionModel> sections = [];
    if (json['sections'] != null) {
      sections = (json['sections'] as List)
          .map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    // Parse enrollment status (from direct fields set by data source)
    final enrollmentStatus =
        EnrollmentStatus.fromString(json['enrollment_status'] as String?);
    final enrollmentId = json['enrollment_id'] as String?;
    final progressPercentage =
        (json['progress_percentage'] as num?)?.toDouble() ?? 0;

    return CourseDetailsModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      previewVideoUrl: json['preview_video_url'] as String?,
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
      badge: json['badge'] as String?,
      pricingOptions: parseCoursePricingOptions(json['pricing_options']),
      groupLinks: CourseGroupLinks.fromJson(
        json['group_links'] as Map<String, dynamic>?,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
      totalDuration: json['total_duration'] as int? ?? 0,
      totalLessons: json['total_lessons'] as int? ?? 0,
      totalQuizzes: json['total_quizzes'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      objectives: objectives,
      requirements: requirements,
      targetAudience: targetAudience,
      hasCertificate: json['has_certificate'] as bool? ?? false,
      instructor: instructor,
      sections: sections,
      enrollmentStatus: enrollmentStatus,
      enrollmentId: enrollmentId,
      progressPercentage: progressPercentage,
      isInWishlist: json['is_in_wishlist'] as bool? ?? false,
      isInCart: json['is_in_cart'] as bool? ?? false,
    );
  }
}
