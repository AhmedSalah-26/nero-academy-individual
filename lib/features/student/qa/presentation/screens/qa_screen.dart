import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/animations/app_animations.dart';
import 'package:lms_platform/features/student/qa/domain/entities/qa_entity.dart';
import 'package:lms_platform/features/student/qa/presentation/widgets/qa_widgets.dart';

/// Q&A Filter
enum QAFilter { all, unanswered, myQuestions }

/// Q&A Screen - Questions and Answers for a course
class QAScreen extends StatefulWidget {
  final String courseId;
  final String? lessonId;

  const QAScreen({
    super.key,
    required this.courseId,
    this.lessonId,
  });

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  QAFilter _currentFilter = QAFilter.all;
  final List<QuestionEntity> _questions = _getMockQuestions();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredQuestions = _filterQuestions();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'qa.title'.tr(),
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(isDark),
          Expanded(
            child: filteredQuestions.isEmpty
                ? EmptyState(
                    type: EmptyStateType.search,
                    title: 'qa.no_questions'.tr(),
                    message: 'qa.no_questions_desc'.tr(),
                    actionText: 'qa.ask_question'.tr(),
                    onAction: () => _showAskQuestionDialog(context, isDark),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredQuestions.length,
                    itemBuilder: (context, index) {
                      return SlideFadeIn.up(
                        delay: Duration(milliseconds: 50 * index),
                        child: QuestionCard(
                          question: filteredQuestions[index],
                          isDark: isDark,
                          onTap: () => _showQuestionDetails(
                              context, filteredQuestions[index]),
                          onUpvote: () =>
                              _toggleUpvote(filteredQuestions[index].id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAskQuestionDialog(context, isDark),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'qa.ask_question'.tr(),
          style: const TextStyle(
            fontFamily: 'Almarai',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: QAFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                _getFilterLabel(filter),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
                ),
              ),
              backgroundColor: isDark ? AppColors.cardDark : AppColors.grey100,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              onSelected: (_) => setState(() => _currentFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(QAFilter filter) {
    switch (filter) {
      case QAFilter.all:
        return 'qa.all'.tr();
      case QAFilter.unanswered:
        return 'qa.unanswered'.tr();
      case QAFilter.myQuestions:
        return 'qa.my_questions'.tr();
    }
  }

  List<QuestionEntity> _filterQuestions() {
    switch (_currentFilter) {
      case QAFilter.all:
        return _questions;
      case QAFilter.unanswered:
        return _questions.where((q) => q.answersCount == 0).toList();
      case QAFilter.myQuestions:
        return _questions.where((q) => q.userId == 'current-user').toList();
    }
  }

  void _toggleUpvote(String questionId) {
    setState(() {
      final index = _questions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        final q = _questions[index];
        _questions[index] = q.copyWith(
          isUpvotedByUser: !q.isUpvotedByUser,
          upvotes: q.isUpvotedByUser ? q.upvotes - 1 : q.upvotes + 1,
        );
      }
    });
  }

  void _showQuestionDetails(BuildContext context, QuestionEntity question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionDetailsScreen(question: question),
      ),
    );
  }

  void _showAskQuestionDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AskQuestionForm(isDark: isDark),
      ),
    );
  }
}

/// Question Details Screen
class QuestionDetailsScreen extends StatelessWidget {
  final QuestionEntity question;

  const QuestionDetailsScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text('qa.question'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.title,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              question.content,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 15,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${question.answersCount} ${'qa.answers'.tr()}',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 16),
            ..._getMockAnswers()
                .map((a) => AnswerCard(answer: a, isDark: isDark)),
          ],
        ),
      ),
    );
  }
}

// Mock data
List<QuestionEntity> _getMockQuestions() {
  final now = DateTime.now();
  return [
    QuestionEntity(
      id: '1',
      courseId: 'course-1',
      userId: 'user-1',
      userName: 'Ahmed Hassan',
      title: 'How to handle state management in large apps?',
      content:
          'I\'m building a large Flutter app and wondering what\'s the best approach for state management. Should I use BLoC, Provider, or Riverpod?',
      upvotes: 15,
      answersCount: 3,
      hasInstructorAnswer: true,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    QuestionEntity(
      id: '2',
      courseId: 'course-1',
      userId: 'user-2',
      userName: 'Sara Mohamed',
      title: 'Error when running flutter pub get',
      content:
          'I\'m getting a dependency conflict error when trying to run flutter pub get. The error mentions version solving failed.',
      upvotes: 8,
      answersCount: 2,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    QuestionEntity(
      id: '3',
      courseId: 'course-1',
      userId: 'current-user',
      userName: 'You',
      title: 'Best practices for API integration?',
      content:
          'What are the recommended patterns for integrating REST APIs in Flutter? Should I use Dio or http package?',
      upvotes: 5,
      answersCount: 0,
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}

List<AnswerEntity> _getMockAnswers() {
  final now = DateTime.now();
  return [
    AnswerEntity(
      id: 'a1',
      questionId: '1',
      userId: 'instructor-1',
      userName: 'Dr. Mohamed Ali',
      content:
          'Great question! For large apps, I recommend using BLoC pattern as it provides clear separation of concerns and is highly testable. You can also combine it with Repository pattern for data layer.',
      upvotes: 12,
      isInstructor: true,
      isAccepted: true,
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    AnswerEntity(
      id: 'a2',
      questionId: '1',
      userId: 'user-3',
      userName: 'Omar Khaled',
      content:
          'I\'ve used both BLoC and Riverpod in production apps. Riverpod is simpler to set up but BLoC has better tooling and debugging support.',
      upvotes: 5,
      createdAt: now.subtract(const Duration(hours: 30)),
    ),
  ];
}
