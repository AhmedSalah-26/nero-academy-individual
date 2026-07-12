import 'package:equatable/equatable.dart';

/// Review Entity - Pure Dart Object
class ReviewEntity extends Equatable {
  final String id;
  final String courseId;
  final String userId;
  final String? userName;
  final String? userAvatarUrl;
  final int rating;
  final String? title;
  final String? comment;
  final int helpfulCount;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReviewEntity({
    required this.id,
    required this.courseId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.rating,
    this.title,
    this.comment,
    this.helpfulCount = 0,
    this.isVerifiedPurchase = false,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        courseId,
        userId,
        userName,
        rating,
        title,
        comment,
        helpfulCount,
        isVerifiedPurchase,
        createdAt,
      ];
}

/// Rating Summary for course
class RatingSummary extends Equatable {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  const RatingSummary({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.fiveStarCount = 0,
    this.fourStarCount = 0,
    this.threeStarCount = 0,
    this.twoStarCount = 0,
    this.oneStarCount = 0,
  });

  double getPercentage(int starCount) {
    if (totalReviews == 0) return 0;
    return starCount / totalReviews;
  }

  @override
  List<Object?> get props => [
        averageRating,
        totalReviews,
        fiveStarCount,
        fourStarCount,
        threeStarCount,
        twoStarCount,
        oneStarCount,
      ];
}
