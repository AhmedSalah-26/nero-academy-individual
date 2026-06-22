import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';

/// Quiz Preview Screen - Full page for previewing quiz as a student would see it
class QuizPreviewScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final List<Map<String, dynamic>> questions;
  final int? timeLimit;

  const QuizPreviewScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.questions,
    this.timeLimit,
  });

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, dynamic> _selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuestion = widget.questions.isNotEmpty
        ? widget.questions[_currentQuestionIndex]
        : null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'معاينة الاختبار' : 'Quiz Preview',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              widget.quizTitle,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        actions: [
          if (widget.timeLimit != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.timeLimit} ${isArabic ? 'دقيقة' : 'min'}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: widget.questions.isEmpty
                ? _buildEmptyState(isArabic, isDark)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildQuestion(currentQuestion!, isArabic, isDark),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(isArabic, isDark),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: widget.questions.isEmpty
          ? 0
          : (_currentQuestionIndex + 1) / widget.questions.length,
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 4,
    );
  }

  Widget _buildEmptyState(bool isArabic, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا توجد أسئلة' : 'No questions yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(
      Map<String, dynamic> question, bool isArabic, bool isDark) {
    final type = question['type'] as String? ?? 'single_choice';
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final points = question['points'] as int? ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question header card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getTypeColor(type).withValues(alpha: 0.1),
                _getTypeColor(type).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTypeColor(type).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeLabel(type, isArabic),
                      style: TextStyle(
                        color: _getTypeColor(type),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isArabic ? 'السؤال' : 'Question'} ${_currentQuestionIndex + 1} ${isArabic ? 'من' : 'of'} ${widget.questions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$points ${isArabic ? 'نقطة' : 'pt${points > 1 ? 's' : ''}'}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Question text
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Text(
            questionText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Options based on type
        if (type == 'single_choice' || type == 'multiple_choice')
          _buildChoiceOptions(options, type, isArabic, isDark)
        else if (type == 'true_false')
          _buildTrueFalseOptions(isArabic, isDark)
        else if (type == 'short_answer')
          _buildShortAnswerField(isArabic, isDark),
      ],
    );
  }

  Widget _buildChoiceOptions(
    List<dynamic> options,
    String type,
    bool isArabic,
    bool isDark,
  ) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value as Map<String, dynamic>;
        final text = option['text'] as String? ?? '';
        final isSelected = type == 'single_choice'
            ? _selectedAnswers[_currentQuestionIndex] == index
            : (_selectedAnswers[_currentQuestionIndex] as List<int>?)
                    ?.contains(index) ??
                false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                if (type == 'single_choice') {
                  _selectedAnswers[_currentQuestionIndex] = index;
                } else {
                  final current =
                      _selectedAnswers[_currentQuestionIndex] as List<int>? ??
                          [];
                  if (current.contains(index)) {
                    current.remove(index);
                  } else {
                    current.add(index);
                  }
                  _selectedAnswers[_currentQuestionIndex] = current;
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : (isDark ? AppColors.cardDark : AppColors.white),
              ),
              child: Row(
                children: [
                  type == 'single_choice'
                      ? Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        )
                      : Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions(bool isArabic, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildTrueFalseOption(
            true,
            isArabic ? 'صح' : 'True',
            Icons.check_circle_outline,
            AppColors.success,
            isArabic,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTrueFalseOption(
            false,
            isArabic ? 'خطأ' : 'False',
            Icons.cancel_outlined,
            AppColors.error,
            isArabic,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOption(
    bool value,
    String label,
    IconData icon,
    Color color,
    bool isArabic,
    bool isDark,
  ) {
    final isSelected = _selectedAnswers[_currentQuestionIndex] == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAnswers[_currentQuestionIndex] = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : AppColors.white),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: isSelected ? color : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortAnswerField(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        maxLines: 4,
        decoration: InputDecoration(
          hintText:
              isArabic ? 'اكتب إجابتك هنا...' : 'Type your answer here...',
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          _selectedAnswers[_currentQuestionIndex] = value;
        },
      ),
    );
  }

  Widget _buildNavigationBar(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Question counter
            Text(
              '${isArabic ? 'السؤال' : 'Question'} ${_currentQuestionIndex + 1} / ${widget.questions.length}',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Navigation buttons
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
                    },
                    icon: Icon(
                      isArabic
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      size: 18,
                    ),
                    label: Text(isArabic ? 'السابق' : 'Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                const SizedBox(width: 12),
                if (_currentQuestionIndex < widget.questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _currentQuestionIndex++);
                    },
                    icon: Icon(
                      isArabic
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(isArabic ? 'التالي' : 'Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => AppRouter.pop(context),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(isArabic ? 'إنهاء المعاينة' : 'End Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'single_choice':
        return Colors.blue;
      case 'multiple_choice':
        return Colors.blue;
      case 'true_false':
        return Colors.orange;
      case 'short_answer':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'single_choice':
        return Icons.radio_button_checked;
      case 'multiple_choice':
        return Icons.check_box;
      case 'true_false':
        return Icons.toggle_on;
      case 'short_answer':
        return Icons.edit_note;
      default:
        return Icons.help_outline;
    }
  }

  String _getTypeLabel(String type, bool isArabic) {
    switch (type) {
      case 'single_choice':
        return isArabic ? 'اختيار واحد' : 'Single Choice';
      case 'multiple_choice':
        return isArabic ? 'اختيار متعدد' : 'Multiple Choice';
      case 'true_false':
        return isArabic ? 'صح/خطأ' : 'True/False';
      case 'short_answer':
        return isArabic ? 'إجابة قصيرة' : 'Short Answer';
      default:
        return type;
    }
  }
}
