import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/shared_widgets/responsive_dialog.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/routing/app_router.dart';
import '../../cubit/instructor_quizzes_cubit.dart';

/// Instructor Quizzes Content
class InstructorQuizzesContent extends StatefulWidget {
  const InstructorQuizzesContent({super.key});

  @override
  State<InstructorQuizzesContent> createState() =>
      _InstructorQuizzesContentState();
}

class _InstructorQuizzesContentState extends State<InstructorQuizzesContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InstructorQuizzesCubit>().loadQuizzes(refresh: true);
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
      context.read<InstructorQuizzesCubit>().loadMoreQuizzes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<InstructorQuizzesCubit, InstructorQuizzesState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic),
            Expanded(child: _buildQuizzesList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, InstructorQuizzesState state, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            isArabic ? 'الاختبارات' : 'Quizzes',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${state.quizzes.length} ${isArabic ? 'اختبار' : 'quizzes'}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          SolidActionButton(
            icon: Icons.add,
            label: isArabic ? 'اختبار جديد' : 'New Quiz',
            color: AppColors.primary,
            onPressed: () => _showCreateQuizDialog(context, isArabic),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateQuizDialog(
      BuildContext context, bool isArabic) async {
    final created = await AppRouter.goToCreateQuiz<bool>(
      context,
      cubit: context.read<InstructorQuizzesCubit>(),
    );
    if (created == true && context.mounted) {
      await context.read<InstructorQuizzesCubit>().loadQuizzes(refresh: true);
    }
  }

  Widget _buildQuizzesList(
      BuildContext context, InstructorQuizzesState state, bool isArabic) {
    if (state.isLoading && state.quizzes.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: const LoadingSkeleton(width: double.infinity, height: 120),
        ),
      );
    }

    if (state.quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد اختبارات' : 'No quizzes found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'أنشئ اختبارات من خلال محرر الكورس'
                  : 'Create quizzes through the course editor',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<InstructorQuizzesCubit>().loadQuizzes(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.quizzes.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.quizzes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _QuizListItem(
            quiz: state.quizzes[index],
            isArabic: isArabic,
            onEdit: () =>
                _showQuizEditor(context, state.quizzes[index], isArabic),
            onManageQuestions: () =>
                _showQuestionsDialog(context, state.quizzes[index], isArabic),
            onViewAttempts: () =>
                _showAttemptsDialog(context, state.quizzes[index], isArabic),
            onDelete: () =>
                _confirmDelete(context, state.quizzes[index], isArabic),
            onPublishChanged: (value) => context
                .read<InstructorQuizzesCubit>()
                .toggleQuizPublished(state.quizzes[index].id, value),
          );
        },
      ),
    );
  }

  void _showQuizEditor(
      BuildContext context, InstructorQuizModel quiz, bool isArabic) {
    AppRouter.goToQuizEditor(
      context,
      quizId: quiz.id,
      quiz: quiz,
      onSave: (data) async {
        return await context.read<InstructorQuizzesCubit>().updateQuiz(
              quizId: quiz.id,
              titleAr: data['title_ar'],
              titleEn: data['title_en'],
              passingScore: data['passing_score'],
              timeLimitMinutes: data['time_limit_minutes'],
              shuffleQuestions: data['shuffle_questions'],
              shuffleAnswers: data['shuffle_answers'],
              showCorrectAnswers: data['show_correct_answers'],
              availableFrom: data['available_from'] as DateTime?,
              availableUntil: data['available_until'] as DateTime?,
              clearAvailableFrom: data['clear_available_from'] == true,
              clearAvailableUntil: data['clear_available_until'] == true,
            );
      },
    );
  }

  void _showQuestionsDialog(
      BuildContext context, InstructorQuizModel quiz, bool isArabic) {
    AppRouter.goToManageQuizQuestions(
      context,
      quizId: quiz.id,
      quiz: quiz,
      cubit: context.read<InstructorQuizzesCubit>(),
    );
  }

  void _showAttemptsDialog(
      BuildContext context, InstructorQuizModel quiz, bool isArabic) async {
    // Show loading
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch attempts
    final attempts =
        await context.read<InstructorQuizzesCubit>().getQuizAttempts(quiz.id);

    // Close loading
    if (context.mounted) Navigator.pop(context);

    // Navigate to full screen instead of dialog
    if (context.mounted) {
      AppRouter.goToQuizAttempts(
        context,
        quizId: quiz.id,
        quizTitle: isArabic ? quiz.titleAr : quiz.titleEn,
        attempts: attempts,
      );
    }
  }

  void _confirmDelete(
      BuildContext context, InstructorQuizModel quiz, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveAlertDialog(
        title: isArabic ? 'حذف الاختبار' : 'Delete Quiz',
        content: isArabic
            ? 'هل أنت متأكد من حذف هذا الاختبار؟ سيتم حذف جميع الأسئلة والمحاولات.'
            : 'Are you sure you want to delete this quiz? All questions and attempts will be deleted.',
        confirmText: isArabic ? 'حذف' : 'Delete',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        isDestructive: true,
        onConfirm: () {
          context.read<InstructorQuizzesCubit>().deleteQuiz(quiz.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Quiz List Item
class _QuizListItem extends StatelessWidget {
  final InstructorQuizModel quiz;
  final bool isArabic;
  final VoidCallback onEdit;
  final VoidCallback onManageQuestions;
  final VoidCallback onViewAttempts;
  final VoidCallback onDelete;
  final ValueChanged<bool> onPublishChanged;

  const _QuizListItem({
    required this.quiz,
    required this.isArabic,
    required this.onEdit,
    required this.onManageQuestions,
    required this.onViewAttempts,
    required this.onDelete,
    required this.onPublishChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? quiz.titleAr : quiz.titleEn,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? (quiz.courseTitleAr ?? '')
                          : (quiz.courseTitleEn ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quiz.isPublished
                        ? (isArabic ? 'منشور' : 'Published')
                        : (isArabic ? 'غير منشور' : 'Unpublished'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: quiz.isPublished
                          ? AppColors.success
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                  ),
                  Switch(
                    value: quiz.isPublished,
                    activeThumbColor: AppColors.success,
                    onChanged: onPublishChanged,
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'questions':
                      onManageQuestions();
                      break;
                    case 'responses':
                      onViewAttempts();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(isArabic ? 'تعديل' : 'Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'questions',
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(isArabic ? 'الأسئلة' : 'Questions'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'responses',
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_turned_in_outlined,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(isArabic ? 'عرض الردود' : 'View Responses'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(isArabic ? 'حذف' : 'Delete',
                            style: const TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.help_outline,
                label:
                    '${quiz.questionsCount} ${isArabic ? 'سؤال' : 'questions'}',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.check_circle_outline,
                label:
                    '${quiz.passingScore}% ${isArabic ? 'للنجاح' : 'to pass'}',
                isDark: isDark,
              ),
              if (quiz.timeLimitMinutes != null) ...[
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.timer_outlined,
                  label:
                      '${quiz.timeLimitMinutes} ${isArabic ? 'دقيقة' : 'min'}',
                  isDark: isDark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.people_outline,
                label:
                    '${quiz.attemptsCount} ${isArabic ? 'محاولة' : 'attempts'}',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.analytics_outlined,
                label:
                    '${quiz.averageScore.toStringAsFixed(1)}% ${isArabic ? 'متوسط' : 'avg'}',
                isDark: isDark,
                color: quiz.averageScore >= quiz.passingScore
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ??
            (isDark ? AppColors.surfaceDark : AppColors.grey100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ??
                (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ??
                  (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ),
        ],
      ),
    );
  }
}
