import '../../domain/entities/admin_entities.dart';

/// Course Report Model
class CourseReportModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String userId;
  final String userName;
  final String reason;
  final String? description;
  final ReportStatus status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const CourseReportModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    required this.userName,
    required this.reason,
    this.description,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.resolvedAt,
  });

  factory CourseReportModel.fromJson(Map<String, dynamic> json) {
    return CourseReportModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      courseTitle: json['course_title'] as String? ??
          json['course']?['title_ar'] as String? ??
          '',
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ??
          json['user']?['name'] as String? ??
          'Unknown',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String?),
      adminResponse: json['admin_response'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
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
      'course_id': courseId,
      'course_title': courseTitle,
      'user_id': userId,
      'user_name': userName,
      'reason': reason,
      'description': description,
      'status': status.name,
      'admin_response': adminResponse,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}
