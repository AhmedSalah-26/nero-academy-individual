import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Quiz Section Card - Common card wrapper for quiz form sections
class QuizSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isRequired;
  final bool isArabic;
  final bool isDark;
  final Widget child;

  const QuizSectionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.isRequired = false,
    required this.isArabic,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ),
              if (isRequired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isArabic ? 'مطلوب' : 'Required',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Quiz Info Card with gradient background
class QuizInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const QuizInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiz Setting Field with label, icon and validation
class QuizSettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isRequired;
  final bool isArabic;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool isPercentage;

  const QuizSettingField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.isRequired,
    required this.isArabic,
    this.hintText,
    this.validator,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: AppColors.error)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon, size: 20),
            suffixText: isPercentage ? '%' : null,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

/// Quiz Option Chip - Toggle switch style option
class QuizOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const QuizOptionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceDark : AppColors.grey50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.primary : null,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              Icon(
                Icons.circle_outlined,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Quiz Form Bottom Bar with Cancel and Submit buttons
class QuizFormBottomBar extends StatelessWidget {
  final bool isLoading;
  final bool isArabic;
  final bool isDark;
  final String submitLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final IconData? submitIcon;

  const QuizFormBottomBar({
    super.key,
    required this.isLoading,
    required this.isArabic,
    required this.isDark,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
    this.submitIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                onPressed: isLoading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onSubmit,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(submitIcon ?? Icons.check, size: 20),
                label: Text(submitLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question Type Dropdown
class QuestionTypeDropdown extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String?> onChanged;
  final bool isArabic;

  const QuestionTypeDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedType,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.list),
      ),
      items: [
        DropdownMenuItem(
          value: 'single',
          child: Text(isArabic ? 'اختيار واحد' : 'Single Choice'),
        ),
        DropdownMenuItem(
          value: 'multiple',
          child: Text(isArabic ? 'اختيار متعدد' : 'Multiple Choice'),
        ),
        DropdownMenuItem(
          value: 'true_false',
          child: Text(isArabic ? 'صح/خطأ' : 'True/False'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

/// True/False Option Button
class TrueFalseOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const TrueFalseOptionButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceDark : AppColors.grey50),
          border: Border.all(
            color: isSelected
                ? AppColors.success
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.success : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.success : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
