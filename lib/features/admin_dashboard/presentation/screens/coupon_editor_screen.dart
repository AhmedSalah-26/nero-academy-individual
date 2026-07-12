import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_coupon_model.dart';
import '../cubit/admin_categories_cubit.dart';
import '../cubit/admin_courses_cubit.dart';
import '../widgets/coupons/coupon_form_widgets.dart';
import '../widgets/coupons/coupon_sections_widgets.dart';

/// Coupon Editor Screen - Full screen version for Create/Edit coupon
class CouponEditorScreen extends StatefulWidget {
  final AdminCouponModel? coupon;
  final Function(CreateCouponDto) onSave;

  const CouponEditorScreen({super.key, this.coupon, required this.onSave});

  @override
  State<CouponEditorScreen> createState() => _CouponEditorScreenState();
}

class _CouponEditorScreenState extends State<CouponEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _descArController;
  late TextEditingController _descEnController;
  late TextEditingController _discountController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _minOrderController;
  late TextEditingController _usageLimitController;
  late TextEditingController _perUserLimitController;

  String _discountType = 'percentage';
  String _scope = 'all';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;
  List<String> _selectedCategoryIds = [];
  List<String> _selectedCourseIds = [];

  bool get isArabic => Localizations.localeOf(context).languageCode == 'ar';
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeController = TextEditingController(text: c?.code ?? '');
    _nameArController = TextEditingController(text: c?.nameAr ?? '');
    _nameEnController = TextEditingController(text: c?.nameEn ?? '');
    _descArController = TextEditingController(text: c?.descriptionAr ?? '');
    _descEnController = TextEditingController(text: c?.descriptionEn ?? '');
    _discountController =
        TextEditingController(text: c?.discountValue.toString() ?? '');
    _maxDiscountController =
        TextEditingController(text: c?.maxDiscountAmount?.toString() ?? '');
    _minOrderController =
        TextEditingController(text: c?.minOrderAmount.toString() ?? '0');
    _usageLimitController =
        TextEditingController(text: c?.usageLimit?.toString() ?? '');
    _perUserLimitController =
        TextEditingController(text: c?.usageLimitPerUser.toString() ?? '1');

    if (c != null) {
      _discountType = c.discountType;
      _scope = c.scope;
      _startDate = c.startDate;
      _endDate = c.endDate;
      _selectedCategoryIds = c.categoryIds ?? [];
      _selectedCourseIds = c.courseIds ?? [];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoriesCubit>().loadCategories(isActive: true);
      context.read<AdminCoursesCubit>().loadCourses();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _discountController.dispose();
    _maxDiscountController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    _perUserLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coupon != null
            ? (isArabic ? 'تعديل الكوبون' : 'Edit Coupon')
            : (isArabic ? 'إضافة كوبون جديد' : 'Add New Coupon')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CouponCodeCard(
                controller: _codeController,
                isArabic: isArabic,
              ),
              const SizedBox(height: 16),
              CouponBasicInfoCard(
                nameArController: _nameArController,
                nameEnController: _nameEnController,
                descArController: _descArController,
                descEnController: _descEnController,
                isArabic: isArabic,
              ),
              const SizedBox(height: 24),
              CouponDiscountCard(
                discountType: _discountType,
                discountController: _discountController,
                maxDiscountController: _maxDiscountController,
                minOrderController: _minOrderController,
                isArabic: isArabic,
                isDark: isDark,
                onTypeChanged: (v) => setState(() => _discountType = v!),
              ),
              const SizedBox(height: 24),
              CouponLimitsCard(
                usageLimitController: _usageLimitController,
                perUserLimitController: _perUserLimitController,
                isArabic: isArabic,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              CouponValidityCard(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateChanged: (d) => setState(() => _startDate = d),
                onEndDateChanged: (d) => setState(() => _endDate = d),
                onClearEndDate: () => setState(() => _endDate = null),
                isArabic: isArabic,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              CouponScopeCard(
                scope: _scope,
                isArabic: isArabic,
                isDark: isDark,
                onScopeChanged: (v) => setState(() {
                  _scope = v!;
                  if (v == 'all') {
                    _selectedCategoryIds.clear();
                    _selectedCourseIds.clear();
                  } else if (v == 'categories') {
                    _selectedCourseIds.clear();
                  } else {
                    _selectedCategoryIds.clear();
                  }
                }),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CouponFormBottomBar(
        isLoading: _isLoading,
        isEditing: widget.coupon != null,
        isDark: isDark,
        onCancel: () => Navigator.pop(context),
        onSave: _handleSave,
      ),
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final dto = CreateCouponDto(
      code: _codeController.text.trim(),
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim().isEmpty
          ? null
          : _nameEnController.text.trim(),
      descriptionAr: _descArController.text.trim().isEmpty
          ? null
          : _descArController.text.trim(),
      descriptionEn: _descEnController.text.trim().isEmpty
          ? null
          : _descEnController.text.trim(),
      discountType: _discountType,
      discountValue: double.parse(_discountController.text),
      maxDiscountAmount: _maxDiscountController.text.isEmpty
          ? null
          : double.parse(_maxDiscountController.text),
      minOrderAmount: _minOrderController.text.isEmpty
          ? 0
          : double.parse(_minOrderController.text),
      usageLimit: _usageLimitController.text.isEmpty
          ? null
          : int.parse(_usageLimitController.text),
      usageLimitPerUser: _perUserLimitController.text.isEmpty
          ? 1
          : int.parse(_perUserLimitController.text),
      startDate: _startDate,
      endDate: _endDate,
      scope: _scope,
      categoryIds: _scope == 'categories' ? _selectedCategoryIds : null,
      courseIds: _scope == 'courses' ? _selectedCourseIds : null,
    );

    final error = dto.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    widget.onSave(dto);
    Navigator.pop(context);
  }
}
