import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_user_model.dart';

/// User Details Sections - Instructor and Student info sections

Widget buildInstructorInfo({
  required bool isDark,
  required bool isArabic,
  required bool isEditing,
  required TextEditingController headlineArController,
  required TextEditingController headlineEnController,
  required TextEditingController bioArController,
  required TextEditingController bioEnController,
  required List<String> expertise,
  required bool isVerifiedInstructor,
  required AdminUserModel user,
  required VoidCallback markChanged,
  required Function(bool) onVerifiedChanged,
  required Function(String) onExpertiseAdd,
  required Function(int) onExpertiseRemove,
}) {
  return buildSection(
    title: isArabic ? 'معلومات المدرس' : 'Instructor Information',
    isDark: isDark,
    children: [
      buildField(
        label: isArabic ? 'العنوان (عربي)' : 'Headline (Arabic)',
        controller: headlineArController,
        isDark: isDark,
        enabled: isEditing,
        textDirection: TextDirection.rtl,
        onChanged: (_) => markChanged(),
      ),
      const SizedBox(height: 12),
      buildField(
        label: isArabic ? 'العنوان (إنجليزي)' : 'Headline (English)',
        controller: headlineEnController,
        isDark: isDark,
        enabled: isEditing,
        onChanged: (_) => markChanged(),
      ),
      const SizedBox(height: 12),
      buildField(
        label: isArabic ? 'النبذة (عربي)' : 'Bio (Arabic)',
        controller: bioArController,
        isDark: isDark,
        enabled: isEditing,
        maxLines: 3,
        textDirection: TextDirection.rtl,
        onChanged: (_) => markChanged(),
      ),
      const SizedBox(height: 12),
      buildField(
        label: isArabic ? 'النبذة (إنجليزي)' : 'Bio (English)',
        controller: bioEnController,
        isDark: isDark,
        enabled: isEditing,
        maxLines: 3,
        onChanged: (_) => markChanged(),
      ),
      const SizedBox(height: 12),
      buildChipsField(
        label: isArabic ? 'الخبرات' : 'Expertise',
        items: expertise,
        isDark: isDark,
        enabled: isEditing,
        onAdd: onExpertiseAdd,
        onRemove: onExpertiseRemove,
        isArabic: isArabic,
      ),
      const SizedBox(height: 12),
      if (isEditing)
        SwitchListTile(
          title: Text(isArabic ? 'مدرس موثق' : 'Verified Instructor'),
          value: isVerifiedInstructor,
          onChanged: onVerifiedChanged,
          contentPadding: EdgeInsets.zero,
        )
      else
        buildInfoRow(
          label: isArabic ? 'موثق' : 'Verified',
          value: isVerifiedInstructor
              ? (isArabic ? 'نعم' : 'Yes')
              : (isArabic ? 'لا' : 'No'),
          isDark: isDark,
        ),
      if (user.totalCourses != null) ...[
        const SizedBox(height: 12),
        buildInfoRow(
          label: isArabic ? 'عدد الكورسات' : 'Total Courses',
          value: '${user.totalCourses}',
          isDark: isDark,
        ),
      ],
      if (user.totalStudents != null) ...[
        const SizedBox(height: 12),
        buildInfoRow(
          label: isArabic ? 'عدد الطلاب' : 'Total Students',
          value: '${user.totalStudents}',
          isDark: isDark,
        ),
      ],
      if (user.averageRating != null) ...[
        const SizedBox(height: 12),
        buildInfoRow(
          label: isArabic ? 'التقييم' : 'Rating',
          value: '${user.averageRating!.toStringAsFixed(1)} ⭐',
          isDark: isDark,
        ),
      ],
    ],
  );
}

Widget buildStudentInfo({
  required bool isDark,
  required bool isArabic,
  required bool isEditing,
  required List<String> interests,
  required Function(String) onAdd,
  required Function(int) onRemove,
}) {
  return buildSection(
    title: isArabic ? 'معلومات الطالب' : 'Student Information',
    isDark: isDark,
    children: [
      buildChipsField(
        label: isArabic ? 'الاهتمامات' : 'Interests',
        items: interests,
        isDark: isDark,
        enabled: isEditing,
        onAdd: onAdd,
        onRemove: onRemove,
        isArabic: isArabic,
      ),
    ],
  );
}

Widget buildStatusSection({
  required bool isDark,
  required bool isArabic,
  required bool isEditing,
  required bool isActive,
  required AdminUserModel user,
  required Function(bool) onActiveChanged,
}) {
  return buildSection(
    title: isArabic ? 'الحالة' : 'Status',
    isDark: isDark,
    children: [
      if (isEditing)
        SwitchListTile(
          title: Text(isArabic ? 'نشط' : 'Active'),
          value: isActive,
          onChanged: onActiveChanged,
          contentPadding: EdgeInsets.zero,
        )
      else
        buildInfoRow(
          label: isArabic ? 'الحالة' : 'Status',
          value: isActive
              ? (isArabic ? 'نشط' : 'Active')
              : (isArabic ? 'غير نشط' : 'Inactive'),
          isDark: isDark,
        ),
      if (user.isBanned) ...[
        const SizedBox(height: 12),
        buildInfoRow(
          label: isArabic ? 'سبب الحظر' : 'Ban Reason',
          value: user.banReason ?? (isArabic ? 'غير محدد' : 'Not specified'),
          isDark: isDark,
        ),
        if (user.bannedUntil != null) ...[
          const SizedBox(height: 12),
          buildInfoRow(
            label: isArabic ? 'محظور حتى' : 'Banned Until',
            value: DateFormat('yyyy/MM/dd HH:mm').format(user.bannedUntil!),
            isDark: isDark,
          ),
        ],
      ],
    ],
  );
}

Widget buildSection({
  required String title,
  required bool isDark,
  required List<Widget> children,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
      const SizedBox(height: 16),
      ...children,
    ],
  );
}

Widget buildField({
  required String label,
  required TextEditingController controller,
  required bool isDark,
  bool enabled = true,
  int maxLines = 1,
  TextDirection? textDirection,
  Function(String)? onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        textDirection: textDirection,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ],
  );
}

Widget buildInfoRow({
  required String label,
  required String value,
  required bool isDark,
  bool copyable = false,
  BuildContext? context,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 120,
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ),
            if (copyable && context != null)
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'تم النسخ'
                                : 'Copied')),
                  );
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    ],
  );
}

Widget buildChipsField({
  required String label,
  required List<String> items,
  required bool isDark,
  required bool enabled,
  required Function(String) onAdd,
  required Function(int) onRemove,
  required bool isArabic,
}) {
  final controller = TextEditingController();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...items.asMap().entries.map((entry) => Chip(
                label: Text(entry.value),
                deleteIcon: enabled ? const Icon(Icons.close, size: 16) : null,
                onDeleted: enabled ? () => onRemove(entry.key) : null,
              )),
          if (enabled)
            SizedBox(
              width: 150,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: isArabic ? 'إضافة...' : 'Add...',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        onAdd(controller.text);
                        controller.clear();
                      }
                    },
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    onAdd(value);
                    controller.clear();
                  }
                },
              ),
            ),
        ],
      ),
    ],
  );
}
