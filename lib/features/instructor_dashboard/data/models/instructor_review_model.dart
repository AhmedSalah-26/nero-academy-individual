/// Instructor Review Model
class InstructorReviewModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String? comment;
  final bool isFeatured;
  final DateTime createdAt;

  const InstructorReviewModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    required this.isFeatured,
    required this.createdAt,
  });

  factory InstructorReviewModel.fromJson(Map<String, dynamic> json) {
    return InstructorReviewModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      courseTitle: json['course']?['title_ar'] as String? ?? '',
      userId: json['user_id'] as String,
      userName: json['user']?['name'] as String? ?? 'Unknown',
      userAvatar: json['user']?['avatar_url'] as String?,
      rating: json['rating'] as int? ?? 0,
      comment: json['review'] as String?,
      isFeatured: false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
