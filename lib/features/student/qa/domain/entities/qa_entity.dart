/// Question Entity
class QuestionEntity {
  final String id;
  final String courseId;
  final String? lessonId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String title;
  final String content;
  final int upvotes;
  final int answersCount;
  final bool hasInstructorAnswer;
  final DateTime createdAt;
  final bool isUpvotedByUser;

  const QuestionEntity({
    required this.id,
    required this.courseId,
    this.lessonId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.title,
    required this.content,
    this.upvotes = 0,
    this.answersCount = 0,
    this.hasInstructorAnswer = false,
    required this.createdAt,
    this.isUpvotedByUser = false,
  });

  QuestionEntity copyWith({
    String? id,
    String? courseId,
    String? lessonId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? title,
    String? content,
    int? upvotes,
    int? answersCount,
    bool? hasInstructorAnswer,
    DateTime? createdAt,
    bool? isUpvotedByUser,
  }) {
    return QuestionEntity(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      upvotes: upvotes ?? this.upvotes,
      answersCount: answersCount ?? this.answersCount,
      hasInstructorAnswer: hasInstructorAnswer ?? this.hasInstructorAnswer,
      createdAt: createdAt ?? this.createdAt,
      isUpvotedByUser: isUpvotedByUser ?? this.isUpvotedByUser,
    );
  }
}

/// Answer Entity
class AnswerEntity {
  final String id;
  final String questionId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final int upvotes;
  final bool isInstructor;
  final bool isAccepted;
  final DateTime createdAt;
  final bool isUpvotedByUser;

  const AnswerEntity({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.upvotes = 0,
    this.isInstructor = false,
    this.isAccepted = false,
    required this.createdAt,
    this.isUpvotedByUser = false,
  });

  AnswerEntity copyWith({
    String? id,
    String? questionId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    int? upvotes,
    bool? isInstructor,
    bool? isAccepted,
    DateTime? createdAt,
    bool? isUpvotedByUser,
  }) {
    return AnswerEntity(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      upvotes: upvotes ?? this.upvotes,
      isInstructor: isInstructor ?? this.isInstructor,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
      isUpvotedByUser: isUpvotedByUser ?? this.isUpvotedByUser,
    );
  }
}
