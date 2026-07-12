import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_quizzes_cubit.dart';
import 'bulk_image_widgets.dart';

/// Bulk Image Questions Dialog - إضافة أسئلة مجمعة من صور
class BulkImageQuestionsDialog extends StatefulWidget {
  final String quizId;
  final InstructorQuizzesCubit cubit;
  final VoidCallback onSaved;

  const BulkImageQuestionsDialog({
    super.key,
    required this.quizId,
    required this.cubit,
    required this.onSaved,
  });

  @override
  State<BulkImageQuestionsDialog> createState() =>
      _BulkImageQuestionsDialogState();
}

class _BulkImageQuestionsDialogState extends State<BulkImageQuestionsDialog> {
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
    return Dialog(
      child: Container(
        width: 800,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
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
                  : _buildQuestionsPreview(),
            ),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.photo_library, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'إضافة أسئلة من صور' : 'Add Questions from Images',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight),
              ),
              Text(
                isArabic
                    ? 'اختر صور الأسئلة ونوع الترقيم'
                    : 'Select question images and label type',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
              ),
            ],
          ),
        ),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildQuestionsPreview() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                isArabic
                    ? '${_questions.length} سؤال - حدد الإجابة الصحيحة لكل سؤال'
                    : '${_questions.length} questions - Select correct answer for each',
                style: const TextStyle(color: AppColors.info),
              ),
              const Spacer(),
              TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: Text(isArabic ? 'إضافة المزيد' : 'Add More')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _questions.length,
            itemBuilder: (ctx, i) => _buildQuestionCard(i, _questions[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, ImageQuestionModel question) {
    final labels = _answerLabels;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: question.correctAnswerIndex != null
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: question.correctAnswerIndex != null ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary))),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showImagePreview(question.imageFile),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: question.imageFile != null
                  ? (kIsWeb
                      ? Image.network(question.imageFile!.path,
                          width: 100, height: 80, fit: BoxFit.cover)
                      : Image.file(File(question.imageFile!.path),
                          width: 100, height: 80, fit: BoxFit.cover))
                  : Container(
                      width: 100,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isArabic
                        ? 'اختر الإجابة الصحيحة:'
                        : 'Select correct answer:',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(labels.length, (optIndex) {
                    final isSelected = question.correctAnswerIndex == optIndex;
                    return InkWell(
                      onTap: () => setState(
                          () => question.correctAnswerIndex = optIndex),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.cardDark
                                  : AppColors.backgroundLight),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.success
                                  : Colors.grey[400]!),
                        ),
                        child: Center(
                            child: Text(labels[optIndex],
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : null))),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          IconButton(
              onPressed: () => setState(() => _questions.removeAt(index)),
              icon: const Icon(Icons.delete_outline, color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final allAnswered = _questions.isNotEmpty &&
        _questions.every((q) => q.correctAnswerIndex != null);
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight))),
      child: Row(
        children: [
          if (_questions.isNotEmpty)
            Text(
                '${_questions.where((q) => q.correctAnswerIndex != null).length}/${_questions.length}',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight)),
          const Spacer(),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          const SizedBox(width: 12),
          if (_questions.isEmpty)
            ElevatedButton.icon(
              onPressed: _isPickingImages ? null : _pickImages,
              icon: const Icon(Icons.photo_library, size: 18),
              label: Text(isArabic ? 'اختيار الصور' : 'Select Images'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
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
                              : null))
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving
                  ? '$_uploadProgress/${_questions.length}'
                  : (isArabic ? 'إضافة الأسئلة' : 'Add Questions')),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      allAnswered ? AppColors.success : Colors.grey,
                  foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    setState(() => _isPickingImages = true);
    try {
      final images = await ImagePicker()
          .pickMultiImage(maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() {
          for (final img in images) {
            _questions.add(ImageQuestionModel(imageFile: img));
          }
        });
      }
    } catch (e) {
      AppLogger.e('[BulkImageQuestions] Error picking images', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(isArabic ? 'فشل اختيار الصور' : 'Failed to pick images'),
            backgroundColor: AppColors.error));
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
              child: Stack(alignment: Alignment.center, children: [
                InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(imageFile.path, fit: BoxFit.contain)
                            : Image.file(File(imageFile.path),
                                fit: BoxFit.contain))),
                Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.black54),
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                    )),
              ]),
            ));
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
          await supabase.storage.from('courses').uploadBinary(
              path, await question.imageFile!.readAsBytes(),
              fileOptions: const FileOptions(contentType: 'image/jpeg'));
          imageUrl = supabase.storage.from('courses').getPublicUrl(path);
        }

        final options = List.generate(
            labels.length,
            (optIndex) => {
                  'text_ar': labels[optIndex],
                  'text_en': labels[optIndex],
                  'is_correct': optIndex == question.correctAnswerIndex,
                });

        await widget.cubit.addQuestion(
            quizId: widget.quizId,
            questionAr: '',
            questionEn: '',
            imageUrl: imageUrl,
            type: 'single',
            options: options);
        setState(() => _uploadProgress = i + 1);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isArabic
                ? 'تم إضافة ${_questions.length} سؤال'
                : '${_questions.length} questions added'),
            backgroundColor: AppColors.success));
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('[BulkImageQuestions] Error saving', e);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isArabic ? 'خطأ أثناء الحفظ' : 'Error saving'),
            backgroundColor: AppColors.error));
      }
    }
  }
}
