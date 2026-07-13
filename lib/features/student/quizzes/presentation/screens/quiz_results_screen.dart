import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/animations/widgets/feedback/completion_animation.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';
import 'package:lms_platform/features/student/quizzes/presentation/cubit/quiz_cubit.dart';
import 'package:lms_platform/features/student/quizzes/presentation/cubit/quiz_state.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_results/score_circle.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_results/results_stats.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_results/answers_review_list.dart';

/// Quiz Results Screen - Shows quiz completion results
class QuizResultsScreen extends StatelessWidget {
  final String quizId;
  final String enrollmentId;
  final String? courseTitle;
  final String? courseId;
  final String? lessonId;
  final String? teacherId;
  final String? instructorName;
  final String? instructorAvatar;

  const QuizResultsScreen({
    super.key,
    required this.quizId,
    required this.enrollmentId,
    this.courseTitle,
    this.courseId,
    this.lessonId,
    this.teacherId,
    this.instructorName,
    this.instructorAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: _buildAppBar(context, theme),
      body: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          if (state.completedAttempt == null) {
            return const AppLoadingState();
          }

          return _buildContent(context, state, theme, isDark);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _goBack(context),
      ),
      title: Text(
        LocaleKeys.quiz_results.tr(),
        style: theme.textTheme.titleMedium,
      ),
      centerTitle: true,
    );
  }

  void _goBack(BuildContext context) {
    final targetCourseId = courseId;
    if (targetCourseId != null && targetCourseId.trim().isNotEmpty) {
      context.goNamed(
        'course-player',
        pathParameters: {'courseId': targetCourseId},
        queryParameters: _buildCoursePlayerQueryParameters(),
      );
      return;
    }

    context.goNamed(
      'quiz-info',
      pathParameters: {'quizId': quizId},
      queryParameters: _buildQuizQueryParameters(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    QuizState state,
    ThemeData theme,
    bool isDark,
  ) {
    final attempt = state.completedAttempt!;
    final locale = context.locale.languageCode;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Completion Animation
                CompletionAnimation(
                  type: attempt.passed
                      ? CompletionType.trophy
                      : CompletionType.checkmark,
                  size: 120,
                  color: attempt.passed ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Score Circle
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ScoreCircle(
                        percentage: attempt.percentage,
                        passed: attempt.passed,
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        attempt.passed
                            ? LocaleKeys.quiz_passed.tr()
                            : LocaleKeys.quiz_failed.tr(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: attempt.passed
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        attempt.passed
                            ? LocaleKeys.quiz_passed_message.tr()
                            : LocaleKeys.quiz_failed_message.tr(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Stats Row
                      ResultsStats(
                        score: attempt.score,
                        totalPoints: attempt.totalPoints,
                        timeSpent: attempt.formattedTimeSpent,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Answers Review
                if (state.quiz?.showCorrectAnswers == true &&
                    state.questions.isNotEmpty) ...[
                  _buildReviewHeader(context, theme, isDark),
                  const SizedBox(height: AppSpacing.md),
                  AnswersReviewList(
                    questions: state.questions,
                    answers: attempt.answers,
                    locale: locale,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Actions
        _buildBottomBar(context, state, theme, isDark),
      ],
    );
  }

  Widget _buildReviewHeader(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        LocaleKeys.quiz_review_answers.tr(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    QuizState state,
    ThemeData theme,
    bool isDark,
  ) {
    final canRetry = state.canStartQuiz && !state.completedAttempt!.passed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (canRetry) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _retryQuiz(context),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(LocaleKeys.quiz_retry.tr()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () => _goBack(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(LocaleKeys.quiz_back_to_course.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retryQuiz(BuildContext context) {
    context.read<QuizCubit>().resetForRetry();
    context.goNamed(
      'quiz-info',
      pathParameters: {'quizId': quizId},
      queryParameters: _buildQuizQueryParameters(),
    );
  }

  Map<String, String> _buildQuizQueryParameters({String? attemptId}) {
    final params = <String, String>{'enrollment': enrollmentId};
    if (courseTitle != null && courseTitle!.trim().isNotEmpty) {
      params['title'] = courseTitle!;
    }
    if (courseId != null && courseId!.trim().isNotEmpty) {
      params['courseId'] = courseId!;
    }
    if (lessonId != null && lessonId!.trim().isNotEmpty) {
      params['lesson'] = lessonId!;
    }
    if (teacherId != null && teacherId!.trim().isNotEmpty) {
      params['teacherId'] = teacherId!;
    }
    if (instructorName != null && instructorName!.trim().isNotEmpty) {
      params['instructor'] = instructorName!;
    }
    if (instructorAvatar != null && instructorAvatar!.trim().isNotEmpty) {
      params['avatar'] = instructorAvatar!;
    }
    if (attemptId != null && attemptId.trim().isNotEmpty) {
      params['attemptId'] = attemptId;
    }
    return params;
  }

  Map<String, String> _buildCoursePlayerQueryParameters() {
    final params = <String, String>{'enrollment': enrollmentId};
    if (courseTitle != null && courseTitle!.trim().isNotEmpty) {
      params['title'] = courseTitle!;
    }
    if (lessonId != null && lessonId!.trim().isNotEmpty) {
      params['lesson'] = lessonId!;
    }
    if (teacherId != null && teacherId!.trim().isNotEmpty) {
      params['teacherId'] = teacherId!;
    }
    if (instructorName != null && instructorName!.trim().isNotEmpty) {
      params['instructor'] = instructorName!;
    }
    if (instructorAvatar != null && instructorAvatar!.trim().isNotEmpty) {
      params['avatar'] = instructorAvatar!;
    }
    return params;
  }
}
