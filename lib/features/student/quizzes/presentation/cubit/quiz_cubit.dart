import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/usecases/get_quiz_usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/usecases/get_quiz_questions_usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/usecases/get_quiz_attempts_usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/usecases/start_quiz_attempt_usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/usecases/submit_quiz_usecase.dart';
import 'package:lms_platform/features/student/quizzes/data/datasources/quizzes_local_data_source.dart';
import 'quiz_state.dart';

/// Quiz Cubit - Manages quiz state and logic
class QuizCubit extends Cubit<QuizState> {
  final GetQuizUseCase getQuizUseCase;
  final GetQuizQuestionsUseCase getQuizQuestionsUseCase;
  final GetQuizAttemptsUseCase getQuizAttemptsUseCase;
  final GetRemainingAttemptsUseCase getRemainingAttemptsUseCase;
  final StartQuizAttemptUseCase startQuizAttemptUseCase;
  final SubmitQuizUseCase submitQuizUseCase;
  final QuizzesLocalDataSource localDataSource;

  Timer? _timer;

  QuizCubit({
    required this.getQuizUseCase,
    required this.getQuizQuestionsUseCase,
    required this.getQuizAttemptsUseCase,
    required this.getRemainingAttemptsUseCase,
    required this.startQuizAttemptUseCase,
    required this.submitQuizUseCase,
    required this.localDataSource,
  }) : super(const QuizState());

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  /// Load quiz info and previous attempts
  Future<void> loadQuiz({
    required String quizId,
    required String enrollmentId,
  }) async {
    AppLogger.i('📝 [Quiz] Loading quiz: $quizId');
    emit(state.copyWith(status: StateStatus.loading));

    // Load quiz details
    final quizResult = await getQuizUseCase(GetQuizParams(quizId: quizId));

    await quizResult.fold(
      (failure) async {
        AppLogger.e('[Quiz] Failed to load quiz: ${failure.message}');
        emit(state.copyWith(status: StateStatus.error, failure: failure));
      },
      (quiz) async {
        // Load previous attempts
        final attemptsResult = await getQuizAttemptsUseCase(
          GetQuizAttemptsParams(quizId: quizId, enrollmentId: enrollmentId),
        );

        final attempts = attemptsResult.fold(
          (_) => <dynamic>[],
          (attempts) => attempts,
        );

        // Load remaining attempts
        final remainingResult = await getRemainingAttemptsUseCase(
          GetRemainingAttemptsParams(
            quizId: quizId,
            enrollmentId: enrollmentId,
          ),
        );

        final remaining = remainingResult.fold((_) => -1, (r) => r);

        AppLogger.success('[Quiz] Quiz loaded successfully');
        emit(state.copyWith(
          status: StateStatus.success,
          quiz: quiz,
          previousAttempts: List.from(attempts),
          remainingAttempts: remaining,
        ));
      },
    );
  }

  /// Start a new quiz attempt
  Future<bool> startQuiz({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      AppLogger.i('📝 [Quiz] startQuiz called');
      AppLogger.i('📝 [Quiz] canStartQuiz: ${state.canStartQuiz}');
      AppLogger.i('📝 [Quiz] remainingAttempts: ${state.remainingAttempts}');
      AppLogger.i('📝 [Quiz] hasQuiz: ${state.hasQuiz}');

      if (!state.canStartQuiz) {
        AppLogger.w('[Quiz] No remaining attempts');
        return false;
      }

      AppLogger.i('📝 [Quiz] Starting quiz attempt');
      emit(state.copyWith(status: StateStatus.loading));

      // Start attempt
      final attemptResult = await startQuizAttemptUseCase(
        StartQuizAttemptParams(quizId: quizId, enrollmentId: enrollmentId),
      );

      return await attemptResult.fold(
        (failure) async {
          AppLogger.e('[Quiz] Failed to start quiz: ${failure.message}');
          emit(state.copyWith(status: StateStatus.error, failure: failure));
          return false;
        },
        (attempt) async {
          AppLogger.i('📝 [Quiz] Attempt created: ${attempt.id}');
          // Load questions
          final questionsResult = await getQuizQuestionsUseCase(
            GetQuizQuestionsParams(
              quizId: quizId,
              shuffle: state.quiz?.shuffleQuestions ?? false,
            ),
          );

          return questionsResult.fold(
            (failure) {
              AppLogger.e(
                  '[Quiz] Failed to load questions: ${failure.message}');
              emit(state.copyWith(status: StateStatus.error, failure: failure));
              return false;
            },
            (questions) {
              AppLogger.success(
                  '[Quiz] Quiz started with ${questions.length} questions');
              emit(state.copyWith(
                status: StateStatus.success,
                currentAttempt: attempt,
                questions: questions,
                currentQuestionIndex: 0,
                answers: {},
                elapsedSeconds: 0,
                isTimerRunning: true,
              ));
              _startTimer();
              return true;
            },
          );
        },
      );
    } catch (e, stackTrace) {
      AppLogger.e('[Quiz] Exception in startQuiz: $e');
      AppLogger.e('[Quiz] StackTrace: $stackTrace');
      return false;
    }
  }

  /// Start the timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isTimerRunning) return;

      final newElapsed = state.elapsedSeconds + 1;
      emit(state.copyWith(elapsedSeconds: newElapsed));

