import 'package:equatable/equatable.dart';

/// Course Entity - Pure Dart Object
class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String instructorName;
  final String? instructorAvatar;
  final String thumbnailUrl;
  final double rating;
  final int reviewCount;
  final double price;
  final double? originalPrice;
  final String? badge; // 'premium', 'new', 'hot'
  final String? categoryId;
  final String? categoryName;
  final int? durationMinutes;
  final int? lectureCount;
  final String? level; // 'beginner', 'intermediate', 'advanced', 'all'
  final DateTime? createdAt;

  const CourseEntity({
    required this.id,
    required this.title,
    required this.instructorName,
    this.instructorAvatar,
    required this.thumbnailUrl,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.originalPrice,
    this.badge,
    this.categoryId,
    this.categoryName,
    this.durationMinutes,
    this.lectureCount,
    this.level,
    this.createdAt,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  String get formattedDuration {
    if (durationMinutes == null) return '';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        instructorName,
        instructorAvatar,
        thumbnailUrl,
        rating,
        reviewCount,
        price,
        originalPrice,
        badge,
        categoryId,
        categoryName,
        durationMinutes,
        lectureCount,
        level,
        createdAt,
      ];
}
