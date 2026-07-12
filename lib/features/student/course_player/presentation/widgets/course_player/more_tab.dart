import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// More Tab Widget
class MoreTab extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNotesTap;
  final VoidCallback onBookmarksTap;
  final VoidCallback onAnnouncementsTap;
  final VoidCallback onAttachmentsTap;

  const MoreTab({
    super.key,
    required this.isDark,
    required this.onNotesTap,
    required this.onBookmarksTap,
    required this.onAnnouncementsTap,
    required this.onAttachmentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOption(
            Icons.note_alt_outlined,
            'course_player.notes'.tr(),
            onNotesTap,
          ),
          _buildOption(
            Icons.bookmark_border,
            'course_player.bookmarks'.tr(),
            onBookmarksTap,
          ),
          _buildOption(
            Icons.campaign_outlined,
            'course_player.announcements'.tr(),
            onAnnouncementsTap,
          ),
          _buildOption(
            Icons.attach_file,
            'course_player.attachments'.tr(),
            onAttachmentsTap,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
      onTap: onTap,
    );
  }
}
