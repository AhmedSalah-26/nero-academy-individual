part of 'instructor_quizzes_cubit.dart';

/// Instructor Quizzes Status
enum InstructorQuizzesStatus { initial, loading, success, error }

/// Instructor Quizzes State
class InstructorQuizzesState extends Equatable {
  final InstructorQuizzesStatus status;
  final List<InstructorQuizModel> quizzes;
  final String? selectedCourseId;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const InstructorQuizzesState({
    this.status = InstructorQuizzesStatus.initial,
    this.quizzes = const [],
    this.selectedCourseId,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorQuizzesStatus.loading;

  InstructorQuizzesState copyWith({
    InstructorQuizzesStatus? status,
    List<InstructorQuizModel>? quizzes,
    String? selectedCourseId,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorQuizzesState(
      status: status ?? this.status,
      quizzes: quizzes ?? this.quizzes,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, quizzes, selectedCourseId, isLoadingMore, hasMore, errorMessage];
}

/// Instructor Quiz Model
class InstructorQuizModel extends Equatable {
  final String id;
  final String courseId;
  final String? lessonId;
  final String? courseTitleAr;
  final String? courseTitleEn;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final int passingScore;
  final int? timeLimitMinutes;
  final int? maxAttempts;
  final bool shuffleQuestions;
  final bool shuffleAnswers;
  final bool showCorrectAnswers;
  final int questionsCount;
  final int totalPoints;
  final int attemptsCount;
  final double averageScore;
  final bool isPublished;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime createdAt;

  const InstructorQuizModel({
    required this.id,
    required this.courseId,
    this.lessonId,
    this.courseTitleAr,
    this.courseTitleEn,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.passingScore,
    this.timeLimitMinutes,
    this.maxAttempts,
    this.shuffleQuestions = false,
    this.shuffleAnswers = false,
    this.showCorrectAnswers = true,
    this.questionsCount = 0,
    this.totalPoints = 0,
    this.attemptsCount = 0,
    this.averageScore = 0,
    this.isPublished = true,
    this.availableFrom,
    this.availableUntil,
    required this.createdAt,
  });

  factory InstructorQuizModel.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>?;

    return InstructorQuizModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      lessonId: json['lesson_id'] as String?,
      courseTitleAr: course?['title_ar'] as String?,
      courseTitleEn: course?['title_en'] as String?,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      passingScore: json['passing_score'] as int? ?? 70,
      timeLimitMinutes: json['time_limit'] as int?,
      maxAttempts: json['max_attempts'] as int?,
      shuffleQuestions: json['shuffle_questions'] as bool? ?? false,
      shuffleAnswers: json['shuffle_answers'] as bool? ?? false,
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? true,
      questionsCount: json['total_questions'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      attemptsCount: json['attempts_count'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : null,
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        lessonId,
        titleAr,
        titleEn,
        passingScore,
        timeLimitMinutes,
        questionsCount,
        attemptsCount,
        averageScore,
        availableFrom,
        availableUntil,
        createdAt,
      ];
}

/// Quiz Question Model
class QuizQuestionModel extends Equatable {
  final String id;
  final String quizId;
  final String questionAr;
  final String questionEn;
  final String? imageUrl; // Optional image for the question
  final String type; // single, multiple, true_false, text
  final int points;
  final int order;
  final List<QuizOptionModel> options;
  final String? correctAnswer; // for text questions

  const QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.questionAr,
    required this.questionEn,
    this.imageUrl,
    required this.type,
    this.points = 1,
    required this.order,
    this.options = const [],
    this.correctAnswer,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    // Parse options from JSONB
    final optionsJson = json['options'] as List? ?? [];
    final options = optionsJson.map((o) {
      final optionMap = o as Map<String, dynamic>;
      return QuizOptionModel(
        id: optionMap['id'] as String? ?? '',
        questionId: json['id'] as String,
        textAr: optionMap['text_ar'] as String? ?? '',
        textEn: optionMap['text_en'] as String? ?? '',
        isCorrect: optionMap['is_correct'] as bool? ?? false,
        order: optionMap['sort_order'] as int? ?? 0,
      );
    }).toList();

    return QuizQuestionModel(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      questionAr: json['question_ar'] as String? ?? '',
      questionEn: json['question_en'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      type: json['question_type'] as String? ?? 'single',
      points: json['points'] as int? ?? 1,
      order: json['sort_order'] as int? ?? 0,
      options: options,
      correctAnswer: json['correct_answer'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        quizId,
        questionAr,
        questionEn,
        imageUrl,
        type,
        points,
        order,
        options,
        correctAnswer
      ];
}

/// Quiz Option Model
class QuizOptionModel extends Equatable {
  final String id;
  final String questionId;
  final String textAr;
  final String textEn;
  final bool isCorrect;
  final int order;

  const QuizOptionModel({
    required this.id,
    required this.questionId,
    required this.textAr,
    required this.textEn,
    required this.isCorrect,
    required this.order,
  });

  factory QuizOptionModel.fromJson(Map<String, dynamic> json) {
    return QuizOptionModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      textAr: json['text_ar'] as String? ?? '',
      textEn: json['text_en'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
      order: json['sort_order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, questionId, textAr, textEn, isCorrect, order];
}
