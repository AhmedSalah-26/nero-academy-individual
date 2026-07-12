import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'quiz_form_widgets.dart';

class QuestionEditorImageSection extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final String? imageUrl;
  final XFile? selectedImage;
  final bool isUploadingImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const QuestionEditorImageSection({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.imageUrl,
    required this.selectedImage,
    required this.isUploadingImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null || selectedImage != null;

    return QuizSectionCard(
      icon: Icons.image,
      iconColor: AppColors.primary,
      title: isArabic ? 'صورة السؤال (اختياري)' : 'Question Image (Optional)',
      isArabic: isArabic,
      isDark: isDark,
      child: !hasImage
          ? OutlinedButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: Text(isArabic ? 'إضافة صورة' : 'Add Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side:
                    BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: selectedImage != null
                      ? (kIsWeb
                          ? Image.network(
                              selectedImage!.path,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(selectedImage!.path),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ))
                      : Image.network(
                          imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _ImageActionButton(
                        icon: Icons.edit,
                        onTap: onPickImage,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      _ImageActionButton(
                        icon: Icons.delete,
                        onTap: onRemoveImage,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
                if (isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class QuestionEditorTextSection extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final TextEditingController questionArController;
  final TextEditingController questionEnController;

  const QuestionEditorTextSection({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.questionArController,
    required this.questionEnController,
  });

  @override
  Widget build(BuildContext context) {
    return QuizSectionCard(
      icon: Icons.help_outline,
      iconColor: AppColors.success,
      title: isArabic ? 'نص السؤال' : 'Question Text',
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        children: [
          TextField(
            controller: questionArController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isArabic ? 'السؤال (عربي)' : 'Question (Arabic)',
              hintText: isArabic
                  ? 'اختياري إذا كان هناك صورة'
                  : 'Optional if image provided',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.language),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: questionEnController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isArabic ? 'السؤال (إنجليزي)' : 'Question (English)',
              hintText: isArabic
                  ? 'اختياري إذا كان هناك صورة'
                  : 'Optional if image provided',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.language),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionEditorTypeSection extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final String selectedType;
  final ValueChanged<String?> onChanged;

  const QuestionEditorTypeSection({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return QuizSectionCard(
      icon: Icons.category,
      iconColor: AppColors.warning,
      title: isArabic ? 'نوع السؤال' : 'Question Type',
      isArabic: isArabic,
      isDark: isDark,
      child: QuestionTypeDropdown(
        selectedType: selectedType,
        isArabic: isArabic,
        onChanged: onChanged,
      ),
    );
  }
}

class QuestionEditorOptionsSection extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final String selectedType;
  final List<Map<String, dynamic>> options;
  final VoidCallback onAddOption;
  final void Function(int oldIndex, int newIndex) onReorderOptions;
  final void Function(int index, bool isCorrect) onCorrectChanged;
  final void Function(int index, String value) onTextArChanged;
  final void Function(int index, String value) onTextEnChanged;
  final void Function(int index) onDeleteOption;
  final VoidCallback onSelectTrue;
  final VoidCallback onSelectFalse;

  const QuestionEditorOptionsSection({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.selectedType,
    required this.options,
    required this.onAddOption,
    required this.onReorderOptions,
    required this.onCorrectChanged,
    required this.onTextArChanged,
    required this.onTextEnChanged,
    required this.onDeleteOption,
    required this.onSelectTrue,
    required this.onSelectFalse,
  });

  @override
  Widget build(BuildContext context) {
    return QuizSectionCard(
      icon: Icons.list_alt,
      iconColor: AppColors.info,
      title: selectedType == 'true_false'
          ? (isArabic ? 'الإجابة الصحيحة' : 'Correct Answer')
          : (isArabic ? 'الخيارات' : 'Options'),
      isArabic: isArabic,
      isDark: isDark,
      child: Column(
        children: [
          if (selectedType != 'true_false')
            Align(
              alignment:
                  isArabic ? Alignment.centerLeft : Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAddOption,
                icon: const Icon(Icons.add, size: 18),
                label: Text(isArabic ? 'إضافة' : 'Add'),
              ),
            ),
          const SizedBox(height: 8),
          if (selectedType == 'true_false')
            Row(
              children: [
                Expanded(
                  child: TrueFalseOptionButton(
                    label: isArabic ? 'صح' : 'True',
                    isSelected: options[0]['is_correct'] as bool,
                    isDark: isDark,
                    onTap: onSelectTrue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TrueFalseOptionButton(
                    label: isArabic ? 'خطأ' : 'False',
                    isSelected: options[1]['is_correct'] as bool,
                    isDark: isDark,
                    onTap: onSelectFalse,
                  ),
                ),
              ],
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              // ignore: deprecated_member_use
              onReorder: onReorderOptions,
              children: options.asMap().entries.map((entry) {
                return _OptionItem(
                  key: ValueKey('option_${entry.key}'),
                  index: entry.key,
                  option: entry.value,
                  isArabic: isArabic,
                  isDark: isDark,
                  canDelete: options.length > 2,
                  onCorrectChanged: (value) =>
                      onCorrectChanged(entry.key, value),
                  onTextArChanged: (value) => onTextArChanged(entry.key, value),
                  onTextEnChanged: (value) => onTextEnChanged(entry.key, value),
                  onDelete: () => onDeleteOption(entry.key),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ImageActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> option;
  final bool isArabic;
  final bool isDark;
  final bool canDelete;
  final ValueChanged<bool> onCorrectChanged;
  final ValueChanged<String> onTextArChanged;
  final ValueChanged<String> onTextEnChanged;
  final VoidCallback onDelete;

  const _OptionItem({
    super.key,
    required this.index,
    required this.option,
    required this.isArabic,
    required this.isDark,
    required this.canDelete,
    required this.onCorrectChanged,
    required this.onTextArChanged,
    required this.onTextEnChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle, size: 20, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Checkbox(
            value: option['is_correct'] as bool,
            onChanged: (value) => onCorrectChanged(value ?? false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller:
                      TextEditingController(text: option['text_ar'] as String),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'الخيار بالعربية' : 'Option in Arabic',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: onTextArChanged,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller:
                      TextEditingController(text: option['text_en'] as String),
                  decoration: InputDecoration(
                    hintText:
                        isArabic ? 'الخيار بالإنجليزية' : 'Option in English',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: onTextEnChanged,
                ),
              ],
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
