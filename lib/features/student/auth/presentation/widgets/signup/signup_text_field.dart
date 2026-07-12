import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

class SignupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const SignupTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.grey300 : AppColors.grey700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.grey400),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.grey800 : AppColors.grey100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.grey700 : AppColors.grey300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.grey700 : AppColors.grey300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
