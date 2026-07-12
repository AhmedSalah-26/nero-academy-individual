import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'coupon_form_widgets.dart';

class CouponCodeCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isArabic;

  const CouponCodeCard({
    super.key,
    required this.controller,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: isArabic ? 'كود الكوبون *' : 'Coupon Code *',
            hintText: isArabic ? 'مثال: SAVE20' : 'e.g., SAVE20',
            prefixIcon: const Icon(Icons.code_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return isArabic ? 'كود الكوبون مطلوب' : 'Required';
            }
            if (v.length < 3) {
              return isArabic ? 'الكود يجب 3 أحرف على الأقل' : 'Min 3 chars';
            }
            return null;
          },
        ),
      ),
    );
  }
}

class CouponBasicInfoCard extends StatelessWidget {
  final TextEditingController nameArController;
  final TextEditingController nameEnController;
  final TextEditingController descArController;
  final TextEditingController descEnController;
  final bool isArabic;

  const CouponBasicInfoCard({
    super.key,
    required this.nameArController,
    required this.nameEnController,
    required this.descArController,
    required this.descEnController,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameArController,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'الاسم بالعربية *' : 'Arabic Name *',
                      prefixIcon: const Icon(Icons.title_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? (isArabic ? 'مطلوب' : 'Required')
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: nameEnController,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'الاسم بالإنجليزية' : 'English Name',
                      prefixIcon: const Icon(Icons.title_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: descArController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText:
                        isArabic ? 'الوصف بالعربية' : 'Arabic Description',
                    prefixIcon: const Icon(Icons.description_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descEnController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText:
                        isArabic ? 'الوصف بالإنجليزية' : 'English Description',
                    prefixIcon: const Icon(Icons.description_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CouponDiscountCard extends StatelessWidget {
  final String discountType;
  final TextEditingController discountController;
  final TextEditingController maxDiscountController;
  final TextEditingController minOrderController;
  final bool isArabic;
  final bool isDark;
  final ValueChanged<String?> onTypeChanged;

  const CouponDiscountCard({
    super.key,
    required this.discountType,
    required this.discountController,
    required this.maxDiscountController,
    required this.minOrderController,
    required this.isArabic,
    required this.isDark,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CouponFormSection(
      title: isArabic ? 'الخصم' : 'Discount',
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: discountType,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'نوع الخصم' : 'Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'percentage',
                        child: Text(isArabic ? 'نسبة' : 'Percentage')),
                    DropdownMenuItem(
                        value: 'fixed',
                        child: Text(isArabic ? 'ثابت' : 'Fixed')),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'القيمة *' : 'Value *',
                    suffixText: discountType == 'percentage' ? '%' : '\$',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return isArabic ? 'مطلوب' : 'Required';
                    }
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) {
                      return isArabic ? 'غير صالح' : 'Invalid';
                    }
                    if (discountType == 'percentage' && n > 100) {
                      return 'Max 100%';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (discountType == 'percentage') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: maxDiscountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isArabic ? 'الحد الأقصى للخصم' : 'Max Discount',
                hintText: isArabic ? 'اختياري' : 'Optional',
                prefixText: '\$ ',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: minOrderController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isArabic ? 'الحد الأدنى للطلب' : 'Min Order',
              prefixText: '\$ ',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class CouponLimitsCard extends StatelessWidget {
  final TextEditingController usageLimitController;
  final TextEditingController perUserLimitController;
  final bool isArabic;
  final bool isDark;

  const CouponLimitsCard({
    super.key,
    required this.usageLimitController,
    required this.perUserLimitController,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CouponFormSection(
      title: isArabic ? 'حدود الاستخدام' : 'Usage Limits',
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: usageLimitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isArabic ? 'الحد الإجمالي' : 'Total Limit',
                hintText: isArabic ? 'غير محدود' : 'Unlimited',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: perUserLimitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isArabic ? 'لكل مستخدم' : 'Per User',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CouponValidityCard extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final VoidCallback onClearEndDate;
  final bool isArabic;
  final bool isDark;

  const CouponValidityCard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onClearEndDate,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CouponFormSection(
      title: isArabic ? 'فترة الصلاحية' : 'Validity Period',
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            child: CouponDatePicker(
              label: isArabic ? 'تاريخ البداية *' : 'Start Date *',
              date: startDate,
              onSelect: onStartDateChanged,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CouponDatePicker(
              label: isArabic ? 'تاريخ النهاية' : 'End Date',
              date: endDate,
              onSelect: onEndDateChanged,
              onClear: onClearEndDate,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class CouponScopeCard extends StatelessWidget {
  final String scope;
  final bool isArabic;
  final bool isDark;
  final ValueChanged<String?> onScopeChanged;

  const CouponScopeCard({
    super.key,
    required this.scope,
    required this.isArabic,
    required this.isDark,
    required this.onScopeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CouponFormSection(
      title: isArabic ? 'نطاق التطبيق' : 'Scope',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: scope,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              DropdownMenuItem(
                  value: 'all', child: Text(isArabic ? 'الكل' : 'All')),
              DropdownMenuItem(
                  value: 'categories',
                  child: Text(isArabic ? 'فئات' : 'Categories')),
              DropdownMenuItem(
                  value: 'courses',
                  child: Text(isArabic ? 'كورسات' : 'Courses')),
            ],
            onChanged: onScopeChanged,
          ),
          if (scope != 'all') ...[
            const SizedBox(height: 12),
            Text(
              scope == 'categories'
                  ? (isArabic
                      ? 'سيطبق على جميع كورسات الفئات المحددة'
                      : 'Applies to all courses in categories')
                  : (isArabic
                      ? 'سيطبق فقط على الكورسات المحددة'
                      : 'Applies only to selected courses'),
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
