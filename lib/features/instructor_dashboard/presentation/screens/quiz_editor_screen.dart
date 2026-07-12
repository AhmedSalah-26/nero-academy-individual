import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../cubit/instructor_quizzes_cubit.dart';
import '../widgets/instructor_quizzes/quiz_form_widgets.dart';

/// Quiz Editor Screen - Full page for editing quiz settings
class QuizEditorScreen extends StatefulWidget {
  final InstructorQuizModel? quiz;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const QuizEditorScreen({
    super.key,
    this.quiz,
    required this.onSave,
  });

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleArController;
  late TextEditingController _titleEnController;
  late TextEditingController _passingScoreController;
  late TextEditingController _timeLimitController;

  bool _isLoading = false;
  bool _shuffleQuestions = false;
  bool _shuffleAnswers = false;
  bool _showCorrectAnswers = true;
  DateTime? _availableFrom;
  DateTime? _availableUntil;

  @override
  void initState() {
    super.initState();
    _titleArController =
        TextEditingController(text: widget.quiz?.titleAr ?? '');
    _titleEnController =
        TextEditingController(text: widget.quiz?.titleEn ?? '');
    _passingScoreController = TextEditingController(
      text: widget.quiz?.passingScore.toString() ?? '70',
    );
    _timeLimitController = TextEditingController(
      text: widget.quiz?.timeLimitMinutes?.toString() ?? '',
    );
    _shuffleQuestions = widget.quiz?.shuffleQuestions ?? false;
    _shuffleAnswers = widget.quiz?.shuffleAnswers ?? false;
    _showCorrectAnswers = widget.quiz?.showCorrectAnswers ?? true;
    _availableFrom = widget.quiz?.availableFrom?.toLocal();
    _availableUntil = widget.quiz?.availableUntil?.toLocal();
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _passingScoreController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'تعديل الاختبار' : 'Edit Quiz'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(isArabic, isDark),
              const SizedBox(height: 20),
              _buildTitleSection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildSettingsSection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildAvailabilitySection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildOptionsSection(isArabic, isDark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isArabic, isDark),
    );
  }

  Widget _buildInfoCard(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic
                  ? 'قم بتعديل إعدادات الاختبار. التغييرات ستؤثر على المحاولات الجديدة فقط.'
                  : 'Edit quiz settings. Changes will only affect new attempts.',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.title, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'عنوان الاختبار' : 'Quiz Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleArController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
              hintText: isArabic
                  ? 'أدخل عنوان الاختبار بالعربية'
                  : 'Enter quiz title in Arabic',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.language),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return isArabic ? 'مطلوب' : 'Required';
              }
              if (value.length < 3) {
                return isArabic ? 'على الأقل 3 أحرف' : 'At least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleEnController,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
              hintText: isArabic
                  ? 'أدخل عنوان الاختبار بالإنجليزية'
                  : 'Enter quiz title in English',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.language),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return isArabic ? 'مطلوب' : 'Required';
              }
              if (value.length < 3) {
                return isArabic ? 'على الأقل 3 أحرف' : 'At least 3 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'إعدادات الاختبار' : 'Quiz Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'درجة النجاح (%)' : 'Passing Score (%)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passingScoreController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '70',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isArabic ? 'مطلوب' : 'Required';
                        }
                        final score = int.tryParse(value);
                        if (score == null || score < 0 || score > 100) {
                          return isArabic
                              ? 'يجب أن يكون بين 0-100'
                              : 'Must be 0-100';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'الوقت المحدد (دقيقة)'
                          : 'Time Limit (minutes)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _timeLimitController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: isArabic ? 'بدون حد' : 'No limit',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceDark : AppColors.grey50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'اترك الوقت فارغاً لعدم تحديد وقت للاختبار'
                        : 'Leave time limit empty for unlimited time',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isArabic, bool isDark) {
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
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => AppRouter.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isArabic ? 'حفظ التغييرات' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection(bool isArabic, bool isDark) {
    return QuizSectionCard(
      icon: Icons.tune,
      iconColor: AppColors.primary,
      title: isArabic ? 'خيارات إضافية' : 'Additional Options',
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        children: [
          QuizOptionChip(
            label: isArabic ? 'خلط الأسئلة' : 'Shuffle Questions',
            icon: Icons.shuffle,
            selected: _shuffleQuestions,
            onChanged: (v) => setState(() => _shuffleQuestions = v),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          QuizOptionChip(
            label: isArabic ? 'خلط الإجابات' : 'Shuffle Answers',
            icon: Icons.shuffle,
            selected: _shuffleAnswers,
            onChanged: (v) => setState(() => _shuffleAnswers = v),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          QuizOptionChip(
            label: isArabic ? 'إظهار الإجابات الصحيحة' : 'Show Correct Answers',
            icon: Icons.visibility,
            selected: _showCorrectAnswers,
            onChanged: (v) => setState(() => _showCorrectAnswers = v),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection(bool isArabic, bool isDark) {
    final hasInvalidWindow = _availableFrom != null &&
        _availableUntil != null &&
        !_availableUntil!.isAfter(_availableFrom!);

    return QuizSectionCard(
      icon: Icons.event_available_outlined,
      iconColor: AppColors.info,
      title: isArabic ? 'وقت إتاحة الاختبار' : 'Quiz Availability',
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        children: [
          _DateTimeTile(
            label: isArabic ? 'يبدأ من' : 'Starts from',
            value: _availableFrom,
            isArabic: isArabic,
            onPick: () async {
              final picked = await _pickDateTime(_availableFrom);
              if (picked != null) setState(() => _availableFrom = picked);
            },
            onClear: _availableFrom == null
                ? null
                : () => setState(() => _availableFrom = null),
          ),
          const SizedBox(height: 12),
          _DateTimeTile(
            label: isArabic ? 'ينتهي في' : 'Ends at',
            value: _availableUntil,
            isArabic: isArabic,
            onPick: () async {
              final picked = await _pickDateTime(_availableUntil);
              if (picked != null) setState(() => _availableUntil = picked);
            },
            onClear: _availableUntil == null
                ? null
                : () => setState(() => _availableUntil = null),
          ),
          if (hasInvalidWindow) ...[
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'وقت الانتهاء يجب أن يكون بعد وقت البداية'
                  : 'End time must be after start time',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? initialValue) async {
    final now = DateTime.now();
    final initial = initialValue ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_availableFrom != null &&
        _availableUntil != null &&
        !_availableUntil!.isAfter(_availableFrom!)) {
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'title_ar': _titleArController.text,
      'title_en': _titleEnController.text,
      'passing_score': int.parse(_passingScoreController.text),
      'time_limit_minutes': _timeLimitController.text.isEmpty
          ? null
          : int.parse(_timeLimitController.text),
      'shuffle_questions': _shuffleQuestions,
      'shuffle_answers': _shuffleAnswers,
      'show_correct_answers': _showCorrectAnswers,
      'available_from': _availableFrom,
      'available_until': _availableUntil,
      'clear_available_from': _availableFrom == null,
      'clear_available_until': _availableUntil == null,
    };

    final success = await widget.onSave(data);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        AppRouter.pop(context);
      }
    }
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.isArabic,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool isArabic;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? (isArabic ? 'غير محدد' : 'Not set')
        : _formatValue(context, value!);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.schedule_rounded),
          suffixIcon: onClear == null
              ? const Icon(Icons.edit_calendar_outlined)
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
        ),
        child: Text(text),
      ),
    );
  }

  String _formatValue(BuildContext context, DateTime dateTime) {
    final local = dateTime.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '$date - $time';
  }
}
