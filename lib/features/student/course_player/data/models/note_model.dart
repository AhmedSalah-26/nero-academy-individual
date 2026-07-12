import 'package:lms_platform/features/student/course_player/domain/entities/note_entity.dart';

/// Note Model - Data Model with JSON serialization
class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.lessonId,
    required super.userId,
    required super.content,
    super.timestampSeconds,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from JSON
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      timestampSeconds: json['timestamp_seconds'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'user_id': userId,
      'content': content,
      'timestamp_seconds': timestampSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
