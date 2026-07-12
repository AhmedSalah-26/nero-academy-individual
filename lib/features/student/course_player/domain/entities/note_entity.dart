import 'package:equatable/equatable.dart';

/// Note Entity - Pure Dart Object
class NoteEntity extends Equatable {
  final String id;
  final String lessonId;
  final String userId;
  final String content;
  final int timestampSeconds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NoteEntity({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.content,
    this.timestampSeconds = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Format timestamp as string (e.g., "5:30")
  String get formattedTimestamp {
    final minutes = timestampSeconds ~/ 60;
    final seconds = timestampSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        lessonId,
        userId,
        content,
        timestampSeconds,
        createdAt,
        updatedAt,
      ];
}
