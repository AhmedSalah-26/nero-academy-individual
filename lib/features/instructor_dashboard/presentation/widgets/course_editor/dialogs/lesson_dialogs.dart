// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/services/file_picker_service.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_details/presentation/screens/course_preview_player_screen.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';
import 'scheduled_date_time_picker.dart';

Future<void> _uploadDocument(
    BuildContext context,
    bool isArabic,
    Function(String url, String name, int size, String type) onSuccess,
    Function(bool) setLoading) async {
  try {
    setLoading(true);
    final filePickerService = FilePickerService();
    final pickedFile =
        await filePickerService.pickFile(type: FilePickerType.any);

    if (pickedFile == null) {
      setLoading(false);
      return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 16),
            Text(isArabic ? 'جاري رفع الملف...' : 'Uploading file...'),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    final supabase = sl<SupabaseClient>();
    final sanitizedName =
        pickedFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    final storagePath = 'course_attachments/$fileName';

    final contentType = lookupMimeType(pickedFile.name) ??
        pickedFile.mimeType ??
        'application/pdf';

    await supabase.storage.from('attachments').uploadBinary(
          storagePath,
          pickedFile.bytes,
          fileOptions: FileOptions(
            contentType: contentType,
          ),
        );

    final fileUrl =
        supabase.storage.from('attachments').getPublicUrl(storagePath);

    onSuccess(fileUrl, pickedFile.name, pickedFile.bytes.length,
        pickedFile.extension);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isArabic ? 'تم رفع الملف بنجاح' : 'File uploaded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    AppLogger.e('Upload error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isArabic ? 'فشل في رفع الملف: $e' : 'Failed to upload file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    setLoading(false);
  }
}

