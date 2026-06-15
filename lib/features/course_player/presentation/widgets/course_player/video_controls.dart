import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/animations/widgets/micro/pulse_animation.dart';

/// Video Controls Widget
class VideoControls extends StatelessWidget {
  final int currentPosition;
  final int totalDuration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay10;
  final VoidCallback onForward10;
  final VoidCallback onFullscreen;
  final ValueChanged<double> onSeek;
  final VoidCallback onSpeedTap;

  const VideoControls({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onReplay10,
    required this.onForward10,
    required this.onFullscreen,
    required this.onSeek,
    required this.onSpeedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time display
          _buildTimeDisplay(),
          const SizedBox(height: 4),
          // Progress bar
          _buildProgressBar(),
          const SizedBox(height: 4),
          // Control buttons
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    final remainingSeconds = totalDuration - currentPosition;
    final isLowTime = remainingSeconds < 60 &&
        remainingSeconds > 0; // Less than 1 minute remaining

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(currentPosition),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Add PulseAnimation for remaining time when low
        PulseAnimation(
          animate: isLowTime,
          minScale: 1.0,
          maxScale: 1.1,
          child: Text(
            _formatDuration(totalDuration),
            style: TextStyle(
              color: isLowTime ? AppColors.warning : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = totalDuration > 0 ? currentPosition / totalDuration : 0.0;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = details.localPosition;
        const width = 300.0; // Approximate width
        final newProgress = (box.dx / width).clamp(0.0, 1.0);
        onSeek(newProgress);
      },
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Tooltip(
          message: 'course_player.playback_speed'.tr(),
          child: IconButton(
            onPressed: onSpeedTap,
            icon: const Icon(Icons.speed, color: Colors.white),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        Row(
          children: [
            Tooltip(
              message: 'course_player.replay_10'.tr(),
              child: IconButton(
                onPressed: onReplay10,
                icon: const Icon(Icons.replay_10, color: Colors.white),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
            Tooltip(
              message: isPlaying
                  ? 'course_player.pause'.tr()
                  : 'course_player.play'.tr(),
              child: IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle,
                  color: Colors.white,
                ),
                iconSize: 32,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
              ),
            ),
            Tooltip(
              message: 'course_player.forward_10'.tr(),
              child: IconButton(
                onPressed: onForward10,
                icon: const Icon(Icons.forward_10, color: Colors.white),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ],
        ),
        Tooltip(
          message: 'course_player.fullscreen'.tr(),
          child: IconButton(
            onPressed: onFullscreen,
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
