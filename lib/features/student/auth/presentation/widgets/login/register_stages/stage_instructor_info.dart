import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/auth_text_field.dart';

class StageInstructorInfo extends StatelessWidget {
  final TextEditingController? headlineCtrl;
  final TextEditingController? bioCtrl;
  final bool isDark;

  const StageInstructorInfo({
    super.key,
    this.headlineCtrl,
    this.bioCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth.instructor_info'.tr(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.instructor_subtitle'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (headlineCtrl != null)
          AuthTextField(
            controller: headlineCtrl!,
            label: 'auth.headline'.tr(),
            hint: 'auth.headline_placeholder'.tr(),
            icon: Icons.title_outlined,
            isDark: isDark,
          ),
        if (headlineCtrl != null) const SizedBox(height: 16),
        if (bioCtrl != null)
          AuthTextField(
            controller: bioCtrl!,
            label: 'auth.bio'.tr(),
            hint: 'auth.bio_placeholder'.tr(),
            icon: Icons.description_outlined,
            isDark: isDark,
          ),
        const SizedBox(height: 16),
        Text(
          'auth.optional'.tr(),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
        ),
      ],
    );
  }
}
