import '../../domain/entities/admin_entities.dart';

/// Admin Enrollment Model
class AdminEnrollmentModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String userId;
  final String userName;
  final String? userEmail;
  final double price;
  final EnrollmentStatus status;
  final double progress;
  final DateTime enrolledAt;
  final DateTime? completedAt;

  const AdminEnrollmentModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.price,
    required this.status,
    this.progress = 0,
    required this.enrolledAt,
    this.completedAt,
  });

  factory AdminEnrollmentModel.fromJson(Map<String, dynamic> json) {
    return AdminEnrollmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      courseTitle: json['course_title'] as String? ??
          json['course']?['title_ar'] as String? ??
          '',
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ??
          json['user']?['name'] as String? ??
          'Unknown',
      userEmail:
          json['user_email'] as String? ?? json['user']?['email'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: _parseStatus(json['status'] as String?),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  static EnrollmentStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return EnrollmentStatus.active;
      case 'completed':
        return EnrollmentStatus.completed;
      case 'pending':
        return EnrollmentStatus.pending;
      case 'refunded':
        return EnrollmentStatus.refunded;
      default:
        return EnrollmentStatus.active;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_title': courseTitle,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'price': price,
      'status': status.name,
      'progress': progress,
      'enrolled_at': enrolledAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
