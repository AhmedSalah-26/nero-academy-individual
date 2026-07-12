import 'package:equatable/equatable.dart';

/// Bookmark Entity - Pure Dart Object
class BookmarkEntity extends Equatable {
  final String id;
  final String lessonId;
  final String enrollmentId;
  final String? note;
  final DateTime createdAt;
  final String? lessonTitle;

  const BookmarkEntity({
    required this.id,
    required this.lessonId,
    required this.enrollmentId,
    this.note,
    required this.createdAt,
    this.lessonTitle,
  });

  @override
  List<Object?> get props => [
        id,
        lessonId,
        enrollmentId,
        note,
        createdAt,
        lessonTitle,
      ];
}
