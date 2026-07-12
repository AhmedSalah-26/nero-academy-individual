import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';
import 'scheduled_date_time_picker.dart';

/// Show Add Section Dialog
void showAddSectionDialog(
    BuildContext context, CourseEditorCubit cubit, bool isArabic) {
  final titleArController = TextEditingController();
  final titleEnController = TextEditingController();

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => ResponsiveDialog(
      title: Text(isArabic ? 'إضافة قسم جديد' : 'Add New Section'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleArController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleEnController,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (titleArController.text.isNotEmpty &&
                titleEnController.text.isNotEmpty) {
              cubit.addSection(
                titleArController.text,
                titleEnController.text,
              );
              Navigator.pop(ctx);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(isArabic ? 'إضافة' : 'Add'),
        ),
      ],
    ),
  );
}

/// Show Edit Section Dialog
void showEditSectionDialog(BuildContext context, CourseEditorCubit cubit,
    int index, SectionData section, bool isArabic) {
  final titleArController = TextEditingController(text: section.titleAr);
  final titleEnController = TextEditingController(text: section.titleEn);
  bool isPublished = section.isPublished;
  bool useScheduledPublish = false;
  DateTime? publishAt;
  DateTime? unpublishAt;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => StatefulBuilder(
      builder: (dialogContext, setState) => ResponsiveDialog(
        title: Text(isArabic ? 'تعديل القسم' : 'Edit Section'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleArController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleEnController,
              decoration: InputDecoration(
                labelText: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
              ),
            ),
            const SizedBox(height: 16),
            // Published toggle
            SwitchListTile(
              value: isPublished,
              onChanged: (value) => setState(() => isPublished = value),
              title: Text(isArabic ? 'منشور' : 'Published'),
              subtitle: Text(
                isArabic
                    ? (isPublished
                        ? 'القسم متاح للطلاب'
                        : 'القسم مخفي عن الطلاب')
                    : (isPublished
                        ? 'Section is visible to students'
                        : 'Section is hidden from students'),
                style: TextStyle(
                  fontSize: 12,
                  color: isPublished
                      ? AppColors.success
                      : AppColors.textMutedLight,
                ),
              ),
              activeTrackColor: AppColors.success,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            // Scheduled publishing toggle
            SwitchListTile(
              value: useScheduledPublish,
              onChanged: (value) => setState(() => useScheduledPublish = value),
              title: Text(isArabic ? 'نشر مجدول' : 'Scheduled Publishing'),
              subtitle: Text(
                isArabic
                    ? 'جدولة النشر وإلغاء النشر تلقائياً'
                    : 'Schedule automatic publish/unpublish',
                style: const TextStyle(fontSize: 12),
              ),
              activeTrackColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            // Scheduled publish options
            if (useScheduledPublish) ...[
              const SizedBox(height: 16),
              // Publish At
              ScheduledDateTimePicker(
                label: isArabic ? 'تاريخ النشر' : 'Publish At',
                selectedDateTime: publishAt,
                isArabic: isArabic,
                onChanged: (dt) => setState(() => publishAt = dt),
              ),
              const SizedBox(height: 12),
              // Unpublish At
              ScheduledDateTimePicker(
                label: isArabic ? 'تاريخ إلغاء النشر' : 'Unpublish At',
                selectedDateTime: unpublishAt,
                isArabic: isArabic,
                onChanged: (dt) => setState(() => unpublishAt = dt),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              cubit.updateSection(
                index,
                titleArController.text,
                titleEnController.text,
                isPublished: isPublished,
              );
              // TODO: Save scheduled publish dates when backend is connected
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    ),
  );
}

/// Confirm Delete Section
void confirmDeleteSection(
    BuildContext context, CourseEditorCubit cubit, int index, bool isArabic) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => ResponsiveAlertDialog(
      title: isArabic ? 'حذف القسم' : 'Delete Section',
      content: isArabic
          ? 'هل أنت متأكد من حذف هذا القسم وجميع دروسه؟'
          : 'Are you sure you want to delete this section and all its lessons?',
      confirmText: isArabic ? 'حذف' : 'Delete',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      isDestructive: true,
      onConfirm: () {
        cubit.deleteSection(index);
        Navigator.pop(ctx);
      },
    ),
  );
}
