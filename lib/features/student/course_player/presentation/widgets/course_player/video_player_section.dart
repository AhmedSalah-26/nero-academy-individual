import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/lesson_entity.dart';
import 'package:lms_platform/features/student/course_player/presentation/cubit/course_player_cubit.dart';
import 'direct_video_player_widget.dart';
import 'clean_youtube_player.dart';

class VideoPlayerSection extends StatelessWidget {
  final LessonEntity lesson;
  final int currentPosition;
  final int totalDuration;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay10;
  final VoidCallback onForward10;
  final VoidCallback onFullscreen;
  final VoidCallback onCast;
  final ValueChanged<double> onSeek;
  final VoidCallback onSpeedTap;
  final VoidCallback? onBack;
  final VoidCallback? onTap;
  final String? courseTitle;
  final int sectionIndex;
  final int lessonIndex;
  final VoidCallback? onOpenFile;

  const VideoPlayerSection({
    super.key,
    required this.lesson,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.isDark,
    required this.onPlayPause,
    required this.onReplay10,
    required this.onForward10,
    required this.onFullscreen,
    required this.onCast,
    required this.onSeek,
    required this.onSpeedTap,
    this.onBack,
    this.onTap,
    this.courseTitle,
    this.sectionIndex = 0,
    this.lessonIndex = 0,
    this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.32 : 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _buildPlayerContent(context),
        ),
      ),
    );
  }

  Widget _buildPlayerContent(BuildContext context) {
    // ── File / Document lessons → show file card instead of video player ──
    if (_isFileLessonType()) {
      return _buildFileCard(context);
    }

    if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      final videoUrl = lesson.videoUrl!.trim();
      final progress = context.read<CoursePlayerCubit>().state.currentProgress;
      final initialPosition = progress?.lastPosition ?? 0;
      final isYouTube = _isYouTubeUrl(videoUrl) ||
          lesson.videoProvider == VideoProvider.youtube;
      final shouldUseDirectPlayer = !isYouTube &&
          (lesson.videoProvider == VideoProvider.supabase ||
              lesson.videoProvider == VideoProvider.bunny);

      if (shouldUseDirectPlayer) {
        return DirectVideoPlayerWidget(
          key: ValueKey('direct-${lesson.id}'),
          videoUrl: videoUrl,
          isDark: isDark,
          initialPosition: initialPosition,
        );
      }

      return YouTubePlayerWidget(
        key: ValueKey(lesson.id),
        videoUrl: videoUrl,
        isDark: isDark,
        initialPosition: initialPosition,
        courseTitle: courseTitle,
        lessonTitle: lesson.titleAr,
      );
    }

    return _buildNoVideoWidget();
  }

  bool _isFileLessonType() {
    return lesson.type == LessonType.document ||
        lesson.type == LessonType.resource;
  }

  /// Beautiful file card shown instead of video player for document/resource lessons
  Widget _buildFileCard(BuildContext context) {
    final ext = _getFileExtension();
    final fileIcon = _getFileIcon(ext);
    final fileColor = _getFileColor(ext);
    final hasFile = (lesson.fileUrl != null && lesson.fileUrl!.isNotEmpty) ||
        onOpenFile != null;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              fileColor.withValues(alpha: isDark ? 0.18 : 0.10),
              fileColor.withValues(alpha: isDark ? 0.06 : 0.03),
              isDark ? const Color(0xFF12101E) : const Color(0xFFF8F6FF),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── File icon badge ────────────────────────────────────────────
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: fileColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: fileColor.withValues(alpha: 0.30),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: fileColor.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(fileIcon, color: fileColor, size: 34),
            ),
            const SizedBox(height: 14),
            // ── File name ─────────────────────────────────────────────────
            if (lesson.fileName != null && lesson.fileName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  lesson.fileName!,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // ── File size ─────────────────────────────────────────────────
            if (lesson.fileSize != null && lesson.fileSize! > 0) ...[
              const SizedBox(height: 6),
              Text(
                _formatFileSize(lesson.fileSize!),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),
            // ── Open file button ───────────────────────────────────────────
            if (hasFile)
              ElevatedButton.icon(
                onPressed: onOpenFile,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'افتح الملف',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: fileColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: fileColor.withValues(alpha: 0.4),
                ),
              )
            else
              // No file URL available
              Text(
                'الملف غير متاح حاليًا',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFileExtension() {
    final source = lesson.fileName ?? lesson.fileUrl ?? lesson.fileType ?? '';
    final dotIndex = source.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < source.length - 1) {
      return source.substring(dotIndex + 1).toLowerCase();
    }
    return (lesson.fileType ?? '').toLowerCase();
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_outlined;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audiotrack_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'pdf':
        return const Color(0xFFE53E3E);
      case 'doc':
      case 'docx':
        return const Color(0xFF2B5CE6);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF1D8A4C);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFE85D2A);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFFB8860B);
      case 'mp3':
      case 'wav':
      case 'm4a':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool _isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') ||
        lower.contains('youtube-nocookie.com') ||
        lower.contains('youtu.be');
  }

  Widget _buildNoVideoWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_outlined,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'course_player.video_unavailable'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'course_player.video_unavailable_desc'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
