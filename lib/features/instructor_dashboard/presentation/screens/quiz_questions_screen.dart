import 'package:flutter/material.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/shared_widgets/loading_state.dart';
import '../../../../core/shared_widgets/responsive_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/instructor_quizzes_cubit.dart';
import '../widgets/instructor_quizzes/ai_import/ai_import_dialog.dart';
import '../widgets/instructor_quizzes/quiz_questions_widgets.dart';
import 'bulk_image_questions_screen.dart';
import 'question_editor_screen.dart';

/// Quiz Questions Management Screen - Full page for managing quiz questions.
class QuizQuestionsScreen extends StatefulWidget {
  final InstructorQuizModel quiz;
  final InstructorQuizzesCubit cubit;

  const QuizQuestionsScreen({
    super.key,
    required this.quiz,
    required this.cubit,
  });

  @override
  State<QuizQuestionsScreen> createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends State<QuizQuestionsScreen> {
  List<QuizQuestionModel> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    AppLogger.i(
      '[QuizQuestionsScreen] Loading questions for quiz: ${widget.quiz.id}',
    );
    final questions = await widget.cubit.getQuizQuestions(widget.quiz.id);
    await widget.cubit.loadQuizzes(refresh: true);
    AppLogger.d('[QuizQuestionsScreen] Loaded ${questions.length} questions');

    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'أسئلة الاختبار' : 'Quiz Questions',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              isArabic ? widget.quiz.titleAr : widget.quiz.titleEn,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: _buildBody(isArabic, isDark),
      floatingActionButton: QuizQuestionsFabRow(
        isArabic: isArabic,
        onAddImageQuestions: () => _showBulkImageQuestionsDialog(context),
        onAddQuestion: () => _navigateToAddQuestion(context),
        onAddFromAi: () => _showAiImportDialog(context),
      ),
    );
  }

  Widget _buildBody(bool isArabic, bool isDark) {
    if (_isLoading) {
      return const AppLoadingState();
    }

    if (_questions.isEmpty) {
      return QuizQuestionsEmptyState(
        isArabic: isArabic,
        isDark: isDark,
        onAddQuestion: () => _navigateToAddQuestion(context),
      );
    }

    return Column(
      children: [
        QuizQuestionsSummaryCard(
          totalQuestions: _questions.length,
          isArabic: isArabic,
          isDark: isDark,
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _questions.length,
            // ignore: deprecated_member_use
            onReorder: _onReorderQuestions,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation =
                      Tween<double>(begin: 0, end: 8).evaluate(animation);
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final question = _questions[index];
              return QuizQuestionManagementCard(
                key: ValueKey('quiz-question-${question.id}'),
                question: question,
                index: index,
                isArabic: isArabic,
                isDark: isDark,
                onEdit: () => _navigateToEditQuestion(context, question),
                onDelete: () => _confirmDeleteQuestion(context, question),
                onImagePreview: _showImagePreview,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onReorderQuestions(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    setState(() {
      final question = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, question);
    });

    final questionIds = _questions.map((q) => q.id).toList();
    final success =
        await widget.cubit.reorderQuestions(widget.quiz.id, questionIds);

    if (!success && mounted) {
      _loadQuestions();
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'فشل حفظ الترتيب' : 'Failed to save order'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToAddQuestion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => QuestionEditorScreen(
          quizId: widget.quiz.id,
          cubit: widget.cubit,
          onSaved: _loadQuestions,
        ),
      ),
    );
  }

  void _navigateToEditQuestion(
      BuildContext context, QuizQuestionModel question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => QuestionEditorScreen(
          question: question,
          quizId: widget.quiz.id,
          cubit: widget.cubit,
          onSaved: _loadQuestions,
        ),
      ),
    );
  }

  void _confirmDeleteQuestion(
      BuildContext context, QuizQuestionModel question) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveAlertDialog(
        title: isArabic ? 'حذف السؤال' : 'Delete Question',
        content: isArabic
            ? 'هل أنت متأكد من حذف هذا السؤال؟'
            : 'Are you sure you want to delete this question?',
        confirmText: isArabic ? 'حذف' : 'Delete',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        isDestructive: true,
        onConfirm: () async {
          final success =
              await widget.cubit.deleteQuestion(question.id, widget.quiz.id);
          if (success && ctx.mounted) {
            Navigator.pop(ctx);
            _loadQuestions();
          }
        },
      ),
    );
  }

  void _showBulkImageQuestionsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BulkImageQuestionsScreen(
          quizId: widget.quiz.id,
          cubit: widget.cubit,
          onSaved: _loadQuestions,
        ),
      ),
    );
  }

  void _showAiImportDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AiImportQuestionsDialog(
        quizId: widget.quiz.id,
        quizTitle: isArabic ? widget.quiz.titleAr : widget.quiz.titleEn,
        cubit: widget.cubit,
        onImported: _loadQuestions,
      ),
    );
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
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
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
