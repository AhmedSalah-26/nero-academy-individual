import '../../domain/entities/qa_question_entity.dart';

/// Q&A Answer Model - Data Model with JSON serialization
class QAAnswerModel extends QAAnswerEntity {
  const QAAnswerModel({
    required super.id,
    required super.questionId,
    required super.userId,
    required super.content,
    super.isInstructor,
    super.isAccepted,
    super.upvotesCount,
    super.hasUpvoted,
    required super.createdAt,
    super.updatedAt,
    super.userName,
    super.userAvatar,
  });

  /// Create from JSON
  factory QAAnswerModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data
    String? userName;
    String? userAvatar;
    // The Supabase query aliases profiles as 'user'
    final userRaw = json['user'] ?? json['profiles'];
    if (userRaw is Map<String, dynamic>) {
      userName = (userRaw['full_name'] ?? userRaw['name']) as String?;
      userAvatar = userRaw['avatar_url'] as String?;
    }

    return QAAnswerModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      isInstructor: json['is_instructor_answer'] as bool? ?? false,
      isAccepted: json['is_accepted'] as bool? ?? false,
      upvotesCount: json['upvotes_count'] as int? ?? 0,
      hasUpvoted: json['has_upvoted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userName: userName,
      userAvatar: userAvatar,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'user_id': userId,
      'content': content,
      'is_instructor_answer': isInstructor,
      'is_accepted': isAccepted,
      'upvotes_count': upvotesCount,
      'has_upvoted': hasUpvoted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Q&A Question Model - Data Model with JSON serialization
class QAQuestionModel extends QAQuestionEntity {
  const QAQuestionModel({
    required super.id,
    required super.userId,
    required super.courseId,
    super.lessonId,
    required super.title,
    required super.content,
    super.isAnswered,
    super.isPinned,
    super.viewsCount,
    super.answersCount,
    super.upvotesCount,
    super.hasUpvoted,
    required super.createdAt,
    super.updatedAt,
    super.userName,
    super.userAvatar,
    super.answers,
  });

  /// Create from JSON
  factory QAQuestionModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data
    String? userName;
    String? userAvatar;
    // The Supabase query aliases profiles as 'user'
    final userRaw = json['user'] ?? json['profiles'];
    if (userRaw is Map<String, dynamic>) {
      userName = (userRaw['full_name'] ?? userRaw['name']) as String?;
      userAvatar = userRaw['avatar_url'] as String?;
    }

    // Handle nested answers
    List<QAAnswerEntity>? answers;
    final answersRaw = json['answers'] ?? json['qa_answers'];
    if (answersRaw != null && answersRaw is List) {
      answers = answersRaw
          .map((e) => QAAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return QAQuestionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      lessonId: json['lesson_id'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      isAnswered: json['is_answered'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      viewsCount: json['views_count'] as int? ?? 0,
      answersCount: json['answers_count'] as int? ?? 0,
      upvotesCount: json['upvotes_count'] as int? ?? 0,
      hasUpvoted: json['has_upvoted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userName: userName,
      userAvatar: userAvatar,
      answers: answers,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'lesson_id': lessonId,
      'title': title,
      'content': content,
      'is_answered': isAnswered,
      'is_pinned': isPinned,
      'views_count': viewsCount,
      'answers_count': answersCount,
      'upvotes_count': upvotesCount,
      'has_upvoted': hasUpvoted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
