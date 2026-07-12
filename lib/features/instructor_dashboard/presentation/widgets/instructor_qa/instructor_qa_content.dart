import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_question_model.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_qa_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/screens/question_details_screen.dart';

// Type aliases for easier reference
typedef InstructorQAQuestion = InstructorQuestionModel;
typedef InstructorQAAnswer = InstructorAnswerModel;

/// Instructor Q&A Content
class InstructorQAContent extends StatefulWidget {
  const InstructorQAContent({super.key});

  @override
  State<InstructorQAContent> createState() => _InstructorQAContentState();
}

class _InstructorQAContentState extends State<InstructorQAContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InstructorQACubit>().loadQuestions(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InstructorQACubit>().loadMoreQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<InstructorQACubit, InstructorQAState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic),
            Expanded(child: _buildQuestionsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, InstructorQAState state, bool isArabic) {
    final tabs = [
      const DashboardTabItem(label: 'All', labelAr: 'الكل'),
      const DashboardTabItem(label: 'Unanswered', labelAr: 'بدون إجابة'),
      const DashboardTabItem(label: 'Answered', labelAr: 'تمت الإجابة'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: DashboardTabs(
        tabs: tabs,
        selectedIndex: _getTabIndex(state.currentStatus),
        onTabSelected: (index) => context
            .read<InstructorQACubit>()
            .changeStatus(_getStatusFromIndex(index)),
      ),
    );
  }

  int _getTabIndex(QAStatus status) {
    switch (status) {
      case QAStatus.all:
        return 0;
      case QAStatus.unanswered:
        return 1;
      case QAStatus.answered:
        return 2;
    }
  }

  QAStatus _getStatusFromIndex(int index) {
    switch (index) {
      case 1:
        return QAStatus.unanswered;
      case 2:
        return QAStatus.answered;
      default:
        return QAStatus.all;
    }
  }

  Widget _buildQuestionsList(
      BuildContext context, InstructorQAState state, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.questions.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: const LoadingSkeleton(width: double.infinity, height: 120)),
      );
    }

    if (state.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا توجد أسئلة' : 'No questions found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context
          .read<InstructorQACubit>()
          .loadQuestions(status: state.currentStatus, refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.questions.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.questions.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          final question = state.questions[index];
          return InkWell(
            onTap: () => _showQuestionDetails(context, question, isArabic),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: question.userAvatar != null
                            ? NetworkImage(question.userAvatar!)
                            : null,
                        child: question.userAvatar == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(question.userName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textMainDark
                                        : AppColors.textMainLight)),
                            Text(question.courseTitle,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: question.isAnswered
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.isAnswered
                              ? (isArabic ? 'تمت الإجابة' : 'Answered')
                              : (isArabic ? 'بدون إجابة' : 'Unanswered'),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: question.isAnswered
                                  ? AppColors.success
                                  : AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(question.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight)),
                  const SizedBox(height: 4),
                  Text(question.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                      const SizedBox(width: 4),
                      Text('${question.answersCount}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight)),
                      const SizedBox(width: 16),
                      Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(question.createdAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQuestionDetails(
      BuildContext context, InstructorQAQuestion question, bool isArabic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionDetailsScreen(
          question: question,
          cubit: context.read<InstructorQACubit>(),
        ),
      ),
    );
  }
}
