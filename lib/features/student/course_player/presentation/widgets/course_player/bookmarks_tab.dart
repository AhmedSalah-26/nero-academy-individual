import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/bookmark_entity.dart';

/// Bookmarks Tab Widget
class BookmarksTab extends StatelessWidget {
  final List<BookmarkEntity> bookmarks;
  final bool isLoading;
  final bool isDark;
  final ValueChanged<BookmarkEntity> onJumpToLesson;
  final ValueChanged<BookmarkEntity> onDelete;

  const BookmarksTab({
    super.key,
    required this.bookmarks,
    required this.isLoading,
    required this.isDark,
    required this.onJumpToLesson,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState.section();
    }

    if (bookmarks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _BookmarkCard(
          bookmark: bookmarks[index],
          isDark: isDark,
          onJumpToLesson: () => onJumpToLesson(bookmarks[index]),
          onDelete: () => onDelete(bookmarks[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      type: EmptyStateType.bookmarks,
      title: 'course_player.no_bookmarks'.tr(),
      message: 'course_player.no_bookmarks_desc'.tr(),
      compact: true,
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final BookmarkEntity bookmark;
  final bool isDark;
  final VoidCallback onJumpToLesson;
  final VoidCallback onDelete;

  const _BookmarkCard({
    required this.bookmark,
    required this.isDark,
    required this.onJumpToLesson,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bookmark,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bookmark.lessonTitle ?? 'course_player.lesson'.tr(),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bookmark.note!,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(bookmark.createdAt),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark.withValues(alpha: 0.7)
                      : AppColors.textMutedLight.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              TextButton.icon(
                onPressed: onJumpToLesson,
                icon: const Icon(
                  Icons.play_circle_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  'course_player.go_to_lesson'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
