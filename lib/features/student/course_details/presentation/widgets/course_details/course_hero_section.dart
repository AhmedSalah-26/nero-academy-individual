import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';

/// Course Hero Section - Video thumbnail with play button and parallax effect
class CourseHeroSection extends StatelessWidget {
  final CourseDetailsEntity course;
  final VoidCallback? onPlayPreview;
  final ScrollController? scrollController;

  const CourseHeroSection({
    super.key,
    required this.course,
    this.onPlayPreview,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPreview = (course.previewVideoUrl ?? '').trim().isNotEmpty;

    // Temporarily disabled ParallaxImage as it might be causing ANR during page transitions
    /*
    if (scrollController != null &&
        course.thumbnailUrl != null &&
        course.thumbnailUrl!.isNotEmpty) {
      return SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ParallaxImage(
              image: NetworkImage(course.thumbnailUrl!),
              height: 250,
              parallaxFactor: 0.3,
            ),
            _buildOverlay(isDark, hasPreview),
          ],
        ),
      );
    }
    */

    // Fallback to regular AspectRatio
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          _buildThumbnail(isDark),
          // Overlay
          _buildOverlay(context, isDark, hasPreview),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, bool isDark, bool hasPreview) {
    final accent = Theme.of(context).colorScheme.tertiary;

    return GestureDetector(
      onTap: hasPreview ? onPlayPreview : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          // Preview button badge
          if (hasPreview)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'course_details.preview'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    if (course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: course.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, _) {
          final theme = Theme.of(context);
          final accent = theme.colorScheme.tertiary;
          return Container(
            color: Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.08 : 0.025),
              theme.cardColor,
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            ),
          );
        },
        errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
      );
    }
    return _buildPlaceholder(isDark);
  }

  Widget _buildPlaceholder(bool isDark) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final accent = theme.colorScheme.tertiary;
        return Container(
          color: Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.08 : 0.025),
            theme.cardColor,
          ),
          child: Center(
            child: Icon(
              Icons.play_circle_outline_rounded,
              size: 64,
              color: accent.withValues(alpha: 0.68),
            ),
          ),
        );
      },
    );
  }
}
