import 'package:equatable/equatable.dart';

/// Q&A Answer Entity - Pure Dart Object
class QAAnswerEntity extends Equatable {
  final String id;
  final String questionId;
  final String userId;
  final String content;
  final bool isInstructor;
  final bool isAccepted;
  final int upvotesCount;
  final bool hasUpvoted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? userAvatar;

  const QAAnswerEntity({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.content,
    this.isInstructor = false,
    this.isAccepted = false,
    this.upvotesCount = 0,
    this.hasUpvoted = false,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  @override
  List<Object?> get props => [
        id,
        questionId,
        userId,
        content,
        isInstructor,
        isAccepted,
        upvotesCount,
        hasUpvoted,
        createdAt,
        updatedAt,
        userName,
        userAvatar,
      ];
}

/// Q&A Question Entity - Pure Dart Object
class QAQuestionEntity extends Equatable {
  final String id;
  final String userId;
  final String courseId;
  final String? lessonId;
  final String title;
  final String content;
  final bool isAnswered;
  final bool isPinned;
  final int viewsCount;
  final int answersCount;
  final int upvotesCount;
  final bool hasUpvoted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? userAvatar;
  final List<QAAnswerEntity>? answers;

  const QAQuestionEntity({
    required this.id,
    required this.userId,
    required this.courseId,
    this.lessonId,
    required this.title,
    required this.content,
    this.isAnswered = false,
    this.isPinned = false,
    this.viewsCount = 0,
    this.answersCount = 0,
    this.upvotesCount = 0,
    this.hasUpvoted = false,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userAvatar,
    this.answers,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        courseId,
        lessonId,
        title,
        content,
        isAnswered,
        isPinned,
        viewsCount,
        answersCount,
        upvotesCount,
        hasUpvoted,
        createdAt,
        updatedAt,
        userName,
        userAvatar,
        answers,
      ];
}
