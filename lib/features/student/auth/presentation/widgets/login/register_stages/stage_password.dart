import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/utils/validators.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/auth_text_field.dart';

class StagePassword extends StatelessWidget {
  final TextEditingController passCtrl;
  final TextEditingController confirmPassCtrl;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final bool isDark;

  const StagePassword({
    super.key,
    required this.passCtrl,
    required this.confirmPassCtrl,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth.secure_account'.tr(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.password_subtitle'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AuthTextField(
          controller: passCtrl,
          label: 'auth.password'.tr(),
          hint: 'auth.create_password_placeholder'.tr(),
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePassword,
          isDark: isDark,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.grey400,
            ),
            onPressed: onTogglePassword,
          ),
          validator: (v) => Validators.password(v, minLength: 8),
        ),
        const SizedBox(height: 8),
        Text(
          'auth.password_hint'.tr(),
          style: const TextStyle(fontSize: 12, color: AppColors.grey400),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: confirmPassCtrl,
          label: 'auth.confirm_password'.tr(),
          hint: 'auth.confirm_password_placeholder'.tr(),
          icon: Icons.lock_outline_rounded,
          obscureText: obscureConfirmPassword,
          isDark: isDark,
          suffixIcon: IconButton(
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.grey400,
            ),
            onPressed: onToggleConfirmPassword,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'auth.confirm_password_required'.tr();
            }
            if (v != passCtrl.text) {
              return 'auth.passwords_dont_match'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }
}
