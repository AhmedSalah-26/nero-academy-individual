import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_quizzes/download_helper.dart';
import 'quiz_response_details_screen.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

/// Quiz Attempts Screen - Full page for viewing quiz attempts by students
class QuizAttemptsScreen extends StatelessWidget {
  final String quizId;
  final String quizTitle;
  final List<Map<String, dynamic>> attempts;

  const QuizAttemptsScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'محاولات الطلاب' : 'Student Attempts',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              quizTitle,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        actions: [
          if (attempts.isNotEmpty)
            IconButton(
              onPressed: () => _exportToExcel(context, isArabic),
              icon: const Icon(Icons.table_chart_outlined),
              tooltip: isArabic ? 'تصدير Excel' : 'Export Excel',
            ),
        ],
      ),
      body: Column(
        children: [
          if (attempts.isNotEmpty) _buildStats(isArabic, isDark),
          Expanded(child: _buildAttemptsList(context, isArabic, isDark)),
        ],
      ),
    );
  }

  Widget _buildStats(bool isArabic, bool isDark) {
    final totalAttempts = attempts.length;
    final passedAttempts = attempts.where((a) => a['passed'] == true).length;
    final avgScore = attempts.isEmpty
        ? 0.0
        : attempts
                .map((a) => (a['score'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            attempts.length;

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
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.assignment_turned_in_rounded,
              label: isArabic ? 'إجمالي المحاولات' : 'Total Attempts',
              value: totalAttempts.toString(),
              color: AppColors.info,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_rounded,
              label: isArabic ? 'ناجح' : 'Passed',
              value: passedAttempts.toString(),
              color: AppColors.success,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.analytics_rounded,
              label: isArabic ? 'متوسط الدرجة' : 'Avg Score',
              value: '${avgScore.toStringAsFixed(1)}%',
              color: AppColors.warning,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsList(BuildContext context, bool isArabic, bool isDark) {
    if (attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'لا توجد محاولات بعد' : 'No attempts yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'سيظهر هنا عندما يبدأ الطلاب في حل الاختبار'
                  : 'Attempts will appear here when students take the quiz',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attempts.length,
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        return _AttemptListItem(
          attempt: attempt,
          isArabic: isArabic,
          isDark: isDark,
          onTap: () => _showResponseDetails(context, attempt, isArabic),
        );
      },
    );
  }

  void _showResponseDetails(
      BuildContext context, Map<String, dynamic> attempt, bool isArabic) {
    // Parse answers from attempt data
    final answers = _parseAnswers(attempt);

    // Navigate to full screen instead of dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => QuizResponseDetailsScreen(
          studentName: attempt['student_name'] as String? ?? 'Unknown',
          studentEmail: attempt['student_email'] as String?,
          studentPhone: attempt['student_phone'] as String?,
          score: (attempt['score'] as num?)?.toDouble() ?? 0,
          passed: attempt['passed'] as bool? ?? false,
          completedAt: attempt['completed_at'] != null
              ? DateTime.tryParse(attempt['completed_at'].toString())
              : null,
          timeTaken: attempt['time_taken'] as int? ?? 0,
          answers: answers,
        ),
      ),
    );
  }

  List<QuizAnswerDetail> _parseAnswers(Map<String, dynamic> attempt) {
    final answersData = attempt['answers'] as List<dynamic>? ?? [];
    return answersData.map((a) {
      final answerMap = a as Map<String, dynamic>;
      final optionsData = answerMap['options'] as List<dynamic>? ?? [];

      return QuizAnswerDetail(
        questionId: answerMap['question_id'] as String? ?? '',
        questionTextAr: answerMap['question_text_ar'] as String? ?? '',
        questionTextEn: answerMap['question_text_en'] as String? ?? '',
        imageUrl: answerMap['image_url'] as String?,
        options: optionsData.map((o) {
          final optMap = o as Map<String, dynamic>;
          return QuizOptionDetail(
            id: optMap['id'] as String? ?? '',
            textAr: optMap['text_ar'] as String? ?? '',
            textEn: optMap['text_en'] as String? ?? '',
          );
        }).toList(),
        selectedOptionId: answerMap['selected_option_id'] as String?,
        correctOptionId: answerMap['correct_option_id'] as String? ?? '',
        isCorrect: answerMap['is_correct'] as bool? ?? false,
        explanation: answerMap['explanation'] as String?,
      );
    }).toList();
  }

  void _exportToExcel(BuildContext context, bool isArabic) {
    // Build CSV content with BOM for Excel Arabic support
    final buffer = StringBuffer();

    // Add BOM for UTF-8 Excel compatibility
    buffer.write('\uFEFF');

    // Calculate stats
    final totalAttempts = attempts.length;
    final passedCount = attempts.where((a) => a['passed'] == true).length;
    final failedCount = totalAttempts - passedCount;
    final avgScore = totalAttempts > 0
        ? attempts
                .map((a) => (a['score'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            totalAttempts
        : 0.0;

    // Quiz info header
    if (isArabic) {
      buffer.writeln('تقرير نتائج الاختبار');
      buffer.writeln('اسم الاختبار:,$quizTitle');
      buffer.writeln('إجمالي المحاولات:,$totalAttempts');
      buffer.writeln('عدد الناجحين:,$passedCount');
      buffer.writeln('عدد الراسبين:,$failedCount');
      buffer.writeln('متوسط الدرجات:,${avgScore.toStringAsFixed(1)}%');
      buffer
          .writeln('تاريخ التصدير:,${DateTime.now().toString().split('.')[0]}');
      buffer.writeln('');
      buffer.writeln('');
    } else {
      buffer.writeln('Quiz Results Report');
      buffer.writeln('Quiz Name:,$quizTitle');
      buffer.writeln('Total Attempts:,$totalAttempts');
      buffer.writeln('Passed:,$passedCount');
      buffer.writeln('Failed:,$failedCount');
      buffer.writeln('Average Score:,${avgScore.toStringAsFixed(1)}%');
      buffer.writeln('Export Date:,${DateTime.now().toString().split('.')[0]}');
      buffer.writeln('');
      buffer.writeln('');
    }

    // Header row
    if (isArabic) {
      buffer.writeln(
          'م,اسم الطالب,رقم الهاتف,البريد الإلكتروني,الدرجة,الدرجة %,الحالة,عدد الإجابات الصحيحة,عدد الإجابات الخاطئة,تاريخ البدء,تاريخ الإرسال,الوقت المستغرق (ثانية),الوقت المستغرق');
    } else {
      buffer.writeln(
          '#,Student Name,Phone,Email,Score,Score %,Status,Correct Answers,Wrong Answers,Started At,Submitted At,Time (seconds),Time Taken');
    }

    // Data rows
    for (int i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      final studentName = attempt['student_name'] as String? ?? 'Unknown';
      final studentPhone = attempt['student_phone'] as String? ?? '-';
      final studentEmail = attempt['student_email'] as String? ?? '-';
      final score = (attempt['score'] as num?)?.toDouble() ?? 0;
      final passed = attempt['passed'] as bool? ?? false;
      final timeTaken = attempt['time_taken'] as int? ?? 0;

      // Parse dates
      final startedAt = attempt['started_at'] != null
          ? DateTime.tryParse(attempt['started_at'].toString())
          : null;
      final completedAt = attempt['completed_at'] != null
          ? DateTime.tryParse(attempt['completed_at'].toString())
          : null;

      // Count correct/wrong answers
      final answers = attempt['answers'] as List<dynamic>? ?? [];
      final correctCount = answers.where((a) => a['is_correct'] == true).length;
      final wrongCount = answers.length - correctCount;

      final status = passed
          ? (isArabic ? 'ناجح' : 'Passed')
          : (isArabic ? 'راسب' : 'Failed');

      final startDateStr = startedAt != null
          ? '${startedAt.year}/${startedAt.month}/${startedAt.day} ${startedAt.hour}:${startedAt.minute.toString().padLeft(2, '0')}'
          : '-';

      final completeDateStr = completedAt != null
          ? '${completedAt.year}/${completedAt.month}/${completedAt.day} ${completedAt.hour}:${completedAt.minute.toString().padLeft(2, '0')}'
          : '-';

      final minutes = timeTaken ~/ 60;
      final seconds = timeTaken % 60;
      final timeStr = '${minutes}m ${seconds}s';

      // Escape fields for CSV
      final escapedName = '"${studentName.replaceAll('"', '""')}"';
      final escapedPhone = '"${studentPhone.replaceAll('"', '""')}"';
      final escapedEmail = '"${studentEmail.replaceAll('"', '""')}"';

      buffer.writeln(
          '${i + 1},$escapedName,$escapedPhone,$escapedEmail,${score.toStringAsFixed(0)},${score.toStringAsFixed(1)}%,$status,$correctCount,$wrongCount,$startDateStr,$completeDateStr,$timeTaken,$timeStr');
    }

    // Download file
    _downloadCsvFile(context, buffer.toString(), isArabic);
  }

  Future<void> _downloadCsvFile(
      BuildContext context, String content, bool isArabic) async {
    final fileName = '${quizTitle.replaceAll(' ', '_')}_students.csv';

    if (kIsWeb) {
      try {
        downloadFile(content, fileName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'تم تصدير البيانات بنجاح'
                : 'Data exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isArabic ? 'فشل في التصدير: $e' : 'Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Mobile implementation
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');

      // Write content to file
      await file.writeAsString(content, flush: true);

      if (!context.mounted) return;

      // Share file
      final xFile = XFile(file.path, mimeType: 'text/csv');
      await Share.shareXFiles(
        [xFile],
        text: isArabic
            ? 'نتائج الاختبار: $quizTitle'
            : 'Quiz Results: $quizTitle',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'فشل في التصدير: $e' : 'Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textMutedDark : Colors.grey[600],
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _AttemptListItem extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final bool isArabic;
  final bool isDark;
  final VoidCallback? onTap;

  const _AttemptListItem({
    required this.attempt,
    required this.isArabic,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final studentName = attempt['student_name'] as String? ?? 'Unknown';
    final score = (attempt['score'] as num?)?.toDouble() ?? 0;
    final passed = attempt['passed'] as bool? ?? false;
    final completedAt = attempt['completed_at'] != null
        ? DateTime.tryParse(attempt['completed_at'].toString())
        : null;

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
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: passed
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.error.withValues(alpha: 0.2),
          child: Icon(
            passed ? Icons.check_rounded : Icons.close_rounded,
            color: passed ? AppColors.success : AppColors.error,
            size: 28,
          ),
        ),
        title: Text(
          studentName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        subtitle: completedAt != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('MMM d, yyyy - h:mm a').format(completedAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: passed
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: passed ? AppColors.success : AppColors.error,
                  width: 1.5,
                ),
              ),
              child: Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: passed ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.textMutedDark : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
