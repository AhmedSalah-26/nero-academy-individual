import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/error_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/admin_qa_cubit.dart';

/// Admin Q&A Content
class AdminQAContent extends StatefulWidget {
  const AdminQAContent({super.key});

  @override
  State<AdminQAContent> createState() => _AdminQAContentState();
}

class _AdminQAContentState extends State<AdminQAContent> {
  @override
  void initState() {
    super.initState();
    context.read<AdminQACubit>().loadQuestions(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AdminQACubit, AdminQAState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic, isDark),
            Expanded(child: _buildBody(context, state, isArabic, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, AdminQAState state, bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DashboardSearchBar(
              hintText: 'Search questions...',
              hintTextAr: 'بحث في الأسئلة...',
              onSearch: (q) => context
                  .read<AdminQACubit>()
                  .loadQuestions(search: q.isEmpty ? null : q, refresh: true),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isArabic
                ? '${state.questions.length} سؤال'
                : '${state.questions.length} questions',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AdminQAState state, bool isArabic, bool isDark) {
    if (state.status == AdminQAStatus.loading && state.questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AdminQAStatus.error) {
      return ErrorState(
        type: ErrorType.server,
        message: state.errorMessage,
        onRetry: () =>
            context.read<AdminQACubit>().loadQuestions(refresh: true),
      );
    }

    if (state.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined,
                size: 48,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا توجد أسئلة' : 'No questions found'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = state.questions[index];
        return _buildQuestionCard(context, question, isArabic, isDark);
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context, Map<String, dynamic> question,
      bool isArabic, bool isDark) {
    final userName = question['user']?['name'] as String? ?? 'Unknown';
    final courseName =
        question['course']?['title_ar'] as String? ?? 'Unknown Course';
    final title = question['title'] as String? ?? '';
    final content = question['content'] as String? ?? '';
    final isAnswered = question['is_answered'] == true;
    final isHidden = question['is_hidden'] == true;
    final questionId = question['id'] as String;
    final answers = question['qa_answers'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHidden
            ? (isDark
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.errorLight)
            : (isDark ? AppColors.cardDark : AppColors.white),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(userName[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(courseName,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAnswered
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAnswered
                      ? (isArabic ? 'تم الرد' : 'Answered')
                      : (isArabic ? 'بانتظار' : 'Pending'),
                  style: TextStyle(
                      fontSize: 11,
                      color: isAnswered ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (isHidden) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isArabic ? 'مخفي' : 'Hidden',
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (title.isNotEmpty)
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight)),
          ],
          if (answers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.grey50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply,
                      size: 16,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
                  const SizedBox(width: 8),
                  Text(
                    '${answers.length} ${isArabic ? 'إجابة' : 'answer(s)'}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  if (isHidden) {
                    context.read<AdminQACubit>().unhideQuestion(questionId);
                  } else {
                    context.read<AdminQACubit>().hideQuestion(questionId);
                  }
                },
                icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off,
                    size: 18),
                label: Text(isHidden
                    ? (isArabic ? 'إظهار' : 'Show')
                    : (isArabic ? 'إخفاء' : 'Hide')),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, questionId, isArabic),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                label: Text(isArabic ? 'حذف' : 'Delete',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String questionId, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(isArabic
            ? 'هل أنت متأكد من حذف هذا السؤال وجميع إجاباته؟'
            : 'Are you sure you want to delete this question and all its answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminQACubit>().deleteQuestion(questionId);
            },
            child: Text(isArabic ? 'حذف' : 'Delete',
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
