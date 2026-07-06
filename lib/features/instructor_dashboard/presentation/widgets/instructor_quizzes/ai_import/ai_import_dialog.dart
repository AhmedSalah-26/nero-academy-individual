import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../generated/locale_keys.g.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_quizzes_cubit.dart';
import 'ai_import_models.dart';
import 'ai_import_prompt_tab.dart';
import 'ai_import_preview_tab.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AI Import Dialog  — Dialog manager that integrates prompt and preview tabs
/// ─────────────────────────────────────────────────────────────────────────────
class AiImportQuestionsDialog extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final InstructorQuizzesCubit cubit;
  final VoidCallback onImported;

  const AiImportQuestionsDialog({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.cubit,
    required this.onImported,
  });

  @override
  State<AiImportQuestionsDialog> createState() =>
      _AiImportQuestionsDialogState();
}

class _AiImportQuestionsDialogState extends State<AiImportQuestionsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _jsonController = TextEditingController();

  List<AiPreviewQuestion> _parsedQuestions = [];
  String? _parseError;
  bool _isSaving = false;
  bool _replaceExistingQuestions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  // ─── Parse JSON ───────────────────────────────────────────────────────────
  void _parseJson() {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parseError = LocaleKeys.course_editor_ai_import_err_empty.tr();
        _parsedQuestions = [];
      });
      return;
    }

    try {
      // Extract JSON array if wrapped in ```json ... ```
      String cleaned = text;
      final codeBlockMatch =
          RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
      if (codeBlockMatch != null) {
        cleaned = codeBlockMatch.group(1)!.trim();
      }

      final dynamic decoded = json.decode(cleaned);
      if (decoded is! List) {
        setState(() {
          _parseError = LocaleKeys.course_editor_ai_import_err_not_array.tr();
          _parsedQuestions = [];
        });
        return;
      }

      final questions = <AiPreviewQuestion>[];
      for (final item in decoded) {
        final q = item as Map<String, dynamic>;
        final options = (q['options'] as List? ?? [])
            .map((o) => AiPreviewOption(
                  textAr:
                      (o as Map<String, dynamic>)['text_ar'] as String? ?? '',
                  textEn: o['text_en'] as String? ?? '',
                  isCorrect: o['is_correct'] as bool? ?? false,
                ))
            .toList();

        questions.add(AiPreviewQuestion(
          questionAr: q['question_ar'] as String? ?? '',
          questionEn: q['question_en'] as String? ?? '',
          type: q['type'] as String? ?? 'single',
          points: (q['points'] as num?)?.toInt() ?? 1,
          options: options,
          correctAnswer: q['correct_answer'] as String?,
        ));
      }

      if (questions.isEmpty) {
        setState(() {
          _parseError =
              LocaleKeys.course_editor_ai_import_err_no_questions.tr();
          _parsedQuestions = [];
        });
        return;
      }

      setState(() {
        _parsedQuestions = questions;
        _parseError = null;
      });

      _tabController.animateTo(1);
    } catch (e) {
      setState(() {
        _parseError = LocaleKeys.course_editor_ai_import_err_invalid
            .tr(namedArgs: {'msg': e.toString().split('\n').first});
        _parsedQuestions = [];
      });
    }
  }

  // ─── Save All Questions ───────────────────────────────────────────────────
  Future<void> _importQuestions() async {
    if (_parsedQuestions.isEmpty) return;
    setState(() => _isSaving = true);

    final questions = _parsedQuestions.map((q) {
      final options = q.options
          .asMap()
          .entries
          .map((e) => {
                'text_ar': e.value.textAr,
                'text_en': e.value.textEn,
                'is_correct': e.value.isCorrect,
                'sort_order': e.key,
              })
          .toList();

      return {
        'question_ar': q.questionAr,
        'question_en': q.questionEn,
        'question_type': q.type,
        'points': q.points,
        'options': options,
        'correct_answer': q.correctAnswer,
      };
    }).toList();

    final success = await widget.cubit.addQuestionsBulk(
      quizId: widget.quizId,
      questions: questions,
      replaceExisting: _replaceExistingQuestions,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onImported();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.course_editor_ai_import_success.tr(
                namedArgs: {
                  'count': '${_parsedQuestions.length}',
                  'total': '${_parsedQuestions.length}'
                })),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cubit.state.errorMessage ??
                'Failed to import questions'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 600,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AiImportPromptTab(isDark: isDark),
                  AiImportPreviewTab(
                    jsonController: _jsonController,
                    parsedQuestions: _parsedQuestions,
                    parseError: _parseError,
                    onParseTriggered: _parseJson,
                    isDark: isDark,
                    onChanged: (_) {
                      if (_parsedQuestions.isNotEmpty || _parseError != null) {
                        setState(() {
                          _parsedQuestions = [];
                          _parseError = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.25 : 0.12),
            const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.15 : 0.06),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF7C3AED), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.course_editor_ai_import_title.tr(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  widget.quizTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        border: Border(
          bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF7C3AED),
        unselectedLabelColor:
            isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        indicatorColor: const Color(0xFF7C3AED),
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.content_copy_rounded, size: 15),
                const SizedBox(width: 6),
                Text(LocaleKeys.course_editor_ai_import_tab_prompt.tr()),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.preview_rounded, size: 15),
                const SizedBox(width: 6),
                Text(LocaleKeys.course_editor_ai_import_tab_paste.tr()),
                if (_parsedQuestions.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_parsedQuestions.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
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

  Widget _buildFooter(bool isDark) {
    if (_parsedQuestions.isEmpty) return const SizedBox.shrink();

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: _replaceExistingQuestions,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _replaceExistingQuestions = value ?? true;
                      });
                    },
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'امسح الأسئلة الحالية قبل إضافة JSON',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              subtitle: Text(
                'لو الإضافة فشلت سيتم إرجاع الأسئلة القديمة تلقائيا',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _importQuestions,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_task_rounded, size: 20),
                label: Text(
                  _isSaving
                      ? LocaleKeys.course_editor_ai_import_adding.tr()
                      : LocaleKeys.course_editor_ai_import_add_btn
                          .tr(namedArgs: {'count': '${_parsedQuestions.length}'}),
                  style:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