/// Show Add Lesson Dialog
void showAddLessonDialog(BuildContext context, CourseEditorCubit cubit,
    int sectionIndex, bool isArabic) {
  final titleArController = TextEditingController();
  final titleEnController = TextEditingController();
  final videoUrlController = TextEditingController();
  bool isFree = false;
  bool isPublished = true;
  bool useScheduledPublish = false;
  DateTime? publishAt;
  DateTime? unpublishAt;
  String lessonType = 'video';
  bool isUploading = false;

  String? fileUrl;
  String? fileName;
  int? fileSize;
  String? fileType;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => StatefulBuilder(
      builder: (dialogContext, setState) => ResponsiveDialog(
        title: Text(isArabic ? 'إضافة درس جديد' : 'Add New Lesson'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson Type Selector
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(isArabic ? 'فيديو' : 'Video',
                        style: const TextStyle(fontSize: 14)),
                    value: 'video',
                    groupValue: lessonType,
                    onChanged: (val) => setState(() => lessonType = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(isArabic ? 'مستند/ملف' : 'Document/File',
                        style: const TextStyle(fontSize: 14)),
                    value: 'document',
                    groupValue: lessonType,
                    onChanged: (val) => setState(() => lessonType = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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

            if (lessonType == 'video') ...[
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'رابط الفيديو' : 'Video URL',
                  hintText: 'https://youtube.com/...',
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment:
                    isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openVideoPreview(
                      context, videoUrlController.text, isArabic),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(isArabic ? 'معاينة الفيديو' : 'Preview Video'),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (fileUrl != null) ...[
                      const Icon(Icons.insert_drive_file,
                          size: 48, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(fileName ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          '${((fileSize ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          fileUrl = null;
                          fileName = null;
                          fileSize = null;
                          fileType = null;
                        }),
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        label: Text(isArabic ? 'حذف الملف' : 'Remove File',
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    ] else ...[
                      if (isUploading)
                        const CircularProgressIndicator()
                      else ...[
                        const Icon(Icons.cloud_upload,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _uploadDocument(context, isArabic,
                                (url, name, size, type) {
                              setState(() {
                                fileUrl = url;
                                fileName = name;
                                fileSize = size;
                                fileType = type;
                              });
                            },
                                (uploading) =>
                                    setState(() => isUploading = uploading));
                          },
                          icon: const Icon(Icons.file_upload),
                          label: Text(isArabic ? 'اختيار ملف' : 'Choose File'),
                        ),
                      ]
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            CheckboxListTile(
              value: isFree,
              onChanged: (value) => setState(() => isFree = value!),
              title: Text(
                  isArabic ? 'درس مجاني (معاينة)' : 'Free Lesson (Preview)'),
              subtitle: Text(
                isArabic
                    ? 'يمكن للزوار مشاهدة هذا الدرس بدون تسجيل'
                    : 'Visitors can watch this lesson without enrolling',
                style: TextStyle(
                  fontSize: 12,
                  color: isFree ? AppColors.success : AppColors.textMutedLight,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: isPublished,
              onChanged: (value) => setState(() => isPublished = value),
              title: Text(isArabic ? 'منشور' : 'Published'),
              subtitle: Text(
                isArabic
                    ? (isPublished
                        ? 'الدرس متاح للطلاب'
                        : 'الدرس مخفي عن الطلاب')
                    : (isPublished
                        ? 'Lesson is visible to students'
                        : 'Lesson is hidden from students'),
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
            SwitchListTile(
              value: useScheduledPublish,
              onChanged: (value) => setState(() => useScheduledPublish = value),
              title: Text(isArabic ? 'جدولة ظهور الدرس' : 'Schedule Lesson'),
              subtitle: Text(
                isArabic
                    ? 'حدد وقت ظهور واختفاء الدرس للطلاب'
                    : 'Set when students can see this lesson',
                style: const TextStyle(fontSize: 12),
              ),
              activeTrackColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (useScheduledPublish) ...[
              const SizedBox(height: 16),
              ScheduledDateTimePicker(
                label: isArabic ? 'يظهر من' : 'Visible From',
                selectedDateTime: publishAt,
                isArabic: isArabic,
                onChanged: (dt) => setState(() => publishAt = dt),
              ),
              const SizedBox(height: 12),
              ScheduledDateTimePicker(
                label: isArabic ? 'يختفي في' : 'Visible Until',
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
            onPressed: (isUploading)
                ? null
                : () {
                    if (titleArController.text.isNotEmpty &&
                        titleEnController.text.isNotEmpty) {
                      cubit.addLesson(
                        sectionIndex,
                        LessonData(
                          titleAr: titleArController.text,
                          titleEn: titleEnController.text,
                          type: lessonType,
                          order: 0,
                          isFree: isFree,
                          isPublished: isPublished,
                          availableFrom: useScheduledPublish ? publishAt : null,
                          availableUntil:
                              useScheduledPublish ? unpublishAt : null,
                          videoUrl: lessonType == 'video'
                              ? (videoUrlController.text.isEmpty
                                  ? null
                                  : videoUrlController.text)
                              : null,
                          fileUrl: lessonType == 'document' ? fileUrl : null,
                          fileName: lessonType == 'document' ? fileName : null,
                          fileSize: lessonType == 'document' ? fileSize : null,
                          fileType: lessonType == 'document' ? fileType : null,
                        ),
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
    ),
  );
}

/// Show Edit Lesson Dialog
void showEditLessonDialog(BuildContext context, CourseEditorCubit cubit,
    int sectionIndex, int lessonIndex, LessonData lesson, bool isArabic) {
  final titleArController = TextEditingController(text: lesson.titleAr);
  final titleEnController = TextEditingController(text: lesson.titleEn);
  final videoUrlController = TextEditingController(text: lesson.videoUrl ?? '');
  bool isFree = lesson.isFree;
  bool isPublished = lesson.isPublished;
  bool useScheduledPublish =
      lesson.availableFrom != null || lesson.availableUntil != null;
  DateTime? publishAt = lesson.availableFrom;
  DateTime? unpublishAt = lesson.availableUntil;

  String lessonType = lesson.type == 'document' ? 'document' : 'video';
  bool isUploading = false;

  String? fileUrl = lesson.fileUrl;
  String? fileName = lesson.fileName;
  int? fileSize = lesson.fileSize;
  String? fileType = lesson.fileType;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => StatefulBuilder(
      builder: (dialogContext, setState) => ResponsiveDialog(
        title: Text(isArabic ? 'تعديل الدرس' : 'Edit Lesson'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson Type Selector
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(isArabic ? 'فيديو' : 'Video',
                        style: const TextStyle(fontSize: 14)),
                    value: 'video',
                    groupValue: lessonType,
                    onChanged: (val) => setState(() => lessonType = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(isArabic ? 'مستند/ملف' : 'Document/File',
                        style: const TextStyle(fontSize: 14)),
                    value: 'document',
                    groupValue: lessonType,
                    onChanged: (val) => setState(() => lessonType = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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

            if (lessonType == 'video') ...[
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'رابط الفيديو' : 'Video URL',
                  hintText: 'https://youtube.com/...',
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment:
                    isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openVideoPreview(
                      context, videoUrlController.text, isArabic),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(isArabic ? 'معاينة الفيديو' : 'Preview Video'),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (fileUrl != null) ...[
                      const Icon(Icons.insert_drive_file,
                          size: 48, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(fileName ?? 'File',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          '${((fileSize ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          fileUrl = null;
                          fileName = null;
                          fileSize = null;
                          fileType = null;
                        }),
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        label: Text(isArabic ? 'حذف الملف' : 'Remove File',
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    ] else ...[
                      if (isUploading)
                        const CircularProgressIndicator()
                      else ...[
                        const Icon(Icons.cloud_upload,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _uploadDocument(context, isArabic,
                                (url, name, size, type) {
                              setState(() {
                                fileUrl = url;
                                fileName = name;
                                fileSize = size;
                                fileType = type;
                              });
                            },
                                (uploading) =>
                                    setState(() => isUploading = uploading));
                          },
                          icon: const Icon(Icons.file_upload),
                          label: Text(isArabic ? 'اختيار ملف' : 'Choose File'),
                        ),
                      ]
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            CheckboxListTile(
              value: isFree,
              onChanged: (value) => setState(() => isFree = value!),
              title: Text(
                  isArabic ? 'درس مجاني (معاينة)' : 'Free Lesson (Preview)'),
              subtitle: Text(
                isArabic
                    ? 'يمكن للزوار مشاهدة هذا الدرس بدون تسجيل'
                    : 'Visitors can watch this lesson without enrolling',
                style: TextStyle(
                  fontSize: 12,
                  color: isFree ? AppColors.success : AppColors.textMutedLight,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: isPublished,
              onChanged: (value) => setState(() => isPublished = value),
              title: Text(isArabic ? 'منشور' : 'Published'),
              subtitle: Text(
                isArabic
                    ? (isPublished
                        ? 'الدرس متاح للطلاب'
                        : 'الدرس مخفي عن الطلاب')
                    : (isPublished
                        ? 'Lesson is visible to students'
                        : 'Lesson is hidden from students'),
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
            if (useScheduledPublish) ...[
              const SizedBox(height: 16),
              ScheduledDateTimePicker(
                label: isArabic ? 'تاريخ النشر' : 'Publish At',
                selectedDateTime: publishAt,
                isArabic: isArabic,
                onChanged: (dt) => setState(() => publishAt = dt),
              ),
              const SizedBox(height: 12),
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
            onPressed: (isUploading)
                ? null
                : () {
                    if (titleArController.text.isNotEmpty &&
                        titleEnController.text.isNotEmpty) {
                      cubit.updateLesson(
                        sectionIndex,
                        lessonIndex,
                        lesson.copyWith(
                          titleAr: titleArController.text,
                          titleEn: titleEnController.text,
                          type: lessonType,
                          isFree: isFree,
                          isPublished: isPublished,
                          availableFrom: useScheduledPublish ? publishAt : null,
                          clearAvailableFrom: !useScheduledPublish,
                          availableUntil:
                              useScheduledPublish ? unpublishAt : null,
                          clearAvailableUntil: !useScheduledPublish,
                          videoUrl: lessonType == 'video'
                              ? (videoUrlController.text.isEmpty
                                  ? null
                                  : videoUrlController.text)
                              : null,
                          fileUrl: lessonType == 'document' ? fileUrl : null,
                          fileName: lessonType == 'document' ? fileName : null,
                          fileSize: lessonType == 'document' ? fileSize : null,
                          fileType: lessonType == 'document' ? fileType : null,
                        ),
                      );
                      Navigator.pop(ctx);
                    }
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

/// Confirm Delete Lesson
void confirmDeleteLesson(BuildContext context, CourseEditorCubit cubit,
    int sectionIndex, int lessonIndex, bool isArabic) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => ResponsiveAlertDialog(
      title: isArabic ? 'حذف الدرس' : 'Delete Lesson',
      content: isArabic
          ? 'هل أنت متأكد من حذف هذا الدرس؟'
          : 'Are you sure you want to delete this lesson?',
      confirmText: isArabic ? 'حذف' : 'Delete',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      isDestructive: true,
      onConfirm: () {
        cubit.deleteLesson(sectionIndex, lessonIndex);
        Navigator.pop(ctx);
      },
    ),
  );
}

void _openVideoPreview(BuildContext context, String videoUrl, bool isArabic) {
  final url = videoUrl.trim();
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'أدخل رابط الفيديو أولاً'
              : 'Please enter a video URL first',
        ),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CoursePreviewPlayerScreen(
        videoUrl: url,
        courseTitle: isArabic ? 'معاينة الدرس' : 'Lesson Preview',
      ),
    ),
  );
}
