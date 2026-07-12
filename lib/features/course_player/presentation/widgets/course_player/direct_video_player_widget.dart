import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/services/app_logger.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_player_cubit.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/video_player_notifier_service.dart';

class DirectVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isDark;
  final int? initialPosition;

  const DirectVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isDark,
    this.initialPosition,
  });

  @override
  State<DirectVideoPlayerWidget> createState() =>
      _DirectVideoPlayerWidgetState();
}

class _DirectVideoPlayerWidgetState extends State<DirectVideoPlayerWidget> {
  late VideoPlayerController _controller;
  Timer? _progressTimer;
  bool _hasError = false;
  int _lastSavedPosition = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final service = sl<VideoPlayerNotifierService>();
      final isExisting = service.videoUrl == widget.videoUrl && service.controller != null && service.controller!.value.isInitialized;

      if (isExisting) {
        _controller = service.controller!;
        AppLogger.i('[DirectVideoPlayer] Reusing existing video player controller');
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        await _controller.initialize();

        if (!mounted) return;

        // Register the new controller
        final cubitState = context.read<CoursePlayerCubit>().state;
        service.registerPlayer(
          _controller,
          widget.videoUrl,
          courseId: cubitState.courseId ?? '',
          enrollmentId: cubitState.enrollmentId ?? '',
          courseTitle: cubitState.courseTitle ?? '',
          lessonId: cubitState.currentLesson?.id ?? '',
          lessonTitle: cubitState.currentLesson?.titleAr ?? '',
          instructorId: cubitState.instructorId,
          instructorName: cubitState.instructorName,
          instructorAvatar: cubitState.instructorAvatar,
        );
      }

      if (!mounted) return;

      final initialPosition = widget.initialPosition ?? 0;
      if (!isExisting && initialPosition > 0) {
        await _controller.seekTo(Duration(seconds: initialPosition));
      }

      _controller.addListener(_onPlayerChanged);
      _startProgressTimer();

      if (mounted) setState(() {});
    } catch (e, stack) {
      AppLogger.e('[DirectVideoPlayer] Failed to initialize', e, stack);
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onPlayerChanged() {
    if (!mounted) return;

    if (_controller.value.hasError && !_hasError) {
      AppLogger.e(
        '[DirectVideoPlayer] Playback error: '
        '${_controller.value.errorDescription}',
      );
      setState(() => _hasError = true);
      return;
    }

    setState(() {});
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !_controller.value.isInitialized) return;
      if (!_controller.value.isPlaying) return;

      final seconds = _controller.value.position.inSeconds;
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

  Future<void> _togglePlayPause() async {
    if (!_controller.value.isInitialized) return;

    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  Future<void> _seekBy(Duration delta) async {
    if (!_controller.value.isInitialized) return;

    final duration = _controller.value.duration;
    final target = _controller.value.position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target;

    await _controller.seekTo(clamped);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.removeListener(_onPlayerChanged);
    
    final service = sl<VideoPlayerNotifierService>();
    if (service.controller != _controller) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildErrorWidget();

    if (!_controller.value.isInitialized) {
      return _buildLoadingWidget();
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio == 0
          ? 16 / 9
          : _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          if (!_controller.value.isPlaying)
            _CircleControlButton(
              icon: Icons.play_arrow_rounded,
              size: 68,
              onPressed: _togglePlayPause,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final value = _controller.value;
    final position = value.position;
    final duration = value.duration;
    final maxSeconds =
        duration.inMilliseconds <= 0 ? 1.0 : duration.inMilliseconds.toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xCC000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              min: 0,
              max: maxSeconds,
              value: position.inMilliseconds
                  .clamp(0, maxSeconds.toInt())
                  .toDouble(),
              activeColor: AppColors.primary,
              inactiveColor: Colors.white30,
              onChanged: (value) {
                _controller.seekTo(Duration(milliseconds: value.round()));
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _seekBy(const Duration(seconds: -10)),
                icon: const Icon(Icons.replay_10, color: Colors.white),
                tooltip: 'رجوع 10 ثواني',
              ),
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => _seekBy(const Duration(seconds: 10)),
                icon: const Icon(Icons.forward_10, color: Colors.white),
                tooltip: 'تقديم 10 ثواني',
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildLoadingWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'common.loading'.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
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

class _CircleControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;

  const _CircleControlButton({
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.6),
        ),
      ),
    );
  }
}
