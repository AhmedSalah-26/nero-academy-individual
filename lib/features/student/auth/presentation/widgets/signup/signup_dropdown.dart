import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

class SignupDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool isDark;

  const SignupDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.grey300 : AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey800 : AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.grey700 : AppColors.grey300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'auth.select'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              dropdownColor: isDark ? AppColors.grey800 : AppColors.white,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
