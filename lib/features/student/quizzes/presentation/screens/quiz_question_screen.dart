import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/animations/widgets/micro/pulse_animation.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';
import 'package:lms_platform/features/student/quizzes/presentation/cubit/quiz_cubit.dart';
import 'package:lms_platform/features/student/quizzes/presentation/cubit/quiz_state.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_question/question_header.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_question/question_card.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_question/question_navigation.dart';
import 'package:lms_platform/features/student/quizzes/presentation/widgets/quiz_question/submit_dialog.dart';

/// Quiz Question Screen - Active quiz taking
class QuizQuestionScreen extends StatefulWidget {
  final String quizId;
  final String enrollmentId;
  final String? courseTitle;
  final String? courseId;
  final String? lessonId;
  final String? teacherId;
  final String? instructorName;
  final String? instructorAvatar;

  const QuizQuestionScreen({
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
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    try {
      final cubit = context.read<QuizCubit>();

      // First load quiz info
      await cubit.loadQuiz(
        quizId: widget.quizId,
        enrollmentId: widget.enrollmentId,
      );

      // Then start the quiz (this loads questions)
      if (mounted && cubit.state.hasQuiz) {
        await cubit.startQuiz(
          quizId: widget.quizId,
          enrollmentId: widget.enrollmentId,
        );
      }
    } catch (e) {
      debugPrint('❌ [QuizQuestionScreen] Error initializing quiz: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Navigate back to quiz info instead of showing dialog
          context.goNamed(
            'quiz-info',
            pathParameters: {'quizId': widget.quizId},
            queryParameters: _buildQuizQueryParameters(),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: _buildAppBar(context, theme, isDark),
        body: BlocConsumer<QuizCubit, QuizState>(
          listener: (context, state) {
            if (state.isQuizCompleted) {
              context.goNamed(
                'quiz-results',
                pathParameters: {'quizId': widget.quizId},
                queryParameters: _buildQuizQueryParameters(),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading || !state.hasQuestions) {
              return const AppLoadingState();
            }

            if (state.isError) {
              return ErrorState(
                type: ErrorType.generic,
                message: state.errorMessage,
                onRetry: _initializeQuiz,
              );
            }

            return _buildContent(context, state, theme, isDark);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showExitConfirmation(context),
      ),
      title: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          return Text(
            state.quiz?.getTitle(context.locale.languageCode) ?? '',
            style: theme.textTheme.titleMedium,
          );
        },
      ),
      centerTitle: true,
      actions: [
        // Timer with PulseAnimation
        BlocBuilder<QuizCubit, QuizState>(
          builder: (context, state) {
            if (state.quiz == null || !state.quiz!.hasTimeLimit) {
              return const SizedBox.shrink();
            }

            final isLowTime = state.remainingSeconds < 60;
            return PulseAnimation(
              animate: isLowTime,
              minScale: 1.0,
              maxScale: 1.1,
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isLowTime
                      ? AppColors.error.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 18,
                      color: isLowTime ? AppColors.error : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.formattedRemainingTime,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: isLowTime ? AppColors.error : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    QuizState state,
    ThemeData theme,
    bool isDark,
  ) {
    final locale = context.locale.languageCode;
    final question = state.currentQuestion!;

    return Column(
      children: [
        // Progress Header
        QuestionHeader(
          currentIndex: state.currentQuestionIndex,
          totalQuestions: state.totalQuestions,
          progress: state.progress,
          isDark: isDark,
        ),

        // Question Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: QuestionCard(
              question: question,
              selectedOptions: state.getSelectedOptions(question.id),
              locale: locale,
              isDark: isDark,
              onOptionSelected: (optionId) {
                context.read<QuizCubit>().selectAnswer(
                      question.id,
                      optionId,
                      isMultiple:
                          question.questionType == QuestionType.multiple,
                    );
              },
            ),
          ),
        ),

        // Navigation
        QuestionNavigation(
          isFirstQuestion: state.isFirstQuestion,
          isLastQuestion: state.isLastQuestion,
          isSubmitting: state.isSubmitting,
          isDark: isDark,
          onPrevious: () => context.read<QuizCubit>().previousQuestion(),
          onNext: () => context.read<QuizCubit>().nextQuestion(),
          onSubmit: () => _showSubmitConfirmation(context, state),
        ),
      ],
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveAlertDialog(
        title: LocaleKeys.quiz_exit_title.tr(),
        content: LocaleKeys.quiz_exit_message.tr(),
        confirmText: LocaleKeys.quiz_exit_confirm.tr(),
        cancelText: 'common.cancel'.tr(),
        isDestructive: true,
        onConfirm: () {
          Navigator.of(ctx).pop();
          // Navigate back to quiz info screen
          context.goNamed(
            'quiz-info',
            pathParameters: {'quizId': widget.quizId},
            queryParameters: _buildQuizQueryParameters(),
          );
        },
      ),
    );
  }

  void _showSubmitConfirmation(BuildContext context, QuizState state) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => SubmitDialog(
        answeredCount: state.answeredCount,
        totalQuestions: state.totalQuestions,
        onSubmit: () {
          Navigator.of(ctx).pop();
          context.read<QuizCubit>().submitQuiz();
        },
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
}
