import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/bookmark_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Bookmarks Bottom Sheet Widget
class BookmarksSheet extends StatelessWidget {
  final bool isDark;
  final String enrollmentId;
  final CoursePlayerRepository repository;
  final Function(String lessonId) onGoToLesson;

  const BookmarksSheet({
    super.key,
    required this.isDark,
    required this.enrollmentId,
    required this.repository,
    required this.onGoToLesson,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookmarkEntity>>(
      future: _loadBookmarks(),
      builder: (context, snapshot) {
        return Column(
          children: [
            _buildHandle(),
            _buildHeader(context),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(context, snapshot),
            ),
          ],
        );
      },
    );
  }

  Future<List<BookmarkEntity>> _loadBookmarks() async {
    AppLogger.i('🔖 [BookmarksSheet] Loading bookmarks...');
    final result = await repository.getBookmarks(enrollmentId: enrollmentId);
    return result.fold(
      (failure) {
        AppLogger.e('[BookmarksSheet] Failed: ${failure.message}');
        return [];
      },
      (bookmarks) {
        AppLogger.success(
            '[BookmarksSheet] Loaded ${bookmarks.length} bookmarks');
        return bookmarks;
      },
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
            'course_player.bookmarks'.tr(),
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

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<BookmarkEntity>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const AppLoadingState.section();
    }

    final bookmarks = snapshot.data ?? [];
    if (bookmarks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: bookmarks.length,
      itemBuilder: (_, index) => _buildBookmarkItem(context, bookmarks[index]),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        type: EmptyStateType.bookmarks,
      ),
    );
  }

  Widget _buildBookmarkItem(BuildContext context, BookmarkEntity bookmark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.bookmark, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookmark.lessonTitle ?? 'درس محفوظ',
                  style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bookmark.note!,
                    style: TextStyle(
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onGoToLesson(bookmark.lessonId);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'course_player.go_to_lesson'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
