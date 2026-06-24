import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/models/course_commerce_models.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Basic Info Step - Course title, description, category, etc.
class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _titleArController;
  late TextEditingController _titleEnController;
  late TextEditingController _subtitleArController;
  late TextEditingController _subtitleEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _thumbnailController;
  late TextEditingController _previewVideoController;
  late TextEditingController _whatsappGroupController;
  late TextEditingController _telegramGroupController;
  late TextEditingController _facebookGroupController;

  @override
  void initState() {
    super.initState();
    final state = context.read<CourseEditorCubit>().state;
    _titleArController = TextEditingController(text: state.titleAr);
    _titleEnController = TextEditingController(text: state.titleEn);
    _subtitleArController = TextEditingController(text: state.subtitleAr);
    _subtitleEnController = TextEditingController(text: state.subtitleEn);
    _descriptionArController = TextEditingController(text: state.descriptionAr);
    _descriptionEnController = TextEditingController(text: state.descriptionEn);
    _thumbnailController =
        TextEditingController(text: state.thumbnailUrl ?? '');
    _previewVideoController =
        TextEditingController(text: state.previewVideoUrl ?? '');
    _whatsappGroupController =
        TextEditingController(text: state.groupLinks.whatsapp ?? '');
    _telegramGroupController =
        TextEditingController(text: state.groupLinks.telegram ?? '');
    _facebookGroupController =
        TextEditingController(text: state.groupLinks.facebook ?? '');
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _subtitleArController.dispose();
    _subtitleEnController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _thumbnailController.dispose();
    _previewVideoController.dispose();
    _whatsappGroupController.dispose();
    _telegramGroupController.dispose();
    _facebookGroupController.dispose();
    super.dispose();
  }

  void _updateCubit() {
    context.read<CourseEditorCubit>().updateBasicInfo(
          titleAr: _titleArController.text,
          titleEn: _titleEnController.text,
          subtitleAr: _subtitleArController.text,
          subtitleEn: _subtitleEnController.text,
          descriptionAr: _descriptionArController.text,
          descriptionEn: _descriptionEnController.text,
          thumbnailUrl: _thumbnailController.text.isEmpty
              ? null
              : _thumbnailController.text,
          previewVideoUrl: _previewVideoController.text.isEmpty
              ? null
              : _previewVideoController.text,
          groupLinks: CourseGroupLinks(
            whatsapp: _emptyToNull(_whatsappGroupController.text),
            telegram: _emptyToNull(_telegramGroupController.text),
            facebook: _emptyToNull(_facebookGroupController.text),
          ),
        );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                  isArabic ? 'العنوان' : 'Title', isDark, isArabic),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _titleArController,
                      label: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
                      hint: isArabic
                          ? 'أدخل العنوان بالعربية'
                          : 'Enter Arabic title',
                      isDark: isDark,
                      isRequired: true,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _titleEnController,
                      label: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
                      hint: isArabic
                          ? 'أدخل العنوان بالإنجليزية'
                          : 'Enter English title',
                      isDark: isDark,
                      isRequired: true,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  isArabic ? 'العنوان الفرعي' : 'Subtitle', isDark, isArabic),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _subtitleArController,
                      label: isArabic
                          ? 'العنوان الفرعي (عربي)'
                          : 'Subtitle (Arabic)',
                      hint: isArabic ? 'وصف مختصر' : 'Brief description',
                      isDark: isDark,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _subtitleEnController,
                      label: isArabic
                          ? 'العنوان الفرعي (إنجليزي)'
                          : 'Subtitle (English)',
                      hint: isArabic ? 'وصف مختصر' : 'Brief description',
                      isDark: isDark,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  isArabic ? 'الوصف' : 'Description', isDark, isArabic),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _descriptionArController,
                    label: isArabic ? 'الوصف (عربي)' : 'Description (Arabic)',
                    hint: isArabic
                        ? 'وصف تفصيلي للكورس'
                        : 'Detailed course description',
                    isDark: isDark,
                    isRequired: true,
                    maxLines: 5,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionEnController,
                    label:
                        isArabic ? 'الوصف (إنجليزي)' : 'Description (English)',
                    hint: isArabic
                        ? 'وصف تفصيلي للكورس'
                        : 'Detailed course description',
                    isDark: isDark,
                    isRequired: true,
                    maxLines: 5,
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  isArabic ? 'التصنيف والمستوى' : 'Category & Level',
                  isDark,
                  isArabic),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    // Mobile: Stack vertically
                    return Column(
                      children: [
                        _buildDropdown(
                          label: isArabic ? 'التصنيف' : 'Category',
                          value: state.categoryId,
                          items: state.categories
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(isArabic ? c.nameAr : c.nameEn),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            context
                                .read<CourseEditorCubit>()
                                .updateBasicInfo(categoryId: value);
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: isArabic ? 'المستوى' : 'Level',
                          value: state.level,
                          items: [
                            DropdownMenuItem(
                              value: 'beginner',
                              child: Text(isArabic ? 'مبتدئ' : 'Beginner'),
                            ),
                            DropdownMenuItem(
                              value: 'intermediate',
                              child: Text(isArabic ? 'متوسط' : 'Intermediate'),
                            ),
                            DropdownMenuItem(
                              value: 'advanced',
                              child: Text(isArabic ? 'متقدم' : 'Advanced'),
                            ),
                          ],
                          onChanged: (value) {
                            context
                                .read<CourseEditorCubit>()
                                .updateBasicInfo(level: value);
                          },
                          isDark: isDark,
                        ),
                      ],
                    );
                  } else {
                    // Desktop: Side by side
                    return Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: isArabic ? 'التصنيف' : 'Category',
                            value: state.categoryId,
                            items: state.categories
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child:
                                          Text(isArabic ? c.nameAr : c.nameEn),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              context
                                  .read<CourseEditorCubit>()
                                  .updateBasicInfo(categoryId: value);
                            },
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            label: isArabic ? 'المستوى' : 'Level',
                            value: state.level,
                            items: [
                              DropdownMenuItem(
                                value: 'beginner',
                                child: Text(isArabic ? 'مبتدئ' : 'Beginner'),
                              ),
                              DropdownMenuItem(
                                value: 'intermediate',
                                child:
                                    Text(isArabic ? 'متوسط' : 'Intermediate'),
                              ),
                              DropdownMenuItem(
                                value: 'advanced',
                                child: Text(isArabic ? 'متقدم' : 'Advanced'),
                              ),
                            ],
                            onChanged: (value) {
                              context
                                  .read<CourseEditorCubit>()
                                  .updateBasicInfo(level: value);
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  isArabic ? 'روابط جروبات الكورس' : 'Course Group Links',
                  isDark,
                  isArabic),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _whatsappGroupController,
                    label:
                        isArabic ? 'رابط جروب واتساب' : 'WhatsApp Group Link',
                    hint: 'https://chat.whatsapp.com/...',
                    isDark: isDark,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _telegramGroupController,
                    label:
                        isArabic ? 'رابط جروب تليجرام' : 'Telegram Group Link',
                    hint: 'https://t.me/...',
                    isDark: isDark,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _facebookGroupController,
                    label:
                        isArabic ? 'رابط جروب فيسبوك' : 'Facebook Group Link',
                    hint: 'https://facebook.com/groups/...',
                    isDark: isDark,
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  isArabic ? 'الوسائط' : 'Media', isDark, isArabic),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _thumbnailController,
                    label: isArabic ? 'رابط الصورة المصغرة' : 'Thumbnail URL',
                    hint: 'https://...',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _previewVideoController,
                    label:
                        isArabic ? 'رابط فيديو المعاينة' : 'Preview Video URL',
                    hint: 'https://youtube.com/...',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (!state.isEditing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      _updateCubit();
                      context.read<CourseEditorCubit>().setStep(1);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isArabic ? 'التالي' : 'Next'),
                        const SizedBox(width: 8),
                        Icon(isArabic ? Icons.arrow_back : Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark, bool isArabic) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool isRequired = false,
    int maxLines = 1,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textDirection: textDirection,
          onChanged: (_) => _updateCubit(),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
