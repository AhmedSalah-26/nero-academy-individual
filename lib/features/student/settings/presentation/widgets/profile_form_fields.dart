import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Profile Form Fields - Reusable form widgets for profile editing

Widget buildSectionHeader(String title, bool isDark) {
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
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
    ],
  );
}

Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  required bool isDark,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  int maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.grey300 : AppColors.grey600,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.grey600 : AppColors.grey400,
          ),
          prefixIcon: maxLines > 1
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Icon(
                    icon,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                )
              : Icon(
                  icon,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                ),
          filled: true,
          fillColor: isDark ? AppColors.cardDark : AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.grey200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.grey200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    ],
  );
}

/// Instructor Fields Widget
class InstructorFormFields extends StatelessWidget {
  final TextEditingController displayNameCtrl;
  final TextEditingController headlineArCtrl;
  final TextEditingController headlineEnCtrl;
  final TextEditingController bioArCtrl;
  final TextEditingController bioEnCtrl;
  final TextEditingController expertiseCtrl;
  final TextEditingController websiteUrlCtrl;
  final TextEditingController facebookCtrl;
  final TextEditingController twitterCtrl;
  final TextEditingController linkedinCtrl;
  final TextEditingController youtubeCtrl;
  final TextEditingController websiteCtrl;
  final bool isDark;

  const InstructorFormFields({
    super.key,
    required this.displayNameCtrl,
    required this.headlineArCtrl,
    required this.headlineEnCtrl,
    required this.bioArCtrl,
    required this.bioEnCtrl,
    required this.expertiseCtrl,
    required this.websiteUrlCtrl,
    required this.facebookCtrl,
    required this.twitterCtrl,
    required this.linkedinCtrl,
    required this.youtubeCtrl,
    required this.websiteCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        buildSectionHeader(
          isArabic ? 'معلومات المدرس' : 'Instructor Info',
          isDark,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: displayNameCtrl,
          label: isArabic ? 'الاسم الظاهر' : 'Display Name',
          hint: isArabic ? 'مثال: م. أحمد علي' : 'e.g. Ahmed Ali',
          icon: Icons.badge_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: headlineArCtrl,
          label: isArabic ? 'العنوان (عربي)' : 'Headline (Arabic)',
          hint: isArabic
              ? 'مثال: مطور تطبيقات Flutter'
              : 'e.g. Flutter Developer',
          icon: Icons.title_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: headlineEnCtrl,
          label: isArabic ? 'العنوان (إنجليزي)' : 'Headline (English)',
          hint: isArabic ? 'مثال: Flutter Developer' : 'e.g. Flutter Developer',
          icon: Icons.title_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: bioArCtrl,
          label: isArabic ? 'نبذة عنك (عربي)' : 'Bio (Arabic)',
          hint: isArabic ? 'اكتب نبذة مختصرة عنك...' : 'Write a short bio...',
          icon: Icons.description_outlined,
          isDark: isDark,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: bioEnCtrl,
          label: isArabic ? 'نبذة عنك (إنجليزي)' : 'Bio (English)',
          hint: isArabic ? 'Write a short bio...' : 'Write a short bio...',
          icon: Icons.description_outlined,
          isDark: isDark,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: expertiseCtrl,
          label: isArabic ? 'مجالات الخبرة' : 'Expertise',
          hint: isArabic
              ? 'Flutter, Dart, Firebase (مفصولة بفاصلة)'
              : 'Flutter, Dart, Firebase (comma separated)',
          icon: Icons.psychology_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: websiteUrlCtrl,
          label: isArabic ? 'الموقع الإلكتروني' : 'Website URL',
          hint: 'https://yourwebsite.com',
          icon: Icons.public_rounded,
          isDark: isDark,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 32),
        buildSectionHeader(
          isArabic ? 'روابط التواصل الاجتماعي' : 'Social Links',
          isDark,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: facebookCtrl,
          label: 'Facebook',
          hint: 'https://facebook.com/username',
          icon: Icons.facebook_rounded,
          isDark: isDark,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: twitterCtrl,
          label: 'Twitter / X',
          hint: 'https://twitter.com/username',
          icon: Icons.alternate_email_rounded,
          isDark: isDark,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: linkedinCtrl,
          label: 'LinkedIn',
          hint: 'https://linkedin.com/in/username',
          icon: Icons.work_outline_rounded,
          isDark: isDark,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: youtubeCtrl,
          label: 'YouTube',
          hint: 'https://youtube.com/@channel',
          icon: Icons.play_circle_outline_rounded,
          isDark: isDark,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: websiteCtrl,
          label: isArabic ? 'الموقع الشخصي' : 'Website',
          hint: 'https://yourwebsite.com',
          icon: Icons.language_rounded,
          isDark: isDark,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}
