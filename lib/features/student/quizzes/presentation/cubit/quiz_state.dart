import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';

/// Quiz State
class QuizState extends Equatable {
  final StateStatus status;
  final Failure? failure;
  final QuizEntity? quiz;
  final List<QuizQuestionEntity> questions;
  final List<QuizAttemptEntity> previousAttempts;
  final QuizAttemptEntity? currentAttempt;
  final QuizAttemptEntity? completedAttempt;
  final int currentQuestionIndex;
  final Map<String, List<String>> answers;
  final int remainingAttempts;
  final int elapsedSeconds;
  final bool isSubmitting;
  final bool isTimerRunning;

  const QuizState({
    this.status = StateStatus.initial,
    this.failure,
    this.quiz,
    this.questions = const [],
    this.previousAttempts = const [],
    this.currentAttempt,
    this.completedAttempt,
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.remainingAttempts = -1,
    this.elapsedSeconds = 0,
    this.isSubmitting = false,
    this.isTimerRunning = false,
  });

  // Status helpers
  bool get isLoading => status == StateStatus.loading;
  bool get isError => status == StateStatus.error;
  bool get isSuccess => status == StateStatus.success;
  String? get errorMessage => failure?.message;

  // Quiz helpers
  bool get hasQuiz => quiz != null;
  bool get hasQuestions => questions.isNotEmpty;
  int get totalQuestions => questions.length;

  // Current question helpers
  QuizQuestionEntity? get currentQuestion {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  bool get isFirstQuestion => currentQuestionIndex == 0;
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;

  // Progress helpers
  double get progress {
    if (totalQuestions == 0) return 0;
    return (currentQuestionIndex + 1) / totalQuestions;
  }

  int get answeredCount => answers.length;

  bool isQuestionAnswered(String questionId) {
    return answers.containsKey(questionId) && answers[questionId]!.isNotEmpty;
  }

  List<String> getSelectedOptions(String questionId) {
    return answers[questionId] ?? [];
  }

  // Attempt helpers
  bool get hasAttempts => previousAttempts.isNotEmpty;
  bool get canStartQuiz {
    if (quiz?.isAvailableNow == false) return false;

    // If remainingAttempts is 0 (default/not loaded), allow starting
    // -1 means unlimited, > 0 means has attempts left
    if (remainingAttempts == -1 || remainingAttempts > 0) return true;
    // Only block if we explicitly know there are 0 attempts left
    // and we have loaded the quiz (quiz != null)
    if (quiz != null && remainingAttempts == 0) return false;
    return true; // Default to allowing
  }

  bool get isQuizInProgress => currentAttempt != null && !isSubmitting;
  bool get isQuizCompleted => completedAttempt != null;

  // Timer helpers
  int get remainingSeconds {
    if (quiz?.timeLimit == null) return -1;
    final totalSeconds = quiz!.timeLimit! * 60;
    return totalSeconds - elapsedSeconds;
  }

  bool get isTimeUp => quiz?.hasTimeLimit == true && remainingSeconds <= 0;

  String get formattedRemainingTime {
    if (remainingSeconds < 0) return '';
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedElapsedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  QuizState copyWith({
    StateStatus? status,
    Failure? failure,
    QuizEntity? quiz,
    List<QuizQuestionEntity>? questions,
    List<QuizAttemptEntity>? previousAttempts,
    QuizAttemptEntity? currentAttempt,
    QuizAttemptEntity? completedAttempt,
    int? currentQuestionIndex,
    Map<String, List<String>>? answers,
    int? remainingAttempts,
    int? elapsedSeconds,
    bool? isSubmitting,
    bool? isTimerRunning,
    bool clearFailure = false,
    bool clearCurrentAttempt = false,
    bool clearCompletedAttempt = false,
  }) {
    return QuizState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      previousAttempts: previousAttempts ?? this.previousAttempts,
      currentAttempt:
          clearCurrentAttempt ? null : (currentAttempt ?? this.currentAttempt),
      completedAttempt: clearCompletedAttempt
          ? null
          : (completedAttempt ?? this.completedAttempt),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    );
  }

  @override
  List<Object?> get props => [
        status,
        failure,
        quiz,
        questions,
        previousAttempts,
        currentAttempt,
        completedAttempt,
        currentQuestionIndex,
        answers,
        remainingAttempts,
        elapsedSeconds,
        isSubmitting,
        isTimerRunning,
      ];
}
