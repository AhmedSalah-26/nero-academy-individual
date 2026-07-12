import '../../domain/entities/review_entity.dart';

/// Review Model - Data Model with JSON serialization
class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.courseId,
    required super.userId,
    super.userName,
    super.userAvatarUrl,
    required super.rating,
    super.title,
    super.comment,
    super.helpfulCount,
    super.isVerifiedPurchase,
    required super.createdAt,
    super.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Handle nested profile
    final profile = json['profiles'] as Map<String, dynamic>?;

    return ReviewModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      userName: profile?['name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      comment: json['review'] as String?,
      helpfulCount: 0,
      isVerifiedPurchase: false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'user_id': userId,
      'rating': rating,
      'review': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Rating Summary Model
class RatingSummaryModel extends RatingSummary {
  const RatingSummaryModel({
    super.averageRating,
    super.totalReviews,
    super.fiveStarCount,
    super.fourStarCount,
    super.threeStarCount,
    super.twoStarCount,
    super.oneStarCount,
  });

  factory RatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return RatingSummaryModel(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      fiveStarCount: json['five_star_count'] as int? ?? 0,
      fourStarCount: json['four_star_count'] as int? ?? 0,
      threeStarCount: json['three_star_count'] as int? ?? 0,
      twoStarCount: json['two_star_count'] as int? ?? 0,
      oneStarCount: json['one_star_count'] as int? ?? 0,
    );
  }
}
