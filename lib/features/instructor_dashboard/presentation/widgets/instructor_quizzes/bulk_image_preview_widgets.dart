import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'bulk_image_widgets.dart';

/// Questions Preview Widget
class BulkImageQuestionsPreview extends StatelessWidget {
  final List<ImageQuestionModel> questions;
  final List<String> answerLabels;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onAddMore;
  final void Function(int) onRemove;
  final void Function(int questionIndex, int answerIndex) onAnswerSelected;
  final void Function(XFile?) onPreview;

  const BulkImageQuestionsPreview({
    super.key,
    required this.questions,
    required this.answerLabels,
    required this.isArabic,
    required this.isDark,
    required this.onAddMore,
    required this.onRemove,
    required this.onAnswerSelected,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInfoBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: questions.length,
            itemBuilder: (context, index) => _QuestionCard(
              index: index,
              question: questions[index],
              answerLabels: answerLabels,
              isArabic: isArabic,
              isDark: isDark,
              onRemove: () => onRemove(index),
              onAnswerSelected: (ai) => onAnswerSelected(index, ai),
              onPreview: () => onPreview(questions[index].imageFile),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.info.withValues(alpha: 0.1),
          AppColors.primary.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.quiz, size: 20, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? '${questions.length} سؤال'
                      : '${questions.length} Questions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight),
                ),
                Text(
                  isArabic
                      ? 'حدد الإجابة الصحيحة لكل سؤال'
                      : 'Select correct answer for each',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAddMore,
            icon: const Icon(Icons.add_photo_alternate, size: 18),
            label: Text(isArabic ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final ImageQuestionModel question;
  final List<String> answerLabels;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onRemove;
  final void Function(int) onAnswerSelected;
  final VoidCallback onPreview;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.answerLabels,
    required this.isArabic,
    required this.isDark,
    required this.onRemove,
    required this.onAnswerSelected,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswer = question.correctAnswerIndex != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAnswer
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: hasAnswer ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), _buildImage(), _buildAnswerOptions()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16))),
          ),
          const SizedBox(width: 12),
          if (question.correctAnswerIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(isArabic ? 'تم التحديد' : 'Selected',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          const Spacer(),
          IconButton(
              onPressed: onPreview,
              icon: const Icon(Icons.zoom_in, size: 20),
              tooltip: isArabic ? 'تكبير' : 'Zoom'),
          IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: isArabic ? 'حذف' : 'Delete'),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: onPreview,
      child: Container(
        height: 180,
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: question.imageFile != null
              ? (kIsWeb
                  ? Image.network(question.imageFile!.path, fit: BoxFit.cover)
                  : Image.file(File(question.imageFile!.path),
                      fit: BoxFit.cover))
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 48)),
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'اختر الإجابة الصحيحة:' : 'Select correct answer:',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
                answerLabels.length,
                (i) => _AnswerButton(
                      label: answerLabels[i],
                      isSelected: question.correctAnswerIndex == i,
                      isDark: isDark,
                      onTap: () => onAnswerSelected(i),
                    )),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AnswerButton(
      {required this.label,
      required this.isSelected,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success
              : (isDark ? AppColors.surfaceDark : AppColors.grey100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppColors.success : Colors.grey[400]!,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : null))),
      ),
    );
  }
}
