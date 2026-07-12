import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_player/presentation/cubit/course_player_cubit.dart';
import 'package:lms_platform/features/student/course_player/presentation/screens/fullscreen_player_screen.dart';

/// YouTube player using the official embedded YouTube player.
class YouTubePlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isDark;
  final int? initialPosition;
  final String? courseTitle;
  final String? lessonTitle;

  const YouTubePlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isDark,
    this.initialPosition,
    this.courseTitle,
    this.lessonTitle,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget>
    with AutomaticKeepAliveClientMixin {
  YoutubePlayerController? _controller;
  Timer? _progressTimer;
  String? _videoId;
  bool _hasError = false;
  int _lastSavedPosition = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (_videoId == null) {
      AppLogger.e('[YouTubePlayer] Invalid YouTube URL: ${widget.videoUrl}');
      setState(() => _hasError = true);
      return;
    }

    final controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        startAt: widget.initialPosition ?? 0,
        enableCaption: false,
        forceHD: true,
        hideThumbnail: true,
        hideControls: false,
        controlsVisibleAtStart: true,
        showLiveFullscreenButton: false,
        useHybridComposition: true,
      ),
    );

    controller.addListener(_onPlayerChanged);
    _controller = controller;
    _startProgressTimer();
  }

  void _onPlayerChanged() {
    final controller = _controller;
    if (!mounted || controller == null) return;

    if (controller.value.hasError && !_hasError) {
      AppLogger.e('[YouTubePlayer] Player error detected');
      setState(() => _hasError = true);
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final controller = _controller;
      if (!mounted || controller == null || !controller.value.isPlaying) {
        return;
      }

      final seconds = controller.value.position.inSeconds;
      if (seconds > _lastSavedPosition) {
        _lastSavedPosition = seconds;
        _saveProgress(seconds);
      }
    });
  }

  void _saveProgress(int seconds) {
    if (seconds <= 0 || !mounted) return;

    CoursePlayerCubit? cubit;
    try {
      cubit = context.read<CoursePlayerCubit>();
    } catch (_) {
      return;
    }

    if (cubit.state.currentLesson != null && cubit.state.enrollmentId != null) {
      cubit.updateProgress(
        watchedSeconds: seconds,
        lastPosition: seconds,
      );
    }
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null) return;

    controller.pause();
    final currentPosition = controller.value.position.inSeconds;

    final result = await Navigator.of(context, rootNavigator: true).push<int>(
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          videoUrl: widget.videoUrl,
          initialPosition: currentPosition,
          courseTitle: widget.courseTitle,
          lessonTitle: widget.lessonTitle,
        ),
      ),
    );

    if (result != null && mounted) {
      controller.seekTo(Duration(seconds: result));
    }
  }

  @override
  void didUpdateWidget(covariant YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl == widget.videoUrl) return;

    final newVideoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    final controller = _controller;
    if (newVideoId == null || controller == null || newVideoId == _videoId) {
      return;
    }

    _videoId = newVideoId;
    _lastSavedPosition = 0;
    controller.load(newVideoId, startAt: widget.initialPosition ?? 0);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onPlayerChanged);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final controller = _controller;
    if (_hasError || controller == null) return _buildErrorWidget();

    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(
          controller: controller,
          bufferIndicator: const SizedBox.shrink(),
          showVideoProgressIndicator: false,
          progressIndicatorColor: AppColors.primary,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
            bufferedColor: Colors.white24,
            backgroundColor: Colors.white12,
          ),
          topActions: const [],
          bottomActions: [
            const SizedBox(width: 8),
            const CurrentPosition(),
            const SizedBox(width: 8),
            const ProgressBar(
              isExpanded: true,
              colors: ProgressBarColors(
                playedColor: AppColors.primary,
                handleColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(width: 8),
            const RemainingDuration(),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _openFullscreen,
              icon: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'course_player.video_unavailable'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