      // Auto-submit if time is up
      if (state.isTimeUp && state.currentAttempt != null) {
        submitQuiz();
      }
    });
  }

  /// Pause timer
  void pauseTimer() {
    emit(state.copyWith(isTimerRunning: false));
  }

  /// Resume timer
  void resumeTimer() {
    emit(state.copyWith(isTimerRunning: true));
  }

  /// Go to next question
  void nextQuestion() {
    if (state.isLastQuestion) return;
    emit(state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1));
  }

  /// Go to previous question
  void previousQuestion() {
    if (state.isFirstQuestion) return;
    emit(state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1));
  }

  /// Go to specific question
  void goToQuestion(int index) {
    if (index < 0 || index >= state.totalQuestions) return;
    emit(state.copyWith(currentQuestionIndex: index));
  }

  /// Select answer for current question
  void selectAnswer(String questionId, String optionId,
      {bool isMultiple = false}) {
    final currentAnswers = Map<String, List<String>>.from(state.answers);

    if (isMultiple) {
      final selected = List<String>.from(currentAnswers[questionId] ?? []);
      if (selected.contains(optionId)) {
        selected.remove(optionId);
      } else {
        selected.add(optionId);
      }
      currentAnswers[questionId] = selected;
    } else {
      currentAnswers[questionId] = [optionId];
    }

    emit(state.copyWith(answers: currentAnswers));

    // Cache answers locally
    if (state.currentAttempt != null) {
      localDataSource.cacheQuizAnswers(
        attemptId: state.currentAttempt!.id,
        answers: currentAnswers,
      );
    }
  }

  /// Clear answer for a question
  void clearAnswer(String questionId) {
    final currentAnswers = Map<String, List<String>>.from(state.answers);
    currentAnswers.remove(questionId);
    emit(state.copyWith(answers: currentAnswers));
  }

  /// Submit quiz
  Future<bool> submitQuiz() async {
    if (state.currentAttempt == null || state.isSubmitting) return false;

    AppLogger.i('📝 [Quiz] Submitting quiz');
    _timer?.cancel();
    emit(state.copyWith(isSubmitting: true, isTimerRunning: false));

    final result = await submitQuizUseCase(
      SubmitQuizParams(
        attemptId: state.currentAttempt!.id,
        answers: state.answers,
        timeSpentSeconds: state.elapsedSeconds,
      ),
    );

    return result.fold(
      (failure) {
        AppLogger.e('[Quiz] Failed to submit quiz: ${failure.message}');
        emit(state.copyWith(
          isSubmitting: false,
          status: StateStatus.error,
          failure: failure,
        ));
        return false;
      },
      (completedAttempt) {
        AppLogger.success(
            '[Quiz] Quiz submitted - Score: ${completedAttempt.percentage}%');
        emit(state.copyWith(
          isSubmitting: false,
          completedAttempt: completedAttempt,
          clearCurrentAttempt: true,
        ));
        return true;
      },
    );
  }

  /// Reset quiz state for retry
  void resetForRetry() {
    emit(state.copyWith(
      clearCurrentAttempt: true,
      clearCompletedAttempt: true,
      questions: [],
      answers: {},
      currentQuestionIndex: 0,
      elapsedSeconds: 0,
      isTimerRunning: false,
    ));
  }

  /// Load results for a completed quiz (used when navigating to results screen)
  Future<void> loadResults({
    required String quizId,
    required String enrollmentId,
    String? attemptId,
  }) async {
    AppLogger.i(
        '📝 [Quiz] Loading results for quiz: $quizId, attemptId: $attemptId');
    emit(state.copyWith(status: StateStatus.loading));

    // Load quiz details
    final quizResult = await getQuizUseCase(GetQuizParams(quizId: quizId));

    await quizResult.fold(
      (failure) async {
        AppLogger.e('[Quiz] Failed to load quiz: ${failure.message}');
        emit(state.copyWith(status: StateStatus.error, failure: failure));
      },
      (quiz) async {
        // Load previous attempts
        final attemptsResult = await getQuizAttemptsUseCase(
          GetQuizAttemptsParams(quizId: quizId, enrollmentId: enrollmentId),
        );

        await attemptsResult.fold(
          (failure) async {
            AppLogger.e('[Quiz] Failed to load attempts: ${failure.message}');
            emit(state.copyWith(status: StateStatus.error, failure: failure));
          },
          (attempts) async {
            // Find the specific attempt or get the latest completed one
            QuizAttemptEntity? targetAttempt;

            if (attemptId != null) {
              targetAttempt =
                  attempts.where((a) => a.id == attemptId).firstOrNull;
            }

            if (targetAttempt == null) {
              final completedAttempts =
                  attempts.where((a) => a.completedAt != null).toList();
              if (completedAttempts.isNotEmpty) {
                completedAttempts.sort((a, b) => (b.completedAt ?? DateTime(0))
                    .compareTo(a.completedAt ?? DateTime(0)));
                targetAttempt = completedAttempts.first;
              }
            }

            if (targetAttempt == null) {
              AppLogger.w('[Quiz] No completed attempts found');
              emit(state.copyWith(
                status: StateStatus.success,
                quiz: quiz,
                previousAttempts: List.from(attempts),
              ));
              return;
            }

            // Load questions for review
            final questionsResult = await getQuizQuestionsUseCase(
              GetQuizQuestionsParams(quizId: quizId, shuffle: false),
            );

            final questions = questionsResult.fold(
              (_) => <dynamic>[],
              (q) => q,
            );

            AppLogger.success(
                '[Quiz] Results loaded - Score: ${targetAttempt.percentage}%');
            emit(state.copyWith(
              status: StateStatus.success,
              quiz: quiz,
              questions: List.from(questions),
              previousAttempts: List.from(attempts),
              completedAttempt: targetAttempt,
            ));
          },
        );
      },
    );
  }
}
