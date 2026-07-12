import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/app_button.dart';
import '../../domain/entities/level_entity.dart';
import '../../data/models/level_model.dart';

/// Level Editor Screen - Full screen version for Create/Edit
class LevelEditorScreen extends StatefulWidget {
  final LevelModel? level;
  final void Function(dynamic dto) onSave;

  const LevelEditorScreen({
    super.key,
    this.level,
    required this.onSave,
  });

  @override
  State<LevelEditorScreen> createState() => _LevelEditorScreenState();
}

class _LevelEditorScreenState extends State<LevelEditorScreen> {
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _displayOrderController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.level != null) {
      _nameArController.text = widget.level!.nameAr;
      _nameEnController.text = widget.level!.nameEn;
      _slugController.text = widget.level!.slug;
      _descriptionArController.text = widget.level!.descriptionAr ?? '';
      _descriptionEnController.text = widget.level!.descriptionEn ?? '';
      _displayOrderController.text = widget.level!.displayOrder.toString();
      _isActive = widget.level!.isActive;
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _slugController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isEdit = widget.level != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (isArabic ? 'تعديل المستوى' : 'Edit Level')
              : (isArabic ? 'إضافة مستوى' : 'Add Level'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _nameArController,
              label: isArabic ? 'الاسم بالعربية' : 'Name (Arabic)',
              hint: isArabic ? 'مثال: مبتدئ' : 'Example: Beginner',
              isDark: isDark,
              icon: Icons.translate_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameEnController,
              label: isArabic ? 'الاسم بالإنجليزية' : 'Name (English)',
              hint: isArabic ? 'Example: Beginner' : 'Example: Beginner',
              isDark: isDark,
              icon: Icons.language_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _slugController,
              label: isArabic ? 'المعرف (Slug)' : 'Slug',
              hint: isArabic ? 'مثال: beginner' : 'Example: beginner',
              isDark: isDark,
              icon: Icons.link_rounded,
              enabled: !isEdit, // Can't change slug after creation
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionArController,
              label: isArabic ? 'الوصف بالعربية' : 'Description (Arabic)',
              hint: isArabic
                  ? 'مناسب للمبتدئين بدون خبرة سابقة'
                  : 'Suitable for beginners',
              isDark: isDark,
              maxLines: 3,
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionEnController,
              label: isArabic ? 'الوصف بالإنجليزية' : 'Description (English)',
              hint: isArabic
                  ? 'Suitable for beginners'
                  : 'Suitable for beginners',
              isDark: isDark,
              maxLines: 3,
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _displayOrderController,
              label: isArabic ? 'ترتيب العرض' : 'Display Order',
              hint: isArabic ? 'مثال: 1' : 'Example: 1',
              isDark: isDark,
              icon: Icons.sort_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isArabic ? 'نشط' : 'Active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      activeTrackColor:
                          AppColors.success.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  text: isArabic ? 'إلغاء' : 'Cancel',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: isArabic ? 'حفظ' : 'Save',
                  onPressed: _onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    IconData? icon,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: maxLines,
              enabled: enabled,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color:
                      isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    final nameAr = _nameArController.text.trim();
    final nameEn = _nameEnController.text.trim();
    final slug = _slugController.text.trim();

    if (nameAr.isEmpty || nameEn.isEmpty || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'يرجى ملء جميع الحقول المطلوبة'
                : 'Please fill all required fields',
          ),
        ),
      );
      return;
    }

    final displayOrder = int.tryParse(_displayOrderController.text.trim()) ?? 0;

    if (widget.level != null) {
      widget.onSave(LevelUpdateDto(
        nameAr: nameAr,
        nameEn: nameEn,
        slug: slug,
        descriptionAr: _descriptionArController.text.trim().isEmpty
            ? null
            : _descriptionArController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim().isEmpty
            ? null
            : _descriptionEnController.text.trim(),
        displayOrder: displayOrder,
        isActive: _isActive,
      ));
    } else {
      widget.onSave(LevelCreateDto(
        nameAr: nameAr,
        nameEn: nameEn,
        slug: slug,
        descriptionAr: _descriptionArController.text.trim().isEmpty
            ? null
            : _descriptionArController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim().isEmpty
            ? null
            : _descriptionEnController.text.trim(),
        displayOrder: displayOrder,
        isActive: _isActive,
      ));
    }
    Navigator.of(context).pop();
  }
}
