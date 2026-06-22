import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/animations/widgets/feedback/animated_snackbar.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/instructor_quizzes_cubit.dart';
import '../widgets/instructor_quizzes/question_editor_section_widgets.dart';
import '../widgets/instructor_quizzes/quiz_form_widgets.dart';

/// Question Editor Screen - Full page for creating/editing quiz questions.
class QuestionEditorScreen extends StatefulWidget {
  final QuizQuestionModel? question;
  final String quizId;
  final InstructorQuizzesCubit cubit;
  final VoidCallback onSaved;

  const QuestionEditorScreen({
    super.key,
    this.question,
    required this.quizId,
    required this.cubit,
    required this.onSaved,
  });

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  late TextEditingController _questionArController;
  late TextEditingController _questionEnController;

  String _selectedType = 'single';
  List<Map<String, dynamic>> _options = [];
  String? _imageUrl;
  XFile? _selectedImage;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  bool get isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    _questionArController =
        TextEditingController(text: widget.question?.questionAr ?? '');
    _questionEnController =
        TextEditingController(text: widget.question?.questionEn ?? '');
    _selectedType = widget.question?.type ?? 'single';
    _imageUrl = widget.question?.imageUrl;
    _options = widget.question?.options
            .map(
              (o) => {
                'text_ar': o.textAr,
                'text_en': o.textEn,
                'is_correct': o.isCorrect,
              },
            )
            .toList() ??
        [
          {'text_ar': '', 'text_en': '', 'is_correct': false},
          {'text_ar': '', 'text_en': '', 'is_correct': false},
        ];
  }

  @override
  void dispose() {
    _questionArController.dispose();
    _questionEnController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;

    setState(() => _isUploadingImage = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileName =
          'quiz_${widget.quizId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'quiz_questions/$fileName';
      final bytes = await _selectedImage!.readAsBytes();

      await supabase.storage.from('courses').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = supabase.storage.from('courses').getPublicUrl(path);

      setState(() {
        _imageUrl = url;
        _isUploadingImage = false;
      });

      return url;
    } catch (e) {
      AppLogger.e('[QuestionEditor] Image upload error', e);
      setState(() => _isUploadingImage = false);
      if (mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        AnimatedSnackbar.showError(
          context: context,
          message: isArabic ? 'فشل رفع الصورة' : 'Image upload failed',
        );
      }
      return null;
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _selectedImage = null;
    });
  }

  Future<void> _save() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasText = _questionArController.text.isNotEmpty ||
        _questionEnController.text.isNotEmpty;
    final hasImage = _imageUrl != null || _selectedImage != null;

    if (!hasText && !hasImage) {
      AnimatedSnackbar.showError(
        context: context,
        message: isArabic
            ? 'يرجى إدخال نص السؤال أو صورة'
            : 'Please enter question text or image',
      );
      return;
    }

    setState(() => _isSaving = true);

    String? finalImageUrl = _imageUrl;
    if (_selectedImage != null) {
      finalImageUrl = await _uploadImage();
    }

    bool success;
    if (isEditing) {
      success = await widget.cubit.updateQuestion(
        quizId: widget.quizId,
        questionId: widget.question!.id,
        questionAr: _questionArController.text,
        questionEn: _questionEnController.text,
        imageUrl: finalImageUrl,
        removeImage: _imageUrl == null && widget.question?.imageUrl != null,
        type: _selectedType,
        options: _options,
      );
    } else {
      success = await widget.cubit.addQuestion(
        quizId: widget.quizId,
        questionAr: _questionArController.text,
        questionEn: _questionEnController.text,
        imageUrl: finalImageUrl,
        type: _selectedType,
        options: _options,
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      widget.onSaved();
      if (mounted) {
        AppRouter.pop(context);
      }
    } else if (mounted) {
      AnimatedSnackbar.showError(
        context: context,
        message: isArabic ? 'حدث خطأ' : 'An error occurred',
      );
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
        title: Text(
          isEditing
              ? (isArabic ? 'تعديل السؤال' : 'Edit Question')
              : (isArabic ? 'سؤال جديد' : 'New Question'),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuizInfoCard(
              icon: Icons.info_outline,
              title: isArabic ? 'تلميح' : 'Hint',
              subtitle: isArabic
                  ? 'يمكنك إضافة نص السؤال أو صورة أو كليهما. على الأقل واحد مطلوب.'
                  : 'You can add question text, image, or both. At least one is required.',
              color: AppColors.info,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            QuestionEditorImageSection(
              isArabic: isArabic,
              isDark: isDark,
              imageUrl: _imageUrl,
              selectedImage: _selectedImage,
              isUploadingImage: _isUploadingImage,
              onPickImage: _pickImage,
              onRemoveImage: _removeImage,
            ),
            const SizedBox(height: 20),
            QuestionEditorTextSection(
              isArabic: isArabic,
              isDark: isDark,
              questionArController: _questionArController,
              questionEnController: _questionEnController,
            ),
            const SizedBox(height: 20),
            QuestionEditorTypeSection(
              isArabic: isArabic,
              isDark: isDark,
              selectedType: _selectedType,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedType = value;
                  if (value == 'true_false') {
                    _options = [
                      {'text_ar': 'صح', 'text_en': 'True', 'is_correct': true},
                      {
                        'text_ar': 'خطأ',
                        'text_en': 'False',
                        'is_correct': false,
                      },
                    ];
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            QuestionEditorOptionsSection(
              isArabic: isArabic,
              isDark: isDark,
              selectedType: _selectedType,
              options: _options,
              onAddOption: () {
                setState(() {
                  _options.add(
                    {'text_ar': '', 'text_en': '', 'is_correct': false},
                  );
                });
              },
              onReorderOptions: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _options.removeAt(oldIndex);
                  _options.insert(newIndex, item);
                });
              },
              onCorrectChanged: (index, isCorrect) {
                setState(() {
                  if (_selectedType == 'single') {
                    for (final option in _options) {
                      option['is_correct'] = false;
                    }
                  }
                  _options[index]['is_correct'] = isCorrect;
                });
              },
              onTextArChanged: (index, value) {
                _options[index]['text_ar'] = value;
              },
              onTextEnChanged: (index, value) {
                _options[index]['text_en'] = value;
              },
              onDeleteOption: (index) {
                setState(() => _options.removeAt(index));
              },
              onSelectTrue: () {
                setState(() {
                  _options[0]['is_correct'] = true;
                  _options[1]['is_correct'] = false;
                });
              },
              onSelectFalse: () {
                setState(() {
                  _options[0]['is_correct'] = false;
                  _options[1]['is_correct'] = true;
                });
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: QuizFormBottomBar(
        isLoading: _isSaving,
        isArabic: isArabic,
        isDark: isDark,
        submitLabel: isArabic ? 'حفظ السؤال' : 'Save Question',
        onCancel: () => AppRouter.pop(context),
        onSubmit: _save,
      ),
    );
  }
}
