import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/services/video_player_notifier_service.dart';

class VideoMiniPlayerOverlay extends StatelessWidget {
  const VideoMiniPlayerOverlay({super.key});

  bool _hasBottomNavBar(String path) {
    return path == '/home' ||
        path == '/my-learning' ||
        path == '/forums-tab' ||
        path == '/profile';
  }

  @override
  Widget build(BuildContext context) {
    final service = sl<VideoPlayerNotifierService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final isVisible = service.isVisible.value;
        final controller = service.controller;

        if (!isVisible || controller == null) {
          return const SizedBox.shrink();
        }

        // Get the current path to dynamically position the player
        String currentPath = '';
        try {
          currentPath =
              AppRouter.router.routerDelegate.currentConfiguration.uri.path;
        } catch (_) {}

        final double bottomMargin = _hasBottomNavBar(currentPath) ? 96.0 : 16.0;

        return Positioned(
          left: 16,
          right: 16,
          bottom: bottomMargin + MediaQuery.of(context).padding.bottom,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                // Navigate back to course player
                if (service.courseId != null) {
                  service.isVisible.value = false;
                  AppRouter.router.pushNamed(
                    'course-player',
                    pathParameters: {'courseId': service.courseId!},
                    queryParameters: {
                      'enrollment': service.enrollmentId ?? '',
                      'title': service.courseTitle ?? '',
                      if (service.lessonId != null) 'lesson': service.lessonId!,
                      if (service.instructorId != null)
                        'instructorId': service.instructorId!,
                      if (service.instructorName != null)
                        'instructor': service.instructorName!,
                      if (service.instructorAvatar != null)
                        'avatar': service.instructorAvatar!,
                    },
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_circle_filled_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.lessonTitle ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      service.courseTitle ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<bool>(
                                valueListenable: service.isPlaying,
                                builder: (context, isPlaying, _) {
                                  return IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    onPressed: () {
                                      if (isPlaying) {
                                        service.pause();
                                      } else {
                                        service.play();
                                      }
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  service.dismiss();
                                },
                              ),
                            ],
                          ),
                        ),
                        _MiniPlayerProgressBar(controller: controller),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  const _MiniPlayerProgressBar({required this.controller});

  @override
  State<_MiniPlayerProgressBar> createState() => _MiniPlayerProgressBarState();
}

class _MiniPlayerProgressBarState extends State<_MiniPlayerProgressBar> {
  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(_MiniPlayerProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_listener);
      widget.controller.addListener(_listener);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final duration = value.duration.inMilliseconds;
    final position = value.position.inMilliseconds;
    final progress = duration > 0 ? position / duration : 0.0;

    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: Colors.white24,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 2.5,
    );
  }
}
