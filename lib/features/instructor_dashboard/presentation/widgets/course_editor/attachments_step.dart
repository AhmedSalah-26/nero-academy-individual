import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../../../core/services/file_picker_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Attachments Step - Course-level attachments management
class AttachmentsStep extends StatelessWidget {
  const AttachmentsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<CourseEditorCubit>();

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: state.attachments.isEmpty
                  ? _buildEmptyState(context, cubit, state, isArabic, isDark)
                  : _buildAttachmentsList(
                      context, cubit, state, isArabic, isDark),
            ),
            _buildBottomBar(context, cubit, state, isArabic, isDark),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CourseEditorCubit cubit,
      CourseEditorState state, bool isArabic, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_file, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ù…Ø±ÙÙ‚Ø§Øª Ø¨Ø¹Ø¯'
                : 'No attachments yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'Ø§Ø±ÙØ¹ Ù…Ù„ÙØ§Øª PDF Ø£Ùˆ ØµÙˆØ± Ø£Ùˆ Ù…Ø³ØªÙ†Ø¯Ø§Øª Ù„Ù„ÙƒÙˆØ±Ø³'
                : 'Upload PDF files, images, or documents for the course',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () {
                    AppLogger.i(
                        'ðŸ“Ž [AttachmentsStep] Upload button clicked (empty state)');
                    _pickAndUploadFile(context, cubit, isArabic);
                  },
            icon: const Icon(Icons.upload_file),
            label: Text(isArabic ? 'Ø±ÙØ¹ Ù…Ù„Ù' : 'Upload File'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList(BuildContext context, CourseEditorCubit cubit,
      CourseEditorState state, bool isArabic, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.grey50,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic
                    ? 'Ù…Ø±ÙÙ‚Ø§Øª Ø§Ù„ÙƒÙˆØ±Ø³ (${state.attachments.length})'
                    : 'Course Attachments (${state.attachments.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        AppLogger.i(
                            'ðŸ“Ž [AttachmentsStep] Upload button clicked (list view)');
                        _pickAndUploadFile(context, cubit, isArabic);
                      },
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(isArabic ? 'Ø±ÙØ¹ Ù…Ù„Ù' : 'Upload File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.attachments.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              cubit.reorderAttachments(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final attachment = state.attachments[index];
              return _AttachmentCard(
                key: ValueKey(attachment.id ?? 'attachment_$index'),
                attachment: attachment,
                index: index,
                isArabic: isArabic,
                isDark: isDark,
                onDelete: () => cubit.deleteAttachment(index),
                onEdit: () => _showEditDialog(
                    context, cubit, index, attachment, isArabic),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CourseEditorCubit cubit,
      CourseEditorState state, bool isArabic, bool isDark) {
    if (state.isEditing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () => cubit.setStep(2),
            icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
            label: Text(isArabic ? 'Ø§Ù„Ø³Ø§Ø¨Ù‚' : 'Previous'),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final success = await cubit.saveDraft();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? (isArabic
                                ? 'ØªÙ… Ø­ÙØ¸ Ø§Ù„Ù…Ø³ÙˆØ¯Ø©'
                                : 'Draft saved')
                            : (isArabic
                                ? 'ÙØ´Ù„ ÙÙŠ Ø§Ù„Ø­ÙØ¸'
                                : 'Failed to save')),
                        backgroundColor:
                            success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
                child: Text(isArabic ? 'Ø­ÙØ¸ ÙƒÙ…Ø³ÙˆØ¯Ø©' : 'Save as Draft'),
              ),
              ElevatedButton.icon(
                onPressed: () => cubit.setStep(4),
                icon: Icon(isArabic ? Icons.arrow_back : Icons.arrow_forward),
                label: Text('course_editor.next_settings'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile(
      BuildContext context, CourseEditorCubit cubit, bool isArabic) async {
    try {
      AppLogger.i('ðŸ“Ž [AttachmentsStep] Starting file picker...');

      // Use our custom file picker service
      final filePickerService = FilePickerService();
      final pickedFile = await filePickerService.pickFile(
        type: FilePickerType.any,
      );

      if (pickedFile == null) {
        AppLogger.i('ðŸ“Ž [AttachmentsStep] No file selected');
        return;
      }

      AppLogger.i(
          'ðŸ“Ž [AttachmentsStep] Selected file: ${pickedFile.name}, size: ${pickedFile.sizeKB.toStringAsFixed(1)} KB');

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(isArabic
                    ? 'Ø¬Ø§Ø±ÙŠ Ø±ÙØ¹ Ø§Ù„Ù…Ù„Ù...'
                    : 'Uploading file...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Upload to Supabase Storage
      final supabase = sl<SupabaseClient>();
      final sanitizedName =
          pickedFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final storagePath = 'course_attachments/$fileName';

      await supabase.storage.from('attachments').uploadBinary(
            storagePath,
            pickedFile.bytes,
            fileOptions: FileOptions(
              contentType:
                  pickedFile.mimeType ?? _getContentType(pickedFile.extension),
            ),
          );

      // Get public URL
      final fileUrl =
          supabase.storage.from('attachments').getPublicUrl(storagePath);

      // Add to state
      cubit.addAttachment(
        CourseAttachmentData(
          fileName: pickedFile.name,
          fileUrl: fileUrl,
          fileType: pickedFile.extension,
          fileSize: pickedFile.bytes.length,
        ),
      );

      // Hide loading and show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'ØªÙ… Ø±ÙØ¹ Ø§Ù„Ù…Ù„Ù Ø¨Ù†Ø¬Ø§Ø­'
                : 'File uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('ðŸ“Ž [AttachmentsStep] Upload error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'ÙØ´Ù„ ÙÙŠ Ø±ÙØ¹ Ø§Ù„Ù…Ù„Ù: $e'
                : 'Failed to upload file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/pdf'; // fallback to pdf as octet-stream may be disallowed by Supabase bucket policies
    }
  }

  void _showEditDialog(BuildContext context, CourseEditorCubit cubit, int index,
      CourseAttachmentData attachment, bool isArabic) {
    final fileNameController = TextEditingController(text: attachment.fileName);
    final fileNameArController =
        TextEditingController(text: attachment.fileNameAr ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ù…Ø±ÙÙ‚' : 'Edit Attachment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fileNameController,
                decoration: InputDecoration(
                  labelText: isArabic
                      ? 'Ø§Ø³Ù… Ø§Ù„Ù…Ù„Ù (Ø¥Ù†Ø¬Ù„ÙŠØ²ÙŠ)'
                      : 'File Name (English)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fileNameArController,
                textDirection: ui.TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: isArabic
                      ? 'Ø§Ø³Ù… Ø§Ù„Ù…Ù„Ù (Ø¹Ø±Ø¨ÙŠ)'
                      : 'File Name (Arabic)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'Ø¥Ù„ØºØ§Ø¡' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.updateAttachment(
                index,
                attachment.copyWith(
                  fileName: fileNameController.text,
                  fileNameAr: fileNameArController.text.isEmpty
                      ? null
                      : fileNameArController.text,
                ),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isArabic ? 'Ø­ÙØ¸' : 'Save'),
          ),
        ],
      ),
    );
  }
}

/// Attachment Card Widget
class _AttachmentCard extends StatelessWidget {
  final CourseAttachmentData attachment;
  final int index;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AttachmentCard({
    super.key,
    required this.attachment,
    required this.index,
    required this.isArabic,
    required this.isDark,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.cardDark : AppColors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFileColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(),
            color: _getFileColor(),
          ),
        ),
        title: Text(
          isArabic && attachment.fileNameAr != null
              ? attachment.fileNameAr!
              : attachment.fileName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${attachment.fileType.toUpperCase()} â€¢ ${_formatFileSize(attachment.fileSize)}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: onEdit,
              tooltip: isArabic ? 'ØªØ¹Ø¯ÙŠÙ„' : 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: onDelete,
              tooltip: isArabic ? 'Ø­Ø°Ù' : 'Delete',
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon() {
    switch (attachment.fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (attachment.fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
