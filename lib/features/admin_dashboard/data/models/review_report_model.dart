import '../../domain/entities/admin_entities.dart';

/// Review Report Model
class ReviewReportModel {
  final String id;
  final String? reviewId;
  final String userId;
  final String userName;
  final String reason;
  final String? description;
  final String? cachedReviewComment;
  final int? cachedReviewRating;
  final ReportStatus status;
  final DateTime createdAt;

  const ReviewReportModel({
    required this.id,
    this.reviewId,
    required this.userId,
    required this.userName,
    required this.reason,
    this.description,
    this.cachedReviewComment,
    this.cachedReviewRating,
    required this.status,
    required this.createdAt,
  });

  factory ReviewReportModel.fromJson(Map<String, dynamic> json) {
    return ReviewReportModel(
      id: json['id'] as String,
      reviewId: json['review_id'] as String?,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ??
          json['user']?['name'] as String? ??
          'Unknown',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      cachedReviewComment: json['cached_review_comment'] as String?,
      cachedReviewRating: json['cached_review_rating'] as int?,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_id': reviewId,
      'user_id': userId,
      'user_name': userName,
      'reason': reason,
      'description': description,
      'cached_review_comment': cachedReviewComment,
      'cached_review_rating': cachedReviewRating,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
