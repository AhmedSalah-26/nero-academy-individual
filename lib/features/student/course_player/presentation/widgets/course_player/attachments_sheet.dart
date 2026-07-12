import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/attachment_entity.dart';

/// Attachments Bottom Sheet Widget
class AttachmentsSheet extends StatelessWidget {
  final bool isDark;
  final List<AttachmentEntity> attachments;
  final Function(AttachmentEntity attachment) onPreview;
  final ScrollController? scrollController;

  const AttachmentsSheet({
    super.key,
    required this.isDark,
    required this.attachments,
    required this.onPreview,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHandle(),
        _buildHeader(context),
        Expanded(
          child: attachments.isEmpty
              ? _buildEmptyState()
              : _buildAttachmentsList(),
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey600 : AppColors.grey300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'course_player.attachments'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        type: EmptyStateType.attachments,
      ),
    );
  }

  Widget _buildAttachmentsList() {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: attachments.length,
      itemBuilder: (_, index) => _buildAttachmentItem(attachments[index]),
    );
  }

  Widget _buildAttachmentItem(AttachmentEntity attachment) {
    return ListTile(
      onTap: () => onPreview(attachment),
      leading: Icon(
        _getFileIcon(attachment.fileType),
        color: AppColors.primary,
      ),
      title: Text(
        attachment.fileName,
        style: TextStyle(
          color: isDark ? AppColors.white : AppColors.textMainLight,
        ),
      ),
      subtitle: Text(
        _formatFileSize(attachment.fileSize),
        style: TextStyle(
          color: isDark ? AppColors.grey400 : AppColors.grey600,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.visibility_outlined,
        color: AppColors.primary,
      ),
    );
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'mp4':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
