import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/lesson_history_service.dart';
import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/extensions/datetime_extensions.dart';

/// History Screen - Shows recently watched lessons
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final LessonHistoryService _historyService;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _historyService = sl<LessonHistoryService>();
  }

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, isArabic),
            Expanded(
              child: FutureBuilder<List<LessonHistoryItem>>(
                key: ValueKey(_refreshKey),
                future: _historyService.getHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingState();
                  }

                  final history = snapshot.data ?? [];

                  if (history.isEmpty) {
                    return EmptyState(
                      icon: Icons.history,
                      title: isArabic ? 'لا يوجد سجل' : 'No History',
                      message: isArabic
                          ? 'لم تشاهد أي دروس بعد'
                          : 'You haven\'t watched any lessons yet',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _refresh();
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return _HistoryCard(
                          item: item,
                          isArabic: isArabic,
                          isDark: isDark,
                          onTap: () => _openLesson(item),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isArabic) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.06).clamp(22.0, 26.0);

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.025,
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Text(
              isArabic ? 'السجل' : 'History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
          ),
          // Refresh Button
          GestureDetector(
            onTap: _refresh,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: iconSize * 0.9,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLesson(LessonHistoryItem item) {
    AppRouter.goToCoursePlayer(
      context,
      courseId: item.courseId,
      enrollmentId: item.enrollmentId,
      courseTitle: item.courseTitle,
      lessonId: item.lessonId,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final LessonHistoryItem item;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.item,
    required this.isArabic,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.play_circle_outline,
                          size: 32,
                          color: AppColors.grey400,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.play_circle_outline,
                      size: 32,
                      color: AppColors.grey400,
                    ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.lessonTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.courseTitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.lastWatched.timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              isArabic
                  ? Icons.arrow_back_ios_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
