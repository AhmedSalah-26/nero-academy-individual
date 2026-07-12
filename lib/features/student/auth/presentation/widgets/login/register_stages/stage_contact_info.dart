import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/utils/validators.dart';
import 'package:lms_platform/core/shared_widgets/phone_input_field.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/auth_text_field.dart';

class StageContactInfo extends StatefulWidget {
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool isDark;
  final ValueChanged<String>? onCountryCodeChanged;

  const StageContactInfo({
    super.key,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.isDark,
    this.onCountryCodeChanged,
  });

  @override
  State<StageContactInfo> createState() => _StageContactInfoState();
}

class _StageContactInfoState extends State<StageContactInfo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth.contact_info'.tr(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? AppColors.white : AppColors.textMainLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.contact_subtitle'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: widget.isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AuthTextField(
          controller: widget.emailCtrl,
          label: 'auth.email'.tr(),
          hint: 'auth.email_placeholder'.tr(),
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          isDark: widget.isDark,
        ),
        const SizedBox(height: 16),
        PhoneInputField(
          controller: widget.phoneCtrl,
          label: 'auth.phone'.tr(),
          onCountryCodeChanged: widget.onCountryCodeChanged,
          validator: (value) {
            final requiredValidation = Validators.required(
              value,
              message: 'auth.phone_required'.tr(),
            );
            if (requiredValidation != null) return requiredValidation;
            return Validators.phone(
              value,
              invalidMessage: context.locale.languageCode == 'ar'
                  ? 'رقم الهاتف غير صالح'
                  : 'Invalid phone number',
            );
          },
        ),
      ],
    );
  }
}
