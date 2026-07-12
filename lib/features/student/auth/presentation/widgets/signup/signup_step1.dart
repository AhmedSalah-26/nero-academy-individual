import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/utils/validators.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'signup_text_field.dart';
import 'role_selection_card.dart';
import 'signup_dropdown.dart';

class SignupStep1 extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmPassCtrl;
  final String countryDialCode;
  final UserRole selectedRole;
  final String? selectedCountry;
  final String? selectedGovernorate;
  final String? selectedCity;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isDark;
  final Function(String) onCountryCodeChanged;
  final Function(UserRole) onRoleChanged;
  final Function(String?) onCountryChanged;
  final Function(String?) onGovernorateChanged;
  final Function(String?) onCityChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const SignupStep1({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passCtrl,
    required this.confirmPassCtrl,
    required this.countryDialCode,
    required this.selectedRole,
    required this.selectedCountry,
    required this.selectedGovernorate,
    required this.selectedCity,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isDark,
    required this.onCountryCodeChanged,
    required this.onRoleChanged,
    required this.onCountryChanged,
    required this.onGovernorateChanged,
    required this.onCityChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final countries = ['مصر', 'السعودية', 'الإمارات'];
    final governorates = {
      'مصر': ['القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'الشرقية'],
    };
    final cities = {
      'القاهرة': ['مدينة نصر', 'المعادي', 'الزمالك', 'مصر الجديدة'],
      'الجيزة': ['الدقي', 'المهندسين', 'الهرم', '6 أكتوبر'],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'auth.create_account'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'auth.signup_step1_subtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
          const SizedBox(height: 32),

          // Name
          SignupTextField(
            controller: nameCtrl,
            label: 'auth.full_name'.tr(),
            hint: 'auth.full_name_placeholder'.tr(),
            icon: Icons.person_outline_rounded,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'auth.name_required'.tr()
                : null,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Email
          SignupTextField(
            controller: emailCtrl,
            label: 'auth.email'.tr(),
            hint: 'auth.email_placeholder'.tr(),
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Phone with country code
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country code dropdown
              Container(
                width: 100,
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
                    value: countryDialCode,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    dropdownColor: isDark ? AppColors.grey800 : AppColors.white,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.white : AppColors.textMainLight,
                    ),
                    items: const [
                      DropdownMenuItem(value: '+20', child: Text('+20')),
                      DropdownMenuItem(value: '+966', child: Text('+966')),
                      DropdownMenuItem(value: '+971', child: Text('+971')),
                    ],
                    onChanged: (v) => onCountryCodeChanged(v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Phone number
              Expanded(
                child: SignupTextField(
                  controller: phoneCtrl,
                  label: 'auth.phone'.tr(),
                  hint: 'auth.phone_placeholder'.tr(),
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'auth.phone_required'.tr()
                      : null,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User type
          Text(
            'auth.user_type'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          RoleSelectionCard(
            role: UserRole.student,
            label: 'auth.student'.tr(),
            icon: Icons.school_outlined,
            isSelected: true,
            onTap: () => onRoleChanged(UserRole.student),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Country
          SignupDropdown(
            label: 'auth.country'.tr(),
            value: selectedCountry,
            items: countries,
            onChanged: onCountryChanged,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Governorate
          if (selectedCountry != null)
            SignupDropdown(
              label: 'auth.governorate'.tr(),
              value: selectedGovernorate,
              items: governorates[selectedCountry] ?? [],
              onChanged: onGovernorateChanged,
              isDark: isDark,
            ),
          if (selectedCountry != null) const SizedBox(height: 16),

          // City
          if (selectedGovernorate != null)
            SignupDropdown(
              label: 'auth.city'.tr(),
              value: selectedCity,
              items: cities[selectedGovernorate] ?? [],
              onChanged: onCityChanged,
              isDark: isDark,
            ),
          if (selectedGovernorate != null) const SizedBox(height: 16),

          // Password
          SignupTextField(
            controller: passCtrl,
            label: 'auth.password'.tr(),
            hint: 'auth.password_placeholder'.tr(),
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            validator: (v) => Validators.password(v, minLength: 8),
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
          ),
          const SizedBox(height: 16),

          // Confirm Password
          SignupTextField(
            controller: confirmPassCtrl,
            label: 'auth.confirm_password'.tr(),
            hint: 'auth.confirm_password_placeholder'.tr(),
            icon: Icons.lock_outline_rounded,
            obscureText: obscureConfirmPassword,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'auth.confirm_password_required'.tr();
              }
              if (v != passCtrl.text) return 'auth.passwords_dont_match'.tr();
              return null;
            },
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
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
