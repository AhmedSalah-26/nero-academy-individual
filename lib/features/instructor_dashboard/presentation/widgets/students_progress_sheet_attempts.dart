import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/instructor_repository.dart';
import '../screens/quiz_response_details_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/loading_state.dart';

class StudentAttemptsDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String? studentPhone;

  const StudentAttemptsDialog({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.studentPhone,
  });

  @override
  State<StudentAttemptsDialog> createState() => _StudentAttemptsDialogState();
}

class _StudentAttemptsDialogState extends State<StudentAttemptsDialog> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _attempts = [];

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    try {
      final client = Supabase.instance.client;

      // 1. Fetch attempts for the student
      final attemptsRes = await client.from('quiz_attempts').select('''
        id,
        score,
        percentage,
        passed,
        answers,
        started_at,
        completed_at,
        time_spent,
        quiz_id,
        quizzes!inner(id, title_ar, title_en)
      ''').eq('user_id', widget.studentId).order('completed_at', ascending: false);

      final attemptsList = (attemptsRes as List).cast<Map<String, dynamic>>();
      if (attemptsList.isEmpty) {
        if (mounted) {
          setState(() {
            _attempts = [];
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Fetch questions and options for those quizzes
      final quizIds = attemptsList.map((a) => a['quiz_id'] as String).toSet().toList();
      final questionsRes = await client.from('quiz_questions').select('''
        id,
        quiz_id,
        question_ar,
        question_en,
        image_url,
        explanation,
        options
      ''').inFilter('quiz_id', quizIds);

      final questionsList = (questionsRes as List).cast<Map<String, dynamic>>();

      // 3. Process each attempt
      final processedAttempts = attemptsList.map((attempt) {
        final quiz = attempt['quizzes'] as Map<String, dynamic>? ?? {};
        final answersData = attempt['answers'] as Map<String, dynamic>? ?? {};
        final quizId = attempt['quiz_id'] as String;

        final quizQuestions = questionsList.where((q) => q['quiz_id'] == quizId).toList();
        final List<QuizAnswerDetail> detailedAnswers = [];

        for (final q in quizQuestions) {
          final qId = q['id'] as String;
          final optionsData = (q['options'] as List? ?? []).cast<Map<String, dynamic>>();

          final optionsList = optionsData.map((o) {
            return QuizOptionDetail(
              id: o['id'] as String? ?? '',
              textAr: o['text_ar'] as String? ?? '',
              textEn: o['text_en'] as String? ?? '',
            );
          }).toList();

          final correctOpt = optionsData.firstWhere(
            (o) => o['is_correct'] == true,
            orElse: () => <String, dynamic>{},
          );
          final correctOptionId = correctOpt['id'] as String? ?? '';

          final answerVal = answersData[qId];
          String? selectedOptionId;
          bool isCorrect = false;

          if (answerVal is Map) {
            final selectedIds = answerVal['selected_option_ids'] as List?;
            selectedOptionId = (selectedIds != null && selectedIds.isNotEmpty)
                ? selectedIds.first.toString()
                : null;
            isCorrect = answerVal['is_correct'] as bool? ?? false;
          } else if (answerVal is List) {
            selectedOptionId = answerVal.isNotEmpty ? answerVal.first.toString() : null;
            isCorrect = selectedOptionId == correctOptionId;
          } else if (answerVal != null) {
            selectedOptionId = answerVal.toString();
            isCorrect = selectedOptionId == correctOptionId;
          }

          detailedAnswers.add(QuizAnswerDetail(
            questionId: qId,
            questionTextAr: q['question_ar'] as String? ?? '',
            questionTextEn: q['question_en'] as String? ?? '',
            imageUrl: q['image_url'] as String?,
            options: optionsList,
            selectedOptionId: selectedOptionId,
            correctOptionId: correctOptionId,
            isCorrect: isCorrect,
            explanation: q['explanation'] as String?,
          ));
        }

        final timeSpent = attempt['time_spent'] as int?;
        int timeTaken = 0;
        if (timeSpent != null && timeSpent > 0) {
          timeTaken = timeSpent;
        } else {
          final startedAt = attempt['started_at'] != null ? DateTime.tryParse(attempt['started_at'].toString()) : null;
          final completedAt = attempt['completed_at'] != null ? DateTime.tryParse(attempt['completed_at'].toString()) : null;
          timeTaken = (startedAt != null && completedAt != null) ? completedAt.difference(startedAt).inSeconds.abs() : 0;
        }

        return {
          'quiz_title_ar': quiz['title_ar'] as String? ?? '',
          'quiz_title_en': quiz['title_en'] as String? ?? '',
          'score': (attempt['percentage'] as num?)?.toDouble() ?? 0.0,
          'passed': attempt['passed'] as bool? ?? false,
          'completed_at': attempt['completed_at'] != null ? DateTime.tryParse(attempt['completed_at'].toString()) : null,
          'time_taken': timeTaken,
          'answers': detailedAnswers,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _attempts = processedAttempts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = DateFormat('yyyy/MM/dd HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'محاولات اختبارات الطالب' : 'Student Quiz Attempts',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                      : _attempts.isEmpty
                          ? Center(child: Text(isArabic ? 'لا توجد محاولات اختبار' : 'No quiz attempts found'))
                          : ListView.builder(
                              itemCount: _attempts.length,
                              itemBuilder: (context, index) {
                                final a = _attempts[index];
                                final title = isArabic ? a['quiz_title_ar'] : a['quiz_title_en'];
                                final passed = a['passed'] as bool;
                                final score = a['score'] as double;
                                final dateStr = a['completed_at'] != null ? fmt.format(a['completed_at']) : '-';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text('${isArabic ? 'التاريخ:' : 'Date:'} $dateStr'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (passed ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${score.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              color: passed ? AppColors.success : AppColors.error,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right, size: 20),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => QuizResponseDetailsScreen(
                                            studentName: widget.studentName,
                                            studentEmail: widget.studentEmail,
                                            studentPhone: widget.studentPhone,
                                            score: score,
                                            passed: passed,
                                            completedAt: a['completed_at'],
                                            timeTaken: a['time_taken'] as int,
                                            answers: a['answers'] as List<QuizAnswerDetail>,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            )
          ],
        ),
      ),
    );
  }
}
