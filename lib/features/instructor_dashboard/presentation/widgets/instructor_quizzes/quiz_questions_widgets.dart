import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../cubit/instructor_quizzes_cubit.dart';

class QuizQuestionsEmptyState extends StatelessWidget {
  final bool isArabic;
  final bool isDark;

  const QuizQuestionsEmptyState({
    super.key,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'لا توجد أسئلة' : 'No questions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'ابدأ بإضافة أسئلة للاختبار'
                : 'Start by adding questions to the quiz',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class QuizQuestionsSummaryCard extends StatelessWidget {
  final int totalQuestions;
  final bool isArabic;
  final bool isDark;

  const QuizQuestionsSummaryCard({
    super.key,
    required this.totalQuestions,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.quiz, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'إجمالي الأسئلة' : 'Total Questions',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalQuestions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'جاهز' : 'Ready',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuizQuestionManagementCard extends StatelessWidget {
  final QuizQuestionModel question;
  final int index;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onImagePreview;

  const QuizQuestionManagementCard({
    super.key,
    required this.question,
    required this.index,
    required this.isArabic,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onImagePreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.drag_indicator,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    quizQuestionTypeLabel(question.type, isArabic),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: isArabic ? 'تعديل' : 'Edit',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                  tooltip: isArabic ? 'حذف' : 'Delete',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((isArabic ? question.questionAr : question.questionEn)
                    .isNotEmpty)
                  Text(
                    isArabic ? question.questionAr : question.questionEn,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                      height: 1.5,
                    ),
                  ),
                if (question.imageUrl != null &&
                    question.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => onImagePreview(question.imageUrl!),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            question.imageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (question.options.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...question.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            option.isCorrect
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: option.isCorrect
                                ? AppColors.success
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isArabic ? option.textAr : option.textEn,
                              style: TextStyle(
                                fontSize: 14,
                                color: option.isCorrect
                                    ? AppColors.success
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary),
                                fontWeight: option.isCorrect
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuizQuestionsFabRow extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onAddImageQuestions;
  final VoidCallback onAddQuestion;
  final VoidCallback onAddFromAi;

  const QuizQuestionsFabRow({
    super.key,
    required this.isArabic,
    required this.onAddImageQuestions,
    required this.onAddQuestion,
    required this.onAddFromAi,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'add_question_menu_fab',
      onPressed: () => _showAddMenu(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  void _showAddMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
                title: Text(isArabic ? 'إضافة سؤال' : 'Add Question'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAddQuestion();
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: Text(
                  LocaleKeys.course_editor_ai_import_fab_label.tr(),
                ),
                subtitle: Text(
                  LocaleKeys.course_editor_ai_import_fab_subtitle.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onAddFromAi();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(isArabic
                    ? 'إضافة أسئلة من صور'
                    : 'Add Questions from Images'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAddImageQuestions();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

String quizQuestionTypeLabel(String type, bool isArabic) {
  switch (type) {
    case 'single':
      return isArabic ? 'اختيار واحد' : 'Single Choice';
    case 'multiple':
      return isArabic ? 'اختيار متعدد' : 'Multiple Choice';
    case 'true_false':
      return isArabic ? 'صح/خطأ' : 'True/False';
    case 'text':
      return isArabic ? 'إجابة نصية' : 'Text Answer';
    default:
      return type;
  }
}
