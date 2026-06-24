import 'package:equatable/equatable.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../../../home/domain/entities/course_entity.dart';
import 'instructor_entity.dart';
import 'section_entity.dart';
import 'review_entity.dart';

/// Enrollment Status Enum
enum EnrollmentStatus {
  notEnrolled,
  inCart,
  enrolled,
  completed;

  static EnrollmentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'active':
        return EnrollmentStatus.enrolled;
      case 'completed':
        return EnrollmentStatus.completed;
      default:
        return EnrollmentStatus.notEnrolled;
    }
  }
}

/// Course Details Entity - Extended Course with full details
class CourseDetailsEntity extends Equatable {
  final String id;
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final CourseLevel level;
  final String language;
  final double price;
  final double? discountPrice;
  final String currency;
  final bool isFree;
  final bool isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final String? badge;
  final List<CoursePricingOption> pricingOptions;
  final CourseGroupLinks groupLinks;
  final double rating;
  final int ratingCount;
  final int enrolledCount;
  final int totalDuration;
  final int totalLessons;
  final int totalQuizzes;
  final bool isFeatured;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  // Extended fields
  final List<String> objectives;
  final List<String> requirements;
  final List<String> targetAudience;
  final bool hasCertificate;
  final InstructorEntity? instructor;
  final List<SectionEntity> sections;
  final RatingSummary? ratingSummary;
  final List<ReviewEntity> topReviews;

  // User-specific fields
  final EnrollmentStatus enrollmentStatus;
  final String? enrollmentId;
  final double progressPercentage;
  final bool isInWishlist;
  final bool isInCart;

  const CourseDetailsEntity({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.level = CourseLevel.allLevels,
    this.language = 'ar',
    this.price = 0,
    this.discountPrice,
    this.currency = 'EGP',
    this.isFree = false,
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.badge,
    this.pricingOptions = const [],
    this.groupLinks = const CourseGroupLinks(),
    this.rating = 0,
    this.ratingCount = 0,
    this.enrolledCount = 0,
    this.totalDuration = 0,
    this.totalLessons = 0,
    this.totalQuizzes = 0,
    this.isFeatured = false,
    this.updatedAt,
    this.publishedAt,
    this.objectives = const [],
    this.requirements = const [],
    this.targetAudience = const [],
    this.hasCertificate = false,
    this.instructor,
    this.sections = const [],
    this.ratingSummary,
    this.topReviews = const [],
    this.enrollmentStatus = EnrollmentStatus.notEnrolled,
    this.enrollmentId,
    this.progressPercentage = 0,
    this.isInWishlist = false,
    this.isInCart = false,
  });

  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');

  String getSubtitle(String locale) => locale == 'ar'
      ? (subtitleAr ?? subtitleEn ?? '')
      : (subtitleEn ?? subtitleAr ?? '');

  String getDescription(String locale) => locale == 'ar'
      ? (descriptionAr ?? descriptionEn ?? '')
      : (descriptionEn ?? descriptionAr ?? '');

  /// Get current effective price
  double get currentPrice {
    if (isFree) return 0;
    if (pricingOptions.isNotEmpty) {
      final prices = pricingOptions.map((option) => option.price).toList()
        ..sort();
      return prices.first.round().toDouble();
    }
    // Flash sale makes discount time-limited
    if (isFlashSale) {
      final price =
          isFlashSaleActive ? (discountPrice ?? this.price) : this.price;
      return price.round().toDouble();
    }
    final price = discountPrice ?? this.price;
    return price.round().toDouble();
  }

  /// Check if flash sale is currently active
  bool get isFlashSaleActive {
    if (!isFlashSale) return false;
    if (flashSaleStart != null && DateTime.now().isBefore(flashSaleStart!)) {
      return false;
    }
    if (flashSaleEnd != null && DateTime.now().isAfter(flashSaleEnd!)) {
      return false;
    }
    return true;
  }

  /// Get discount percentage
  int? get discountPercentage {
    if (isFree || price <= 0) return null;
    if (discountPrice == null || discountPrice! >= price) return null;
    // If flash sale, only show discount when active
    if (isFlashSale && !isFlashSaleActive) return null;
    return ((price - discountPrice!) / price * 100).round();
  }

  /// Format duration as "Xh Ym"
  String get formattedDuration {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Check if user is enrolled
  bool get isEnrolled =>
      enrollmentStatus == EnrollmentStatus.enrolled ||
      enrollmentStatus == EnrollmentStatus.completed;

  @override
  List<Object?> get props => [
        id,
        titleAr,
        titleEn,
        price,
        discountPrice,
        isFlashSale,
        flashSaleStart,
        flashSaleEnd,
        badge,
        pricingOptions,
        groupLinks,
        rating,
        enrolledCount,
        enrollmentStatus,
        isInWishlist,
        isInCart,
        progressPercentage,
      ];
}
