import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/app_button.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/models/category_model.dart';

/// Category Editor Screen - Full screen version for Create/Edit
class CategoryEditorScreen extends StatefulWidget {
  final CategoryModel? category;
  final void Function(dynamic dto) onSave;

  const CategoryEditorScreen({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<CategoryEditorScreen> {
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIcon;

  final _icons = [
    'code',
    'design',
    'business',
    'marketing',
    'language',
    'music',
    'photo',
    'health',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameArController.text = widget.category!.nameAr;
      _nameEnController.text = widget.category!.nameEn ?? '';
      _descriptionController.text = widget.category!.description ?? '';
      _selectedIcon = widget.category!.icon;
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isEdit = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (isArabic ? 'تعديل التصنيف' : 'Edit Category')
              : (isArabic ? 'إضافة تصنيف' : 'Add Category'),
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
              hint: isArabic ? 'أدخل الاسم بالعربية' : 'Enter Arabic name',
              isDark: isDark,
              icon: Icons.translate_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameEnController,
              label: isArabic ? 'الاسم بالإنجليزية' : 'Name (English)',
              hint: isArabic ? 'أدخل الاسم بالإنجليزية' : 'Enter English name',
              isDark: isDark,
              icon: Icons.language_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: isArabic ? 'الوصف' : 'Description',
              hint: isArabic ? 'أدخل الوصف' : 'Enter description',
              isDark: isDark,
              maxLines: 3,
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'اختر الأيقونة' : 'Select Icon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildIconSelector(isDark),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelector(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _icons.map((icon) {
        final isSelected = icon == _selectedIcon;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = icon),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : (isDark ? AppColors.surfaceDark : AppColors.grey100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              _getIconData(icon),
              color: isSelected ? AppColors.primary : AppColors.grey500,
              size: 28,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code_rounded;
      case 'design':
        return Icons.design_services_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'photo':
        return Icons.photo_camera_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _onSave() {
    final nameAr = _nameArController.text.trim();
    if (nameAr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Arabic name')),
      );
      return;
    }

    if (widget.category != null) {
      widget.onSave(CategoryUpdateDto(
        nameAr: nameAr,
        nameEn: _nameEnController.text.trim().isEmpty
            ? null
            : _nameEnController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
      ));
    } else {
      widget.onSave(CategoryCreateDto(
        nameAr: nameAr,
        nameEn: _nameEnController.text.trim().isEmpty
            ? null
            : _nameEnController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
      ));
    }
    Navigator.of(context).pop();
  }
}
