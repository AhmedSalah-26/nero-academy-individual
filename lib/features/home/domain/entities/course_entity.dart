import 'package:equatable/equatable.dart';
import '../../../../core/utils/availability_window.dart';

/// Course Entity - Pure Dart Object for Course Cards
class CourseEntity extends Equatable {
  final String id;
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final String instructorId;
  final String? instructorName;
  final String? instructorAvatarUrl;
  final String? categoryId;
  final CourseLevel level;
  final String language;
  final double price;
  final double? discountPrice;
  final String currency;
  final bool isFree;
  final bool isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final double rating;
  final int ratingCount;
  final int enrolledCount;
  final int totalDuration; // in minutes
  final int totalLessons;
  final bool isFeatured;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime createdAt;
  final String? badge;

  const CourseEntity({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.thumbnailUrl,
    this.previewVideoUrl,
    required this.instructorId,
    this.instructorName,
    this.instructorAvatarUrl,
    this.categoryId,
    this.level = CourseLevel.allLevels,
    this.language = 'ar',
    this.price = 0,
    this.discountPrice,
    this.currency = 'EGP',
    this.isFree = false,
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.rating = 0,
    this.ratingCount = 0,
    this.enrolledCount = 0,
    this.totalDuration = 0,
    this.totalLessons = 0,
    this.isFeatured = false,
    this.isPublished = false,
    this.publishedAt,
    this.availableFrom,
    this.availableUntil,
    required this.createdAt,
    this.badge,
  });

  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');
  String getSubtitle(String locale) => locale == 'ar'
      ? (subtitleAr ?? subtitleEn ?? '')
      : (subtitleEn ?? subtitleAr ?? '');

  /// Get current effective price
  double get currentPrice {
    if (isFree) return 0;
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
    final now = DateTime.now();
    if (flashSaleStart != null && now.isBefore(flashSaleStart!)) return false;
    if (flashSaleEnd != null && now.isAfter(flashSaleEnd!)) return false;
    return true;
  }

  bool get isCurrentlyAvailable => AvailabilityWindow.isActive(
        availableFrom: availableFrom,
        availableUntil: availableUntil,
      );

  /// Get discount percentage
  int? get discountPercentage {
    if (isFree || price <= 0) return null;
    if (discountPrice == null || discountPrice! >= price) return null;
    // If flash sale, only show discount when active
    if (isFlashSale && !isFlashSaleActive) return null;
    return ((price - discountPrice!) / price * 100).round();
  }

  /// Get effective badge (hides flash sale badge when sale is not active)
  String? get effectiveBadge {
    if (isFlashSale && !isFlashSaleActive) return null;
    return badge;
  }

  /// Format duration as "Xh Ym"
  String get formattedDuration {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  @override
  List<Object?> get props => [
        id,
        titleAr,
        titleEn,
        subtitleAr,
        subtitleEn,
        thumbnailUrl,
        previewVideoUrl,
        instructorId,
        instructorName,
        instructorAvatarUrl,
        categoryId,
        level,
        language,
        price,
        discountPrice,
        currency,
        isFree,
        isFlashSale,
        flashSaleStart,
        flashSaleEnd,
        rating,
        ratingCount,
        enrolledCount,
        totalDuration,
        totalLessons,
        isFeatured,
        isPublished,
        publishedAt,
        availableFrom,
        availableUntil,
        createdAt,
        badge,
      ];
}

/// Course Level Enum
enum CourseLevel {
  beginner,
  intermediate,
  advanced,
  allLevels;

  static CourseLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'beginner':
        return CourseLevel.beginner;
      case 'intermediate':
        return CourseLevel.intermediate;
      case 'advanced':
        return CourseLevel.advanced;
      default:
        return CourseLevel.allLevels;
    }
  }

  String toJson() => name;

  String getDisplayName(String locale) {
    if (locale == 'ar') {
      switch (this) {
        case CourseLevel.beginner:
          return 'مبتدئ';
        case CourseLevel.intermediate:
          return 'متوسط';
        case CourseLevel.advanced:
          return 'متقدم';
        case CourseLevel.allLevels:
          return 'جميع المستويات';
      }
    }
    return name[0].toUpperCase() + name.substring(1);
  }
}
