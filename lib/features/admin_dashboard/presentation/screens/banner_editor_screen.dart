// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_banner_model.dart';

/// Banner Editor Screen - Full screen version for Create/Edit banner
class BannerEditorScreen extends StatefulWidget {
  final AdminBannerModel? banner;
  final Future<void> Function(CreateBannerDto dto) onSave;

  const BannerEditorScreen({
    super.key,
    this.banner,
    required this.onSave,
  });

  @override
  State<BannerEditorScreen> createState() => _BannerEditorScreenState();
}

class _BannerEditorScreenState extends State<BannerEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleArController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _subtitleArController;
  late final TextEditingController _subtitleEnController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _linkValueController;

  late String _linkType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final banner = widget.banner;
    _titleArController = TextEditingController(text: banner?.titleAr ?? '');
    _titleEnController = TextEditingController(text: banner?.titleEn ?? '');
    _subtitleArController =
        TextEditingController(text: banner?.subtitleAr ?? '');
    _subtitleEnController =
        TextEditingController(text: banner?.subtitleEn ?? '');
    _imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    _linkValueController = TextEditingController(text: banner?.linkValue ?? '');
    _linkType = banner?.linkType ?? 'none';
    _startDate = banner?.startDate;
    _endDate = banner?.endDate;
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _subtitleArController.dispose();
    _subtitleEnController.dispose();
    _imageUrlController.dispose();
    _linkValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.banner != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (isArabic ? 'تعديل البانر' : 'Edit Banner')
              : (isArabic ? 'إضافة بانر جديد' : 'Add New Banner'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(isArabic, isDark),
              const SizedBox(height: 24),
              _buildTitleSection(isArabic, isDark),
              const SizedBox(height: 24),
              _buildSubtitleSection(isArabic, isDark),
              const SizedBox(height: 24),
              _buildLinkSection(isArabic, isDark),
              const SizedBox(height: 24),
              _buildDateSection(isArabic, isDark),
              const SizedBox(height: 80),
            ],
          ),
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
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
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
                      : Text(isArabic ? 'حفظ' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isArabic, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'صورة البانر *' : 'Banner Image *',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                hintText: isArabic ? 'رابط الصورة' : 'Image URL',
                prefixIcon: const Icon(Icons.link_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isArabic
                      ? 'رابط الصورة مطلوب'
                      : 'Image URL is required';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            if (_imageUrlController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageUrlController.text,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey[400]),
                            const SizedBox(height: 4),
                            Text(
                              isArabic
                                  ? 'فشل تحميل الصورة'
                                  : 'Failed to load image',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(bool isArabic, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.title_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'العنوان' : 'Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleArController,
              decoration: InputDecoration(
                labelText: isArabic ? 'العنوان بالعربية *' : 'Arabic Title *',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isArabic
                      ? 'العنوان بالعربية مطلوب'
                      : 'Arabic title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleEnController,
              decoration: InputDecoration(
                labelText: isArabic ? 'العنوان بالإنجليزية' : 'English Title',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleSection(bool isArabic, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.subtitles_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'العنوان الفرعي' : 'Subtitle',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitleArController,
              decoration: InputDecoration(
                labelText:
                    isArabic ? 'العنوان الفرعي بالعربية' : 'Arabic Subtitle',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitleEnController,
              decoration: InputDecoration(
                labelText: isArabic
                    ? 'العنوان الفرعي بالإنجليزية'
                    : 'English Subtitle',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkSection(bool isArabic, bool isDark) {
    final linkTypes = [
      ('none', isArabic ? 'بدون رابط' : 'No Link', Icons.link_off_rounded),
      ('course', isArabic ? 'كورس' : 'Course', Icons.school_outlined),
      ('category', isArabic ? 'تصنيف' : 'Category', Icons.category_outlined),
      ('url', isArabic ? 'رابط خارجي' : 'External URL', Icons.link_rounded),
      ('instructor', isArabic ? 'مدرس' : 'Instructor', Icons.person_outline),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'الرابط' : 'Link',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: linkTypes.map((type) {
                final isSelected = _linkType == type.$1;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.$3, size: 16),
                      const SizedBox(width: 4),
                      Text(type.$2),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _linkType = type.$1),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            if (_linkType != 'none') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkValueController,
                decoration: InputDecoration(
                  labelText: _getLinkValueLabel(isArabic),
                  hintText: _getLinkValueHint(isArabic),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (_linkType != 'none' && (value == null || value.isEmpty)) {
                    return isArabic
                        ? 'قيمة الرابط مطلوبة'
                        : 'Link value is required';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLinkValueLabel(bool isArabic) {
    switch (_linkType) {
      case 'course':
        return isArabic ? 'معرف الكورس' : 'Course ID';
      case 'category':
        return isArabic ? 'معرف التصنيف' : 'Category ID';
      case 'url':
        return isArabic ? 'الرابط' : 'URL';
      case 'instructor':
        return isArabic ? 'معرف المدرس' : 'Instructor ID';
      default:
        return '';
    }
  }

  String _getLinkValueHint(bool isArabic) {
    switch (_linkType) {
      case 'course':
        return 'e.g., course-uuid-123';
      case 'category':
        return 'e.g., category-uuid-123';
      case 'url':
        return 'https://example.com';
      case 'instructor':
        return 'e.g., instructor-uuid-123';
      default:
        return '';
    }
  }

  Widget _buildDateSection(bool isArabic, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'فترة العرض' : 'Display Period',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    label: isArabic ? 'تاريخ البداية' : 'Start Date',
                    value: _startDate,
                    onChanged: (date) => setState(() => _startDate = date),
                    isArabic: isArabic,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePicker(
                    label: isArabic ? 'تاريخ النهاية' : 'End Date',
                    value: _endDate,
                    onChanged: (date) => setState(() => _endDate = date),
                    isArabic: isArabic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'اتركها فارغة لعرض البانر دائماً'
                  : 'Leave empty to display banner indefinitely',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
    required bool isArabic,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
          );
          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          } else {
            onChanged(date);
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value != null
              ? '${value.day}/${value.month}/${value.year} ${value.hour}:${value.minute.toString().padLeft(2, '0')}'
              : (isArabic ? 'اختر تاريخ' : 'Select date'),
          style: TextStyle(
            color: value != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final dto = CreateBannerDto(
      titleAr: _titleArController.text.trim(),
      titleEn: _titleEnController.text.trim().isEmpty
          ? null
          : _titleEnController.text.trim(),
      subtitleAr: _subtitleArController.text.trim().isEmpty
          ? null
          : _subtitleArController.text.trim(),
      subtitleEn: _subtitleEnController.text.trim().isEmpty
          ? null
          : _subtitleEnController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      linkType: _linkType,
      linkValue: _linkType == 'none' ? null : _linkValueController.text.trim(),
      sortOrder: widget.banner?.sortOrder ?? 0,
      startDate: _startDate,
      endDate: _endDate,
    );

    final validationError = dto.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onSave(dto);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
