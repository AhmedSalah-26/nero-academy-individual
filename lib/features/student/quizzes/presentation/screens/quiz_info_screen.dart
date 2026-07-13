import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';
import 'package:lms_platform/features/student/quizzes/presentation/cubit/quiz_cubit.dart';
import 'package:lms_platform/features/student/quizzes/presentation/cubit/quiz_state.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_info/quiz_info_card.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_info/quiz_meta_grid.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_info/previous_attempts_list.dart';

/// Quiz Info Screen - Shows quiz details and previous attempts
class QuizInfoScreen extends StatefulWidget {
  final String quizId;
  final String enrollmentId;
  final String? courseTitle;
  final String? courseId;
  final String? lessonId;
  final String? teacherId;
  final String? instructorName;
  final String? instructorAvatar;

  const QuizInfoScreen({
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
  State<QuizInfoScreen> createState() => _QuizInfoScreenState();
}

class _QuizInfoScreenState extends State<QuizInfoScreen> {
  @override
  void initState() {
    super.initState();
    // Quiz is loaded in router, no need to load again
  }

  void _loadQuiz() {
    context.read<QuizCubit>().loadQuiz(
          quizId: widget.quizId,
          enrollmentId: widget.enrollmentId,
        );
  }

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
          if (state.isLoading) {
            return const AppLoadingState();
          }

          if (state.isError) {
            return _buildErrorState(context, state);
          }

          if (!state.hasQuiz) {
            return _buildEmptyState(context);
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
      surfaceTintColor: Colors.transparent,
      leading:
          AppBackButton(onPressed: () => _goBackToCourseOrDefault(context)),
      title: Text(
        widget.courseTitle ?? LocaleKeys.quiz_title.tr(),
        style: theme.textTheme.titleMedium,
      ),
      centerTitle: true,
    );
  }

  Widget _buildErrorState(BuildContext context, QuizState state) {
    return ErrorState(
      type: ErrorType.generic,
      display: ErrorStateDisplay.section,
      message: state.errorMessage ?? LocaleKeys.common_error.tr(),
      onRetry: _loadQuiz,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      type: EmptyStateType.quizzes,
      message: LocaleKeys.quiz_not_found.tr(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    QuizState state,
    ThemeData theme,
    bool isDark,
  ) {
    final locale = context.locale.languageCode;
    int sectionIndex = 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quiz Info Card
                SlideFadeIn.fromBottom(
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                  child: QuizInfoCard(
                    quiz: state.quiz!,
                    locale: locale,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Meta Grid (Time, Questions, Pass Score, Attempts)
                SlideFadeIn.fromBottom(
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                  child: QuizMetaGrid(
                    quiz: state.quiz!,
                    remainingAttempts: state.remainingAttempts,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Previous Attempts
                if (state.hasAttempts) ...[
                  SlideFadeIn.fromBottom(
                    delay: Duration(milliseconds: 100 * sectionIndex++),
                    child: PreviousAttemptsList(
                      attempts: state.previousAttempts,
                      passingScore: state.quiz!.passingScore,
                      isDark: isDark,
                      onAttemptTap: (attempt) => _viewAttemptResults(attempt),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Action Bar
        SlideFadeIn.fromBottom(
          delay: const Duration(milliseconds: 400),
          child: _buildBottomBar(context, state, theme, isDark),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    QuizState state,
    ThemeData theme,
    bool isDark,
  ) {
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
        child: SizedBox(
          width: double.infinity,
          child: AnimatedButton(
            onPressed: state.canStartQuiz ? () => _startQuiz(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    state.canStartQuiz ? AppColors.primary : AppColors.grey400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _startButtonText(state),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _startButtonText(QuizState state) {
    if (state.canStartQuiz) return LocaleKeys.quiz_start.tr();
    final quiz = state.quiz;
    if (quiz?.isScheduled == true) {
      final startsAt = DateFormat.yMMMd(context.locale.languageCode)
          .add_jm()
          .format(quiz!.availableFrom!.toLocal());
      return context.locale.languageCode == 'ar'
          ? 'يبدأ في $startsAt'
          : 'Starts $startsAt';
    }
    if (quiz?.isExpired == true) {
      return context.locale.languageCode == 'ar'
          ? 'انتهى وقت الاختبار'
          : 'Quiz closed';
    }
    return LocaleKeys.quiz_no_attempts.tr();
  }

  Future<void> _startQuiz(BuildContext context) async {
    // Just navigate to questions screen, it will handle starting the quiz
    if (context.mounted) {
      context.goNamed(
        'quiz-questions',
        pathParameters: {'quizId': widget.quizId},
        queryParameters: _buildQuizQueryParameters(),
      );
    }
  }

  void _viewAttemptResults(attempt) {
    context.pushNamed(
      'quiz-results',
      pathParameters: {'quizId': widget.quizId},
      queryParameters: _buildQuizQueryParameters(
        attemptId: attempt.id.toString(),
      ),
    );
  }

  Map<String, String> _buildQuizQueryParameters({String? attemptId}) {
    final params = <String, String>{'enrollment': widget.enrollmentId};
    if (widget.courseTitle != null && widget.courseTitle!.trim().isNotEmpty) {
      params['title'] = widget.courseTitle!;
    }
    if (widget.courseId != null && widget.courseId!.trim().isNotEmpty) {
      params['courseId'] = widget.courseId!;
    }
    if (widget.lessonId != null && widget.lessonId!.trim().isNotEmpty) {
      params['lesson'] = widget.lessonId!;
    }
    if (widget.teacherId != null && widget.teacherId!.trim().isNotEmpty) {
      params['teacherId'] = widget.teacherId!;
    }
    if (widget.instructorName != null &&
        widget.instructorName!.trim().isNotEmpty) {
      params['instructor'] = widget.instructorName!;
    }
    if (widget.instructorAvatar != null &&
        widget.instructorAvatar!.trim().isNotEmpty) {
      params['avatar'] = widget.instructorAvatar!;
    }
    if (attemptId != null && attemptId.trim().isNotEmpty) {
      params['attemptId'] = attemptId;
    }
    return params;
  }

  void _goBackToCourseOrDefault(BuildContext context) {
    final targetCourseId = widget.courseId;
    if (targetCourseId != null && targetCourseId.trim().isNotEmpty) {
      context.goNamed(
        'course-player',
        pathParameters: {'courseId': targetCourseId},
        queryParameters: _buildCoursePlayerQueryParameters(),
      );
      return;
    }

    context.go('/my-learning');
  }

  Map<String, String> _buildCoursePlayerQueryParameters() {
    final params = <String, String>{'enrollment': widget.enrollmentId};
    if (widget.courseTitle != null && widget.courseTitle!.trim().isNotEmpty) {
      params['title'] = widget.courseTitle!;
    }
    if (widget.lessonId != null && widget.lessonId!.trim().isNotEmpty) {
      params['lesson'] = widget.lessonId!;
    }
    if (widget.teacherId != null && widget.teacherId!.trim().isNotEmpty) {
      params['teacherId'] = widget.teacherId!;
    }
    if (widget.instructorName != null &&
        widget.instructorName!.trim().isNotEmpty) {
      params['instructor'] = widget.instructorName!;
    }
    if (widget.instructorAvatar != null &&
        widget.instructorAvatar!.trim().isNotEmpty) {
      params['avatar'] = widget.instructorAvatar!;
    }
    return params;
  }
}
