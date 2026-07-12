import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/instructor_coupons_cubit.dart';
import '../widgets/dialogs/course_selection_dialog.dart';
import '../widgets/common/editor_form_widgets.dart';

/// Coupon Editor Screen - Full page for creating/editing coupons
class CouponEditorScreen extends StatefulWidget {
  final InstructorCouponModel? coupon;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const CouponEditorScreen({
    super.key,
    this.coupon,
    required this.onSave,
  });

  @override
  State<CouponEditorScreen> createState() => _CouponEditorScreenState();
}

class _CouponEditorScreenState extends State<CouponEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _discountValueController;
  late TextEditingController _usageLimitController;

  String _discountType = 'percentage';
  String _scope = 'all';
  Set<String> _selectedCourseIds = {};
  Map<String, Map<String, dynamic>> _selectedCoursesData = {};
  DateTime? _endDate;
  bool _isLoading = false;

  bool get isEditing => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.coupon?.code ?? '');
    _nameArController =
        TextEditingController(text: widget.coupon?.nameAr ?? '');
    _nameEnController =
        TextEditingController(text: widget.coupon?.nameEn ?? '');
    _discountValueController = TextEditingController(
      text: widget.coupon?.discountValue.toStringAsFixed(0) ?? '',
    );
    _usageLimitController = TextEditingController(
      text: widget.coupon?.usageLimit?.toString() ?? '',
    );
    _discountType = widget.coupon?.discountType ?? 'percentage';
    _scope = widget.coupon?.scope ?? 'all';
    _selectedCourseIds = widget.coupon?.courseIds.toSet() ?? {};
    _endDate = widget.coupon?.endDate;
    _loadSelectedCoursesData();
  }

  Future<void> _loadSelectedCoursesData() async {
    if (_selectedCourseIds.isEmpty) return;

    try {
      final response = await Supabase.instance.client
          .from('courses')
          .select('id, title_ar, title_en, thumbnail_url')
          .inFilter('id', _selectedCourseIds.toList());

      if (!mounted) return;
      setState(() {
        _selectedCoursesData = {
          for (final course in response as List)
            course['id'] as String: Map<String, dynamic>.from(course),
        };
      });
    } catch (e) {
      debugPrint('Error loading selected coupon courses: $e');
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _discountValueController.dispose();
    _usageLimitController.dispose();
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
        title: Text(
          isEditing
              ? (isArabic ? 'تعديل الكوبون' : 'Edit Coupon')
              : (isArabic ? 'كوبون جديد' : 'New Coupon'),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            EditorInfoCard(
              icon: Icons.info_outline,
              color: AppColors.info,
              text: isArabic
                  ? 'أنشئ كوبونات خصم لطلابك. يمكنك تحديد نوع الخصم والحد الأقصى للاستخدام وتاريخ الانتهاء.'
                  : 'Create discount coupons for your students. You can set discount type, usage limit, and expiry date.',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildCodeSection(isArabic, isDark),
            const SizedBox(height: 20),
            _buildNameSection(isArabic, isDark),
            const SizedBox(height: 20),
            _buildDiscountSection(isArabic, isDark),
            const SizedBox(height: 20),
            _buildScopeSection(isArabic, isDark),
            const SizedBox(height: 20),
            _buildLimitsSection(isArabic, isDark),
            const SizedBox(height: 32),
            EditorFormActions(
              isLoading: _isLoading,
              cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
              saveLabel: isArabic ? 'حفظ الكوبون' : 'Save Coupon',
              onCancel: () => Navigator.pop(context),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection(bool isArabic, bool isDark) {
    return EditorFormCard(
      icon: Icons.confirmation_number_outlined,
      title: isArabic ? 'كود الكوبون' : 'Coupon Code',
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الكود' : 'Code',
                    hintText: 'SUMMER2024',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isArabic ? 'مطلوب' : 'Required';
                    }
                    if (value.length < 3) {
                      return isArabic
                          ? 'يجب أن يكون 3 أحرف على الأقل'
                          : 'Must be at least 3 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: _generateRandomCode,
                  icon: const Icon(Icons.casino_outlined),
                  tooltip:
                      isArabic ? 'توليد كود عشوائي' : 'Generate random code',
                  color: AppColors.primary,
                  iconSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EditorHintBox(
            text: isArabic
                ? 'استخدم أحرف كبيرة وأرقام فقط. تجنب الأحرف المتشابهة (O/0, I/1)'
                : 'Use uppercase letters and numbers only. Avoid similar characters (O/0, I/1)',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection(bool isArabic, bool isDark) {
    return EditorFormCard(
      icon: Icons.label_outline,
      title: isArabic ? 'اسم الكوبون' : 'Coupon Name',
      isDark: isDark,
      child: Column(
        children: [
          TextFormField(
            controller: _nameArController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: isArabic ? 'الاسم (عربي)' : 'Name (Arabic)',
              hintText: isArabic ? 'خصم الصيف' : 'Summer Discount',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.translate),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return isArabic ? 'مطلوب' : 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameEnController,
            decoration: InputDecoration(
              labelText: isArabic ? 'الاسم (إنجليزي)' : 'Name (English)',
              hintText: 'Summer Discount',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.translate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection(bool isArabic, bool isDark) {
    return EditorFormCard(
      icon: Icons.discount_outlined,
      title: isArabic ? 'تفاصيل الخصم' : 'Discount Details',
      isDark: isDark,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _discountType,
            decoration: InputDecoration(
              labelText: isArabic ? 'نوع الخصم' : 'Discount Type',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: 'percentage',
                child: Row(
                  children: [
                    const Icon(Icons.percent, size: 18),
                    const SizedBox(width: 8),
                    Text(isArabic ? 'نسبة مئوية' : 'Percentage'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'fixed',
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 18),
                    const SizedBox(width: 8),
                    Text(isArabic ? 'مبلغ ثابت' : 'Fixed Amount'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _discountType = value!);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _discountValueController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: isArabic ? 'قيمة الخصم' : 'Discount Value',
              suffixText: _discountType == 'percentage' ? '%' : 'EGP',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                _discountType == 'percentage'
                    ? Icons.percent
                    : Icons.attach_money,
                color: AppColors.success,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return isArabic ? 'مطلوب' : 'Required';
              }
              final num = double.tryParse(value);
              if (num == null || num <= 0) {
                return isArabic ? 'قيمة غير صالحة' : 'Invalid value';
              }
              if (_discountType == 'percentage' && num > 100) {
                return isArabic
                    ? 'لا يمكن أن تتجاوز 100%'
                    : 'Cannot exceed 100%';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSection(bool isArabic, bool isDark) {
    return EditorFormCard(
      icon: Icons.school_outlined,
      title: isArabic ? 'نطاق الكوبون' : 'Coupon Scope',
      isDark: isDark,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _scope,
            decoration: InputDecoration(
              labelText: isArabic ? 'يطبق على' : 'Applies to',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.filter_list_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    const Icon(Icons.all_inclusive, size: 18),
                    const SizedBox(width: 8),
                    Text(isArabic ? 'كل الكورسات' : 'All Courses'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'courses',
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, size: 18),
                    const SizedBox(width: 8),
                    Text(isArabic ? 'كورسات محددة' : 'Specific Courses'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _scope = value!;
                if (_scope == 'all') {
                  _selectedCourseIds.clear();
                }
              });
            },
          ),
          if (_scope == 'courses') ...[
            const SizedBox(height: 16),
            EditorInfoCard(
              icon: Icons.info_outline,
              color: AppColors.info,
              text: isArabic
                  ? 'سيتم تطبيق الكوبون فقط على الكورسات المحددة'
                  : 'Coupon will only apply to selected courses',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showCourseSelector(context, isArabic),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                _selectedCourseIds.isEmpty
                    ? (isArabic ? 'اختر الكورسات' : 'Select Courses')
                    : (isArabic
                        ? '${_selectedCourseIds.length} كورس محدد'
                        : '${_selectedCourseIds.length} courses selected'),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            if (_selectedCourseIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._selectedCoursesData.entries.map((entry) {
                final courseId = entry.key;
                final course = entry.value;
                final titleAr = course['title_ar'] as String? ?? '';
                final titleEn = course['title_en'] as String?;
                final title = isArabic ? titleAr : (titleEn ?? titleAr);

                return SelectedCourseChip(
                  title: title,
                  thumbnailUrl: course['thumbnail_url'] as String?,
                  isArabic: isArabic,
                  isDark: isDark,
                  onRemove: () {
                    setState(() {
                      _selectedCourseIds.remove(courseId);
                      _selectedCoursesData.remove(courseId);
                    });
                  },
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _showCourseSelector(BuildContext context, bool isArabic) async {
    final result = await CourseSelectionDialog.show(
      context,
      isArabic: isArabic,
      initialSelectedIds: _selectedCourseIds,
    );

    if (result != null) {
      setState(() {
        _selectedCourseIds = result['ids'] as Set<String>;
        _selectedCoursesData =
            result['courses'] as Map<String, Map<String, dynamic>>;
      });
    }
  }

  Widget _buildLimitsSection(bool isArabic, bool isDark) {
    return EditorFormCard(
      icon: Icons.settings_outlined,
      title: isArabic ? 'القيود والحدود' : 'Limits & Restrictions',
      isDark: isDark,
      child: Column(
        children: [
          TextFormField(
            controller: _usageLimitController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: isArabic ? 'الحد الأقصى للاستخدام' : 'Usage Limit',
              hintText: isArabic ? 'غير محدود' : 'Unlimited',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.people_outline),
              helperText: isArabic
                  ? 'اترك فارغاً للاستخدام غير المحدود'
                  : 'Leave empty for unlimited usage',
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectEndDate(context, isArabic),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: isArabic ? 'تاريخ الانتهاء' : 'End Date',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _endDate = null),
                        tooltip: isArabic ? 'إزالة' : 'Clear',
                      )
                    : null,
                helperText: isArabic
                    ? 'اترك فارغاً لعدم تحديد تاريخ انتهاء'
                    : 'Leave empty for no expiry date',
              ),
              child: Text(
                _endDate != null
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : (isArabic ? 'بدون انتهاء' : 'No expiry'),
                style: TextStyle(
                  fontSize: 16,
                  color: _endDate != null
                      ? (isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight)
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectEndDate(BuildContext context, bool isArabic) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: isArabic ? 'اختر تاريخ الانتهاء' : 'Select end date',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmText: isArabic ? 'تأكيد' : 'Confirm',
    );

    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  void _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code =
        List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() => _codeController.text = code);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_scope == 'courses' && _selectedCourseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى اختيار كورس واحد على الأقل'
                : 'Please select at least one course',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'code': _codeController.text,
      'name_ar': _nameArController.text,
      'name_en': _nameEnController.text.isEmpty ? null : _nameEnController.text,
      'discount_type': _discountType,
      'discount_value': double.parse(_discountValueController.text),
      'usage_limit': _usageLimitController.text.isEmpty
          ? null
          : int.parse(_usageLimitController.text),
      'end_date': _endDate,
      'scope': _scope,
      'course_ids': _scope == 'courses' ? _selectedCourseIds.toList() : null,
    };

    final success = await widget.onSave(data);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }
}
