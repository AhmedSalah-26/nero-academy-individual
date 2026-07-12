import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_quizzes/quiz_response_details_widgets.dart';

/// Quiz Response Details Screen - Full page for viewing detailed quiz responses.
class QuizResponseDetailsScreen extends StatelessWidget {
  final String studentName;
  final String? studentEmail;
  final String? studentPhone;
  final double score;
  final bool passed;
  final DateTime? completedAt;
  final int timeTaken;
  final List<QuizAnswerDetail> answers;

  const QuizResponseDetailsScreen({
    super.key,
    required this.studentName,
    this.studentEmail,
    this.studentPhone,
    required this.score,
    required this.passed,
    this.completedAt,
    required this.timeTaken,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          QuizResponseDetailsHeaderSliver(
            studentName: studentName,
            studentEmail: studentEmail,
            studentPhone: studentPhone,
            score: score,
            passed: passed,
            completedAt: completedAt,
          ),
          SliverToBoxAdapter(
            child: QuizResponseSummaryCard(
              answers: answers,
              timeTaken: timeTaken,
              passed: passed,
              isDark: isDark,
              isArabic: isArabic,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => QuizResponseAnswerCard(
                  answer: answers[index],
                  questionNumber: index + 1,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
                childCount: answers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
