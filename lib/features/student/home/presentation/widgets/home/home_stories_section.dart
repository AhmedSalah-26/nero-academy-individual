import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Story Model
class StoryItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String? avatarUrl;
  final bool isViewed;
  final bool isLive;

  const StoryItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.avatarUrl,
    this.isViewed = false,
    this.isLive = false,
  });
}

/// Home Stories Section - Instagram-like stories
class HomeStoriesSection extends StatelessWidget {
  final List<StoryItem> stories;
  final Function(StoryItem) onStoryTap;

  const HomeStoriesSection({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          return _StoryAvatar(
            story: stories[index],
            onTap: () {
              HapticFeedback.lightImpact();
              onStoryTap(stories[index]);
            },
          );
        },
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final StoryItem story;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Avatar with gradient border
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isViewed
                    ? null
                    : story.isLive
                        ? const LinearGradient(
                            colors: [Color(0xFFFF0000), Color(0xFFFF6B6B)],
                          )
                        : const LinearGradient(
                            colors: [AppColors.primary, AppColors.info],
                          ),
                border: story.isViewed
                    ? Border.all(
                        color: isDark ? AppColors.grey600 : AppColors.grey300,
                        width: 2,
                      )
                    : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                ),
                child: ClipOval(
                  child: story.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: story.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildPlaceholder(isDark),
                          errorWidget: (_, __, ___) =>
                              _buildPlaceholder(isDark),
                        )
                      : _buildPlaceholder(isDark),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              story.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: story.isViewed
                    ? (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight)
                    : (isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Live badge
            if (story.isLive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.grey200,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.grey400,
        size: 32,
      ),
    );
  }
}
