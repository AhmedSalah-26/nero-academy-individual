import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/animations/widgets/feedback/animated_snackbar.dart';
import '../cubit/instructor_quizzes_cubit.dart';
import '../widgets/instructor_quizzes/quiz_form_widgets.dart';

/// Create Quiz Screen - Full page for creating a new quiz
class CreateQuizScreen extends StatefulWidget {
  final InstructorQuizzesCubit cubit;

  const CreateQuizScreen({
    super.key,
    required this.cubit,
  });

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleArController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _descArController = TextEditingController();
  final _descEnController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '70');
  final _timeLimitController = TextEditingController();
  final _maxAttemptsController = TextEditingController();

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _lessons = [];
  String? _selectedCourseId;
  String? _selectedLessonId;

  bool _isLoading = false;
  bool _isLoadingCourses = true;
  bool _isLoadingLessons = false;
  bool _isCourseLevelQuiz = true;
  bool _shuffleQuestions = false;
  bool _shuffleAnswers = false;
  bool _showCorrectAnswers = true;
  DateTime? _availableFrom;
  DateTime? _availableUntil;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _passingScoreController.dispose();
    _timeLimitController.dispose();
    _maxAttemptsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    AppLogger.i('📝 [CreateQuizScreen] Loading courses...');
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('courses')
          .select('id, title_ar, title_en')
          .eq('instructor_id', userId)
          .order('created_at', ascending: false);

      AppLogger.d(
          '📝 [CreateQuizScreen] Loaded ${(response as List).length} courses');
      setState(() {
        _courses = List<Map<String, dynamic>>.from(response);
        _isLoadingCourses = false;
      });
    } catch (e) {
      AppLogger.e('📝 [CreateQuizScreen] Error loading courses: $e');
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadLessons(String courseId) async {
    setState(() {
      _isLoadingLessons = true;
      _selectedLessonId = null;
      _lessons = [];
    });

    try {
      final response = await Supabase.instance.client
          .from('lessons')
          .select('id, title_ar, title_en, sort_order')
          .eq('course_id', courseId)
          .order('sort_order');

      if (!mounted) return;
      setState(() {
        _lessons = List<Map<String, dynamic>>.from(response);
        _isLoadingLessons = false;
      });
    } catch (e) {
      AppLogger.e('📝 [CreateQuizScreen] Error loading lessons: $e');
      if (mounted) {
        setState(() => _isLoadingLessons = false);
      }
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
        title: Text(isArabic ? 'إنشاء اختبار جديد' : 'Create New Quiz'),
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
              QuizInfoCard(
                icon: Icons.quiz,
                title: isArabic ? 'إنشاء اختبار جديد' : 'Create New Quiz',
                subtitle: isArabic
                    ? 'املأ التفاصيل أدناه لإنشاء اختبار جديد. يمكنك إضافة الأسئلة بعد الإنشاء.'
                    : 'Fill in the details below to create a new quiz. You can add questions after creation.',
                color: AppColors.primary,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildCourseSection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildQuizScopeSection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildTitleSection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildDescriptionSection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildSettingsSection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildAvailabilitySection(isArabic, isDark),
              const SizedBox(height: 20),
              _buildOptionsSection(isArabic, isDark),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: QuizFormBottomBar(
        isLoading: _isLoading,
        isArabic: isArabic,
        isDark: isDark,
        submitLabel: isArabic ? 'إنشاء الاختبار' : 'Create Quiz',
        submitIcon: Icons.add,
        onCancel: () => AppRouter.pop(context),
        onSubmit: _createQuiz,
      ),
    );
  }

  Widget _buildCourseSection(bool isArabic, bool isDark) {
    return QuizSectionCard(
      icon: Icons.school,
      iconColor: AppColors.primary,
      title: isArabic ? 'اختر الكورس' : 'Select Course',
      isRequired: true,
      isArabic: isArabic,
      isDark: isDark,
      child: _isLoadingCourses
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          : DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: isArabic ? 'اختر الكورس' : 'Select course',
                prefixIcon: const Icon(Icons.book_outlined),
              ),
              items: _courses.map((course) {
                return DropdownMenuItem<String>(
                  value: course['id'] as String,
                  child: Text(
                    isArabic
                        ? course['title_ar'] ?? ''
                        : course['title_en'] ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourseId = value;
                  _selectedLessonId = null;
                  _lessons = [];
                });
                if (value != null) {
                  _loadLessons(value);
                }
              },
              validator: (value) {
                if (value == null) {
                  return isArabic
                      ? 'يرجى اختيار الكورس'
                      : 'Please select a course';
                }
                return null;
              },
            ),
    );
  }

  Widget _buildQuizScopeSection(bool isArabic, bool isDark) {
    return QuizSectionCard(
      icon: Icons.account_tree_outlined,
      iconColor: AppColors.info,
      title: isArabic ? 'نطاق الاختبار' : 'Quiz Scope',
      isRequired: true,
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: true,
                icon: const Icon(Icons.school_outlined),
                label: Text(isArabic ? 'اختبار شامل' : 'Course quiz'),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(isArabic ? 'اختبار درس' : 'Lesson quiz'),
              ),
            ],
            selected: {_isCourseLevelQuiz},
            onSelectionChanged: (selection) {
              setState(() {
                _isCourseLevelQuiz = selection.first;
                if (_isCourseLevelQuiz) {
                  _selectedLessonId = null;
                }
              });
              if (!_isCourseLevelQuiz &&
                  _selectedCourseId != null &&
                  _lessons.isEmpty &&
                  !_isLoadingLessons) {
                _loadLessons(_selectedCourseId!);
              }
            },
          ),
          if (!_isCourseLevelQuiz) ...[
            const SizedBox(height: 16),
            if (_selectedCourseId == null)
              Text(
                isArabic
                    ? 'اختر الكورس أولاً لعرض الدروس'
                    : 'Select a course first to load lessons',
                style: TextStyle(
                  color: isDark ? AppColors.textMutedDark : AppColors.grey600,
                ),
              )
            else if (_isLoadingLessons)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedLessonId,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: isArabic ? 'اختر الدرس' : 'Select lesson',
                  prefixIcon: const Icon(Icons.play_lesson_outlined),
                ),
                items: _lessons.map((lesson) {
                  return DropdownMenuItem<String>(
                    value: lesson['id'] as String,
                    child: Text(
                      isArabic
                          ? lesson['title_ar'] ?? ''
                          : lesson['title_en'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedLessonId = value),
                validator: (value) {
                  if (!_isCourseLevelQuiz && value == null) {
                    return isArabic
                        ? 'يرجى اختيار الدرس'
                        : 'Please select a lesson';
                  }
                  return null;
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isArabic, bool isDark) {
    return QuizSectionCard(
      icon: Icons.title,
      iconColor: AppColors.success,
      title: isArabic ? 'عنوان الاختبار' : 'Quiz Title',
      isRequired: true,
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        children: [
          TextFormField(
            controller: _titleArController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
              hintText: isArabic
                  ? 'مثال: اختبار الوحدة الأولى'
                  : 'Example: Unit 1 Quiz',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.language),
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) {
                return isArabic ? 'مطلوب' : 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleEnController,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
              hintText:
                  isArabic ? 'Example: Unit 1 Quiz' : 'Example: Unit 1 Quiz',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.language),
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) {
                return isArabic ? 'مطلوب' : 'Required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isArabic, bool isDark) {
    return QuizSectionCard(
      icon: Icons.description,
      iconColor: AppColors.info,
      title: isArabic ? 'الوصف (اختياري)' : 'Description (Optional)',
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        children: [
          TextFormField(
            controller: _descArController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isArabic ? 'الوصف (عربي)' : 'Description (Arabic)',
              hintText: isArabic
                  ? 'وصف مختصر عن محتوى الاختبار...'
                  : 'Brief description of quiz content...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descEnController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isArabic ? 'الوصف (إنجليزي)' : 'Description (English)',
              hintText: isArabic
                  ? 'Brief description of quiz content...'
                  : 'Brief description of quiz content...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isArabic, bool isDark) {
    return QuizSectionCard(
      icon: Icons.settings,
      iconColor: AppColors.warning,
      title: isArabic ? 'إعدادات الاختبار' : 'Quiz Settings',
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        children: [
          QuizSettingField(
            label: isArabic ? 'درجة النجاح (%)' : 'Passing Score (%)',
            controller: _passingScoreController,
            icon: Icons.check_circle_outline,
            isRequired: true,
            isArabic: isArabic,
            isPercentage: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return isArabic ? 'مطلوب' : 'Required';
              }
              final score = int.tryParse(value);
              if (score == null || score < 0 || score > 100) {
                return '0-100';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QuizSettingField(
                  label: isArabic ? 'الوقت (دقيقة)' : 'Time Limit (min)',
                  controller: _timeLimitController,
                  icon: Icons.timer_outlined,
                  isRequired: false,
                  isArabic: isArabic,
                  hintText: isArabic ? 'بدون حد' : 'No limit',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: QuizSettingField(
                  label: isArabic ? 'عدد المحاولات' : 'Max Attempts',
                  controller: _maxAttemptsController,
                  icon: Icons.repeat,
                  isRequired: false,
                  isArabic: isArabic,
                  hintText: isArabic ? 'غير محدود' : 'Unlimited',
                ),
              ),
            ],
          ),
        ],
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

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_availableFrom != null &&
        _availableUntil != null &&
        !_availableUntil!.isAfter(_availableFrom!)) {
      return;
    }

    AppLogger.i('📝 [CreateQuizScreen] Creating quiz...');
    setState(() => _isLoading = true);

    try {
      final success = await widget.cubit.createQuiz(
        courseId: _selectedCourseId!,
        lessonId: _isCourseLevelQuiz ? null : _selectedLessonId,
        titleAr: _titleArController.text,
        titleEn: _titleEnController.text,
        descriptionAr:
            _descArController.text.isEmpty ? null : _descArController.text,
        descriptionEn:
            _descEnController.text.isEmpty ? null : _descEnController.text,
        passingScore: int.parse(_passingScoreController.text),
        timeLimitMinutes: _timeLimitController.text.isEmpty
            ? null
            : int.parse(_timeLimitController.text),
        maxAttempts: _maxAttemptsController.text.isEmpty
            ? null
            : int.parse(_maxAttemptsController.text),
        availableFrom: _availableFrom,
        availableUntil: _availableUntil,
        shuffleQuestions: _shuffleQuestions,
        shuffleAnswers: _shuffleAnswers,
        showCorrectAnswers: _showCorrectAnswers,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          AppLogger.success('📝 [CreateQuizScreen] Quiz created successfully');
          AppRouter.pop(context);
          AnimatedSnackbar.showSuccess(
            context: context,
            message: Localizations.localeOf(context).languageCode == 'ar'
                ? 'تم إنشاء الاختبار بنجاح - يمكنك الآن إضافة الأسئلة'
                : 'Quiz created successfully - you can now add questions',
          );
        }
      }
    } catch (e) {
      AppLogger.e('📝 [CreateQuizScreen] Error creating quiz: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        AnimatedSnackbar.showError(
          context: context,
          message: e.toString(),
        );
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
