import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'auth_text_field.dart';

class InstructorFields extends StatelessWidget {
  final TextEditingController headlineCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController expertiseCtrl;
  final bool isDark;

  const InstructorFields({
    super.key,
    required this.headlineCtrl,
    required this.bioCtrl,
    required this.expertiseCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('auth.instructor_fields_title'.tr()),
        const SizedBox(height: 12),
        // Headline Field
        AuthTextField(
          controller: headlineCtrl,
          label: '${'auth.headline'.tr()} ${'auth.optional'.tr()}',
          hint: 'auth.headline_placeholder'.tr(),
          icon: Icons.work_outline_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        // Bio Field
        _buildBioField(),
        const SizedBox(height: 16),
        // Expertise Field
        AuthTextField(
          controller: expertiseCtrl,
          label: '${'auth.expertise'.tr()} ${'auth.optional'.tr()}',
          hint: 'auth.expertise_placeholder'.tr(),
          icon: Icons.category_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 4),
        Text(
          'auth.expertise_hint'.tr(),
          style: const TextStyle(fontSize: 12, color: AppColors.grey400),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'auth.bio'.tr()} ${'auth.optional'.tr()}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.grey300 : AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: bioCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'auth.bio_placeholder'.tr(),
            hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 14),
            filled: true,
            fillColor: isDark ? AppColors.grey800 : AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.grey700 : AppColors.grey200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: TextStyle(
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }
}
