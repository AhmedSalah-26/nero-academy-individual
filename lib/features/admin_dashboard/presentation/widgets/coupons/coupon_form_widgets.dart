import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Section Card for Coupon Forms
class CouponFormSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget child;

  const CouponFormSection({
    super.key,
    required this.title,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Date Picker Field
class CouponDatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime) onSelect;
  final VoidCallback? onClear;
  final bool isDark;

  const CouponDatePicker({
    super.key,
    required this.label,
    required this.date,
    required this.onSelect,
    this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (selected != null) onSelect(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: onClear != null && date != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          date != null
              ? '${date!.day}/${date!.month}/${date!.year}'
              : (onClear != null ? (isArabic ? 'غير محدد' : 'Not set') : ''),
          style: TextStyle(
            color: date != null
                ? (isDark ? AppColors.textMainDark : AppColors.textMainLight)
                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
        ),
      ),
    );
  }
}

/// Bottom Actions Bar
class CouponFormBottomBar extends StatelessWidget {
  final bool isLoading;
  final bool isEditing;
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const CouponFormBottomBar({
    super.key,
    required this.isLoading,
    required this.isEditing,
    required this.isDark,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
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
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing
                        ? (isArabic ? 'تحديث' : 'Update')
                        : (isArabic ? 'إنشاء' : 'Create')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
