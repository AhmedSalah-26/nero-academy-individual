import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_quizzes_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_quizzes/bulk_image_widgets.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_quizzes/bulk_image_preview_widgets.dart';

/// Bulk Image Questions Screen - إضافة أسئلة مجمعة من صور (صفحة كاملة)
class BulkImageQuestionsScreen extends StatefulWidget {
  final String quizId;
  final InstructorQuizzesCubit cubit;
  final VoidCallback onSaved;

  const BulkImageQuestionsScreen({
    super.key,
    required this.quizId,
    required this.cubit,
    required this.onSaved,
  });

  @override
  State<BulkImageQuestionsScreen> createState() =>
      _BulkImageQuestionsScreenState();
}

class _BulkImageQuestionsScreenState extends State<BulkImageQuestionsScreen> {
  final List<ImageQuestionModel> _questions = [];
  AnswerLabelType _labelType = AnswerLabelType.numeric;
  int _optionsCount = 4;
  bool _isPickingImages = false;
  bool _isSaving = false;
  int _uploadProgress = 0;

  bool get isArabic => Localizations.localeOf(context).languageCode == 'ar';
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<String> get _answerLabels {
    switch (_labelType) {
      case AnswerLabelType.numeric:
        return List.generate(_optionsCount, (i) => '${i + 1}');
      case AnswerLabelType.alphabetEn:
        return List.generate(_optionsCount, (i) => String.fromCharCode(97 + i));
      case AnswerLabelType.alphabetAr:
        const arabicLetters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];
        return arabicLetters.take(_optionsCount).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAnswered = _questions.isNotEmpty &&
        _questions.every((q) => q.correctAnswerIndex != null);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'إضافة أسئلة من صور' : 'Add Questions from Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            Text(
              isArabic
                  ? 'اختر صور الأسئلة ونوع الترقيم'
                  : 'Select question images and label type',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        actions: [
          if (_questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildSaveButton(allAnswered),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _questions.isEmpty
                  ? BulkImageSetupSection(
                      labelType: _labelType,
                      optionsCount: _optionsCount,
                      isPickingImages: _isPickingImages,
                      isArabic: isArabic,
                      isDark: isDark,
                      onLabelTypeChanged: (t) => setState(() => _labelType = t),
                      onOptionsCountChanged: (c) =>
                          setState(() => _optionsCount = c),
                      onPickImages: _pickImages,
                    )
                  : BulkImageQuestionsPreview(
                      questions: _questions,
                      answerLabels: _answerLabels,
                      isArabic: isArabic,
                      isDark: isDark,
                      onAddMore: _pickImages,
                      onRemove: (i) => setState(() => _questions.removeAt(i)),
                      onAnswerSelected: (qi, ai) => setState(
                          () => _questions[qi].correctAnswerIndex = ai),
                      onPreview: _showImagePreview,
                    ),
            ),
            _buildBottomActions(allAnswered),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool allAnswered) {
    return ElevatedButton.icon(
      onPressed: (_isSaving || !allAnswered) ? null : _saveQuestions,
      icon: _isSaving
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                value: _uploadProgress > 0
                    ? _uploadProgress / _questions.length
                    : null,
              ),
            )
          : const Icon(Icons.check, size: 18),
      label: Text(
        _isSaving
            ? '$_uploadProgress/${_questions.length}'
            : (isArabic ? 'حفظ' : 'Save'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: allAnswered ? AppColors.success : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildBottomActions(bool allAnswered) {
    final answeredCount =
        _questions.where((q) => q.correctAnswerIndex != null).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_questions.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: allAnswered
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$answeredCount/${_questions.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: allAnswered ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'تم تحديدها' : 'answered',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontSize: 13,
                ),
              ),
            ],
            const Spacer(),
            if (_questions.isEmpty)
              ElevatedButton.icon(
                onPressed: _isPickingImages ? null : _pickImages,
                icon: const Icon(Icons.photo_library, size: 18),
                label: Text(isArabic ? 'اختيار الصور' : 'Select Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: (_isSaving || !allAnswered) ? null : _saveQuestions,
                icon: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                          value: _uploadProgress > 0
                              ? _uploadProgress / _questions.length
                              : null,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(
                  _isSaving
                      ? (isArabic
                          ? 'جاري الرفع... $_uploadProgress/${_questions.length}'
                          : 'Uploading... $_uploadProgress/${_questions.length}')
                      : (isArabic ? 'إضافة الأسئلة' : 'Add Questions'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      allAnswered ? AppColors.success : Colors.grey,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    setState(() => _isPickingImages = true);

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (final image in images) {
            _questions.add(ImageQuestionModel(imageFile: image));
          }
        });
      }
    } catch (e) {
      AppLogger.e('[BulkImageQuestions] Error picking images', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isArabic ? 'فشل اختيار الصور' : 'Failed to pick images'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isPickingImages = false);
    }
  }

  void _showImagePreview(XFile? imageFile) {
    if (imageFile == null) return;

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
                child: kIsWeb
                    ? Image.network(imageFile.path, fit: BoxFit.contain)
                    : Image.file(File(imageFile.path), fit: BoxFit.contain),
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

  Future<void> _saveQuestions() async {
    setState(() {
      _isSaving = true;
      _uploadProgress = 0;
    });

    try {
      final supabase = Supabase.instance.client;
      final labels = _answerLabels;

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];

        String? imageUrl;
        if (question.imageFile != null) {
          final fileName =
              'quiz_${widget.quizId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final path = 'quiz_questions/$fileName';
          final bytes = await question.imageFile!.readAsBytes();

          await supabase.storage.from('courses').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );

          imageUrl = supabase.storage.from('courses').getPublicUrl(path);
        }

        final options = List.generate(labels.length, (optIndex) {
          return {
            'text_ar': labels[optIndex],
            'text_en': labels[optIndex],
            'is_correct': optIndex == question.correctAnswerIndex,
          };
        });

        await widget.cubit.addQuestion(
          quizId: widget.quizId,
          questionAr: '',
          questionEn: '',
          imageUrl: imageUrl,
          type: 'single',
          options: options,
        );

        setState(() => _uploadProgress = i + 1);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم إضافة ${_questions.length} سؤال بنجاح'
                  : '${_questions.length} questions added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('[BulkImageQuestions] Error saving questions', e);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isArabic ? 'حدث خطأ أثناء الحفظ' : 'Error saving questions'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
