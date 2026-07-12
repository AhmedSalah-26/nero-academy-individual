/// Instructor Answer Model (Q&A)
class InstructorAnswerModel {
  final String id;
  final String questionId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final bool isInstructor;
  final bool isAccepted;
  final int upvotesCount;
  final DateTime createdAt;

  const InstructorAnswerModel({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.isInstructor,
    required this.isAccepted,
    required this.upvotesCount,
    required this.createdAt,
  });

  factory InstructorAnswerModel.fromJson(Map<String, dynamic> json) {
    return InstructorAnswerModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user']?['name'] as String? ?? 'Unknown',
      userAvatar: json['user']?['avatar_url'] as String?,
      content: json['content'] as String? ?? '',
      isInstructor: json['is_instructor_answer'] as bool? ?? false,
      isAccepted: json['is_accepted'] as bool? ?? false,
      upvotesCount: json['upvotes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Instructor Question Model (Q&A)
class InstructorQuestionModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String? lessonId;
  final String? lessonTitle;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String title;
  final String content;
  final bool isAnswered;
  final bool isPinned;
  final int viewsCount;
  final int answersCount;
  final DateTime createdAt;
  final List<InstructorAnswerModel>? answers;

  const InstructorQuestionModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.lessonId,
    this.lessonTitle,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.title,
    required this.content,
    required this.isAnswered,
    required this.isPinned,
    required this.viewsCount,
    required this.answersCount,
    required this.createdAt,
    this.answers,
  });

  factory InstructorQuestionModel.fromJson(Map<String, dynamic> json) {
    // Handle nested answers
    List<InstructorAnswerModel>? answers;
    if (json['qa_answers'] != null) {
      answers = (json['qa_answers'] as List)
          .map((e) => InstructorAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return InstructorQuestionModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      courseTitle: json['course']?['title_ar'] as String? ?? '',
      lessonId: json['lesson_id'] as String?,
      lessonTitle: json['lesson']?['title_ar'] as String?,
      userId: json['user_id'] as String,
      userName: json['user']?['name'] as String? ?? 'Unknown',
      userAvatar: json['user']?['avatar_url'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isAnswered: json['is_answered'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      viewsCount: json['views_count'] as int? ?? 0,
      answersCount: json['answers_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      answers: answers,
    );
  }
}
