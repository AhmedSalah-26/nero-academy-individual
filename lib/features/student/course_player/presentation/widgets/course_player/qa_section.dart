import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/qa_question_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Q&A Section Widget
class QASection extends StatefulWidget {
  final bool isDark;
  final String courseId;
  final String enrollmentId;
  final String? lessonId;
  final CoursePlayerRepository repository;

  const QASection({
    super.key,
    required this.isDark,
    required this.courseId,
    required this.enrollmentId,
    this.lessonId,
    required this.repository,
  });

  @override
  State<QASection> createState() => _QASectionState();
}

class _QASectionState extends State<QASection> {
  late Future<List<QAQuestionEntity>> _questionsFuture;
  final Set<String> _upvotedAnswers = {};
  final Set<String> _upvotedQuestions = {};
  final Set<String> _expandedQuestions = {};
  final Map<String, int> _questionUpvoteAdjustments = {};
  final Map<String, int> _answerUpvoteAdjustments = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    _questionsFuture = _fetchQuestions();
  }

  Future<List<QAQuestionEntity>> _fetchQuestions() async {
    AppLogger.i('❓ [QASection] Loading questions...');
    final result = await widget.repository.getQuestions(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
    );
    return result.fold(
      (failure) {
        AppLogger.e('[QASection] Failed: ${failure.message}');
        return [];
      },
      (questions) {
        AppLogger.success('[QASection] Loaded ${questions.length} questions');
        return questions;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QAQuestionEntity>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: AppLoadingState.section(),
          );
        }

        final questions = snapshot.data ?? [];

        if (questions.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAskButton(),
              const SizedBox(height: 32),
              _buildEmptyState(),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAskButton(),
            ...questions.map((q) => _buildQuestionItem(q)),
          ],
        );
      },
    );
  }

  Widget _buildAskButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _showAskQuestionDialog,
        icon: const Icon(Icons.add),
        label: Text('course_player.ask_question'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        type: EmptyStateType.qa,
      ),
    );
  }

  Widget _buildQuestionItem(QAQuestionEntity question) {
    final isExpanded = _expandedQuestions.contains(question.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(question),
          const SizedBox(height: 8),
          Text(
            question.title,
            style: TextStyle(
              color: widget.isDark ? AppColors.white : AppColors.textMainLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question.content,
            style: TextStyle(
              color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
              fontSize: 12,
            ),
            maxLines: isExpanded ? null : 2,
            overflow: isExpanded ? null : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          _buildQuestionStats(question),

          // Show answers when expanded
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Divider(
              color:
                  widget.isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 12),
            if (question.answers != null && question.answers!.isNotEmpty) ...[
              Text(
                'course_player.answers'.tr(),
                style: TextStyle(
                  color:
                      widget.isDark ? AppColors.white : AppColors.textMainLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...question.answers!.map((answer) => _buildAnswerItem(answer)),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'course_player.no_answers_yet'.tr(),
                    style: TextStyle(
                      color:
                          widget.isDark ? AppColors.grey400 : AppColors.grey600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(QAQuestionEntity question) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage:
              question.userAvatar != null && question.userAvatar!.isNotEmpty
                  ? NetworkImage(question.userAvatar!)
                  : null,
          child: question.userAvatar == null || question.userAvatar!.isEmpty
              ? Text(
                  (question.userName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.userName ?? 'مستخدم',
                style: TextStyle(
                  color:
                      widget.isDark ? AppColors.white : AppColors.textMainLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDate(question.createdAt),
                style: TextStyle(
                  color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (question.isAnswered)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'course_player.answered'.tr(),
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionStats(QAQuestionEntity question) {
    final isExpanded = _expandedQuestions.contains(question.id);
    final isUpvoted =
        question.hasUpvoted || _upvotedQuestions.contains(question.id);

    return Row(
      children: [
        GestureDetector(
          onTap: () => _toggleQuestionUpvote(question.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUpvoted
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.grey100.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: isUpvoted
                  ? Border.all(color: AppColors.primary, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 14,
                  color: isUpvoted
                      ? AppColors.primary
                      : (widget.isDark ? AppColors.grey400 : AppColors.grey600),
                ),
                const SizedBox(width: 4),
                Text(
                  '${question.upvotesCount + (_questionUpvoteAdjustments[question.id] ?? 0)}',
                  style: TextStyle(
                    color: isUpvoted
                        ? AppColors.primary
                        : (widget.isDark
                            ? AppColors.grey400
                            : AppColors.grey600),
                    fontSize: 12,
                    fontWeight: isUpvoted ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedQuestions.remove(question.id);
              } else {
                _expandedQuestions.add(question.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpanded ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  size: 14,
                  color: isExpanded
                      ? AppColors.primary
                      : (widget.isDark ? AppColors.grey400 : AppColors.grey600),
                ),
                const SizedBox(width: 4),
                Text(
                  '${question.answersCount}',
                  style: TextStyle(
                    color: isExpanded
                        ? AppColors.primary
                        : (widget.isDark
                            ? AppColors.grey400
                            : AppColors.grey600),
                    fontSize: 12,
                    fontWeight:
                        isExpanded ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  void _showAskQuestionDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveDialog(
        title: Text('course_player.ask_question'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'course_player.question_title_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'course_player.question_content_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _submitQuestion(
              ctx,
              titleController.text,
              contentController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('common.submit'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuestion(
    BuildContext ctx,
    String title,
    String content,
  ) async {
    if (title.isEmpty || content.isEmpty) return;

    AppLogger.i('❓ [QASection] Submitting question...');
    final result = await widget.repository.addQuestion(
      courseId: widget.courseId,
      enrollmentId: widget.enrollmentId,
      lessonId: widget.lessonId,
      title: title,
      content: content,
    );

    result.fold(
      (failure) => AppLogger.e('[QASection] Failed: ${failure.message}'),
      (_) {
        AppLogger.success('[QASection] Question submitted');
        Navigator.pop(ctx);
        setState(() => _loadQuestions());
      },
    );
  }

  Widget _buildAnswerItem(QAAnswerEntity answer) {
    final isUpvoted = answer.hasUpvoted || _upvotedAnswers.contains(answer.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: answer.isInstructor
            ? AppColors.primary.withValues(alpha: 0.05)
            : (widget.isDark ? AppColors.cardDark : AppColors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: answer.isInstructor
              ? AppColors.primary.withValues(alpha: 0.2)
              : (widget.isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: answer.isInstructor
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.grey300.withValues(alpha: 0.3),
                backgroundImage:
                    answer.userAvatar != null && answer.userAvatar!.isNotEmpty
                        ? NetworkImage(answer.userAvatar!)
                        : null,
                child: answer.userAvatar == null || answer.userAvatar!.isEmpty
                    ? Text(
                        (answer.userName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: answer.isInstructor
                              ? AppColors.primary
                              : AppColors.grey600,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          answer.userName ?? 'مستخدم',
                          style: TextStyle(
                            color: widget.isDark
                                ? AppColors.white
                                : AppColors.textMainLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        if (answer.isInstructor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'course_player.instructor'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(answer.createdAt),
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.grey400
                            : AppColors.grey600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer.content,
            style: TextStyle(
              color:
                  widget.isDark ? AppColors.grey300 : AppColors.textMainLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Prevent event bubbling to parent InkWell
                  _toggleUpvote(answer.id);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUpvoted
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.grey100.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: isUpvoted
                        ? Border.all(color: AppColors.primary, width: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 14,
                        color: isUpvoted
                            ? AppColors.primary
                            : (widget.isDark
                                ? AppColors.grey400
                                : AppColors.grey600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${answer.upvotesCount + (_answerUpvoteAdjustments[answer.id] ?? 0)}',
                        style: TextStyle(
                          color: isUpvoted
                              ? AppColors.primary
                              : (widget.isDark
                                  ? AppColors.grey300
                                  : AppColors.grey700),
                          fontSize: 12,
                          fontWeight:
                              isUpvoted ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUpvote(String answerId) async {
    final result = await widget.repository.toggleAnswerUpvote(
      answerId: answerId,
    );

    result.fold(
      (failure) {
        AppLogger.e('[QASection] Failed to toggle upvote: ${failure.message}');
        if (failure.message.contains('own answer')) {
          // Show message that user cannot upvote their own answer
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('course_player.cannot_upvote_own_answer'.tr()),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      (isUpvoted) {
        setState(() {
          if (isUpvoted) {
            _upvotedAnswers.add(answerId);
            _answerUpvoteAdjustments[answerId] =
                (_answerUpvoteAdjustments[answerId] ?? 0) + 1;
          } else {
            _upvotedAnswers.remove(answerId);
            _answerUpvoteAdjustments[answerId] =
                (_answerUpvoteAdjustments[answerId] ?? 0) - 1;
          }
        });
        // Don't reload - just update UI with adjustments
        AppLogger.i('[QASection] Toggled upvote for answer: $answerId');
      },
    );
  }

  void _toggleQuestionUpvote(String questionId) {
    setState(() {
      if (_upvotedQuestions.contains(questionId)) {
        _upvotedQuestions.remove(questionId);
        _questionUpvoteAdjustments[questionId] =
            (_questionUpvoteAdjustments[questionId] ?? 0) - 1;
      } else {
        _upvotedQuestions.add(questionId);
        _questionUpvoteAdjustments[questionId] =
            (_questionUpvoteAdjustments[questionId] ?? 0) + 1;
      }
    });
    AppLogger.i('[QASection] Toggled upvote for question: $questionId');
  }
}
