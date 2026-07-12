import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_question_model.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_qa_cubit.dart';

/// Question Details Screen - صفحة تفاصيل السؤال كاملة
class QuestionDetailsScreen extends StatelessWidget {
  final InstructorQuestionModel question;
  final InstructorQACubit cubit;

  const QuestionDetailsScreen({
    super.key,
    required this.question,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isArabic ? 'تفاصيل السؤال' : 'Question Details',
          style: TextStyle(
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
        actions: [
          if (!question.isAnswered)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => _showAnswerDialog(context, isArabic),
                icon: const Icon(Icons.reply, size: 18),
                label: Text(isArabic ? 'إجابة' : 'Answer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: question.isAnswered
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              question.isAnswered
                                  ? Icons.check_circle
                                  : Icons.pending,
                              size: 14,
                              color: question.isAnswered
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              question.isAnswered
                                  ? (isArabic ? 'تمت الإجابة' : 'Answered')
                                  : (isArabic ? 'بدون إجابة' : 'Unanswered'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: question.isAnswered
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                size: 12, color: AppColors.info),
                            const SizedBox(width: 4),
                            Text(
                              '${question.answersCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Title
                  Text(
                    question.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: question.userAvatar != null
                              ? NetworkImage(question.userAvatar!)
                              : null,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: question.userAvatar == null
                              ? const Icon(Icons.person,
                                  color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.userName,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textMainLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                question.courseTitle,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(question.createdAt),
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.grey500
                                      : AppColors.grey500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question Content
                  Text(
                    question.content,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.grey300 : AppColors.textMainLight,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Answers Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.question_answer,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  isArabic ? 'الإجابات' : 'Answers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Spacer(),
                Text(
                  '${question.answersCount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (question.answers != null && question.answers!.isNotEmpty)
              ...question.answers!.map((answer) => _buildAnswerItem(
                    context,
                    answer,
                    isDark,
                    isArabic,
                  ))
            else
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: isDark ? AppColors.grey600 : AppColors.grey400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? 'لا توجد إجابات بعد' : 'No answers yet',
                        style: TextStyle(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAnswerDialog(context, isArabic),
                        icon: const Icon(Icons.reply),
                        label: Text(isArabic
                            ? 'كن أول من يجيب'
                            : 'Be the first to answer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
      // Floating Answer Button (for unanswered questions)
      floatingActionButton: !question.isAnswered
          ? FloatingActionButton.extended(
              onPressed: () => _showAnswerDialog(context, isArabic),
              icon: const Icon(Icons.reply),
              label: Text(isArabic ? 'إجابة' : 'Answer'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildAnswerItem(BuildContext context, InstructorAnswerModel answer,
      bool isDark, bool isArabic) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final canEditAnswer = answer.userId == currentUserId || answer.isInstructor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isInstructor
            ? AppColors.primary.withValues(alpha: 0.05)
            : (isDark ? AppColors.cardDark : AppColors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: answer.isInstructor
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: answer.isInstructor ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: answer.userAvatar != null
                    ? NetworkImage(answer.userAvatar!)
                    : null,
                backgroundColor: answer.isInstructor
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.grey300.withValues(alpha: 0.3),
                child: answer.userAvatar == null
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: answer.isInstructor
                            ? AppColors.primary
                            : AppColors.grey600,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            answer.userName,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textMainLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (answer.isInstructor) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isArabic ? 'المدرس' : 'Instructor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(answer.createdAt),
                      style: TextStyle(
                        color: isDark ? AppColors.grey400 : AppColors.grey600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (canEditAnswer)
                IconButton(
                  onPressed: () =>
                      _showEditAnswerDialog(context, answer, isArabic),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: isArabic ? 'تعديل الرد' : 'Edit reply',
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Answer Content
          Text(
            answer.content,
            style: TextStyle(
              color: isDark ? AppColors.grey300 : AppColors.textMainLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Upvotes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.thumb_up,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${answer.upvotesCount}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardInputDialog(
        title: isArabic ? 'إجابة السؤال' : 'Answer Question',
        message: isArabic ? 'اكتب إجابتك' : 'Write your answer',
        hintText: isArabic ? 'الإجابة...' : 'Answer...',
        confirmText: isArabic ? 'إرسال' : 'Submit',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        maxLines: 5,
      ),
    ).then((answer) {
      if (answer != null && answer.isNotEmpty) {
        cubit.answerQuestion(question.id, answer);
        if (!context.mounted) return;
        Navigator.pop(context); // Go back after answering
      }
    });
  }

  void _showEditAnswerDialog(
      BuildContext context, InstructorAnswerModel answer, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardInputDialog(
        title: isArabic ? 'تعديل الرد' : 'Edit Reply',
        message: isArabic ? 'عدّل نص الرد' : 'Edit your reply content',
        hintText: isArabic ? 'الرد...' : 'Reply...',
        initialValue: answer.content,
        confirmText: isArabic ? 'حفظ' : 'Save',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        maxLines: 5,
      ),
    ).then((updatedContent) {
      if (updatedContent == null) return;
      final trimmed = updatedContent.trim();
      if (trimmed.isEmpty || trimmed == answer.content.trim()) return;

      cubit.updateAnswer(answer.id, trimmed);
      if (!context.mounted) return;
      Navigator.pop(context); // Go back so refreshed list is visible
    });
  }
}
