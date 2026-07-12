import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

class QuizResponseDetailsHeaderSliver extends StatelessWidget {
  final String studentName;
  final String? studentEmail;
  final String? studentPhone;
  final double score;
  final bool passed;
  final DateTime? completedAt;

  const QuizResponseDetailsHeaderSliver({
    super.key,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhone,
    required this.score,
    required this.passed,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final formattedCompletedAt = completedAt != null
        ? DateFormat('yyyy/MM/dd - HH:mm').format(completedAt!)
        : null;
    final secondaryParts = <String>[
      if (studentEmail != null && studentEmail!.trim().isNotEmpty)
        studentEmail!,
      if (studentPhone != null && studentPhone!.trim().isNotEmpty)
        studentPhone!,
      if (formattedCompletedAt != null &&
          formattedCompletedAt.trim().isNotEmpty)
        formattedCompletedAt,
    ];
    final secondaryInfo = secondaryParts.join(' • ');

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: passed ? AppColors.success : AppColors.error,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                passed ? AppColors.success : AppColors.error,
                (passed ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (secondaryInfo.isNotEmpty)
                          Text(
                            secondaryInfo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '${score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: passed ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizResponseSummaryCard extends StatelessWidget {
  final List<QuizAnswerDetail> answers;
  final int timeTaken;
  final bool passed;
  final bool isDark;
  final bool isArabic;

  const QuizResponseSummaryCard({
    super.key,
    required this.answers,
    required this.timeTaken,
    required this.passed,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final correctCount = answers.where((a) => a.isCorrect).length;
    final totalCount = answers.length;
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
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
          Row(
            children: [
              Expanded(
                child: _QuizResponseSummaryItem(
                  icon: Icons.check_circle_outline,
                  label: isArabic ? 'صحيح' : 'Correct',
                  value: '$correctCount / $totalCount',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _QuizResponseSummaryItem(
                  icon: Icons.cancel_outlined,
                  label: isArabic ? 'خطأ' : 'Wrong',
                  value: '${totalCount - correctCount}',
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: _QuizResponseSummaryItem(
                  icon: Icons.timer_outlined,
                  label: isArabic ? 'الوقت' : 'Time',
                  value: '${minutes}m ${seconds}s',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: passed ? AppColors.success : AppColors.error,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  color: passed ? AppColors.success : AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  passed
                      ? (isArabic ? 'ناجح' : 'PASSED')
                      : (isArabic ? 'راسب' : 'FAILED'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: passed ? AppColors.success : AppColors.error,
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

class _QuizResponseSummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuizResponseSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class QuizResponseAnswerCard extends StatelessWidget {
  final QuizAnswerDetail answer;
  final int questionNumber;
  final bool isDark;
  final bool isArabic;

  const QuizResponseAnswerCard({
    super.key,
    required this.answer,
    required this.questionNumber,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: answer.isCorrect
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.error.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (answer.isCorrect ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: answer.isCorrect
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: answer.isCorrect
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$questionNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (context) {
                            final text = isArabic
                                ? (answer.questionTextAr.isNotEmpty
                                    ? answer.questionTextAr
                                    : answer.questionTextEn)
                                : (answer.questionTextEn.isNotEmpty
                                    ? answer.questionTextEn
                                    : answer.questionTextAr);

                            if (text.isEmpty) return const SizedBox.shrink();

                            return Text(
                              text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight,
                              ),
                            );
                          }),
                          if (answer.imageUrl != null &&
                              answer.imageUrl!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () =>
                                  _showImageDialog(context, answer.imageUrl!),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  answer.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.grey100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...answer.options.map(
                      (option) => _QuizResponseOptionItem(
                        option: option,
                        selectedOptionId: answer.selectedOptionId,
                        correctOptionId: answer.correctOptionId,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                    ),
                    if (answer.explanation != null &&
                        answer.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.info,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'شرح' : 'Explanation',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.info,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    answer.explanation!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: isArabic ? 12 : null,
            right: isArabic ? null : 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: answer.isCorrect ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    answer.isCorrect ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    answer.isCorrect
                        ? (isArabic ? 'صحيح' : 'Correct')
                        : (isArabic ? 'خطأ' : 'Wrong'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResponseOptionItem extends StatelessWidget {
  final QuizOptionDetail option;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool isDark;
  final bool isArabic;

  const _QuizResponseOptionItem({
    required this.option,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = option.id == selectedOptionId;
    final isCorrect = option.id == correctOptionId;

    Color bgColor;
    Color borderColor;
    IconData? icon;
    Color? iconColor;

    if (isCorrect) {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      borderColor = AppColors.success;
      icon = Icons.check_circle;
      iconColor = AppColors.success;
    } else if (isSelected && !isCorrect) {
      bgColor = AppColors.error.withValues(alpha: 0.15);
      borderColor = AppColors.error;
      icon = Icons.cancel;
      iconColor = AppColors.error;
    } else {
      bgColor = isDark ? AppColors.surfaceDark : AppColors.grey50;
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected || isCorrect ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: iconColor, size: 24)
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isArabic ? option.textAr : option.textEn,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected || isCorrect
                    ? FontWeight.w600
                    : FontWeight.normal,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          if (isSelected && !isCorrect)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isArabic ? 'إجابتك' : 'Your answer',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isCorrect)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isArabic ? 'الإجابة الصحيحة' : 'Correct answer',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
