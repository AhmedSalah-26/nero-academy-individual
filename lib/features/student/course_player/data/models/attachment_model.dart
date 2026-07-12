import 'package:lms_platform/features/student/course_player/domain/entities/attachment_entity.dart';

/// Attachment Model - Data Model with JSON serialization
class AttachmentModel extends AttachmentEntity {
  const AttachmentModel({
    required super.id,
    super.lessonId,
    required super.fileName,
    super.fileNameAr,
    required super.fileUrl,
    required super.fileType,
    required super.fileSize,
    super.sortOrder,
    super.createdAt,
  });

  /// Create from JSON
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      lessonId:
          json['lesson_id'] as String?, // Can be null for course attachments
      fileName: json['file_name'] as String,
      fileNameAr: json['file_name_ar'] as String?,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      'file_name': fileName,
      'file_name_ar': fileNameAr,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
