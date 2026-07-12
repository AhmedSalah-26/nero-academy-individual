/// Review Entity - represents a course review
class ReviewEntity {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String? review;
  final DateTime createdAt;

  ReviewEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> json) {
    // Handle profiles data from join
    final profiles = json['profiles'] as Map<String, dynamic>?;

    return ReviewEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profiles?['name'] as String? ?? 'مستخدم',
      userAvatar: profiles?['avatar_url'] as String?,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
