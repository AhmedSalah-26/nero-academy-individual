import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../../../core/services/app_logger.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/video_player_notifier_service.dart';
import '../../../data/services/youtube_stream_service.dart';
import '../../cubit/course_player_cubit.dart';
import '../../screens/fullscreen_player_screen.dart';

/// Native YouTube video player that uses [youtube_explode_dart] to fetch
/// direct muxed stream URLs (MP4) and plays them via [video_player] + [chewie].
///
/// **No iframes or WebViews** — this renders through a native Surface/Texture,
/// eliminating the performance issues on low-end devices.
///
/// Features:
/// - Quality fallback: muxed → video-only
/// - Auto-retry on transient network failures (up to [_maxRetries] attempts)
/// - Progress saving every 30 s via [CoursePlayerCubit]
/// - Fullscreen mode via [FullscreenPlayerScreen]
/// - Chewie controls with configurable playback speed
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
  // ──────────────── Constants ────────────────
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _progressInterval = Duration(seconds: 30);

  // ──────────────── State ────────────────
  YouTubeStreamService? _streamService;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;

  bool _isLoading = true;
  String? _errorMessage;
  String? _currentVideoId;
  int _lastSavedPosition = 0;
  int _retryCount = 0;

  @override
  bool get wantKeepAlive => true;

  // ══════════════════════════════════════════════════════════════
  //  Lifecycle
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _streamService = YouTubeStreamService();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      final newVideoId = YouTubeStreamService.extractVideoId(widget.videoUrl);
      if (newVideoId != null && newVideoId != _currentVideoId) {
        AppLogger.i('[YouTubePlayer] Switching to video: $newVideoId');
        _disposeControllers();
        _lastSavedPosition = 0;
        _retryCount = 0;
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        _initializePlayer();
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _disposeControllers();
    _streamService?.dispose();
    _streamService = null;
    super.dispose();
  }

  void _disposeControllers() {
    _progressTimer?.cancel();
    _videoController?.removeListener(_onVideoChanged);
    _chewieController?.dispose();
    _chewieController = null;

    if (_videoController != null) {
      final service = sl<VideoPlayerNotifierService>();
      if (service.controller == _videoController) {
        _videoController = null;
      } else {
        _videoController!.dispose();
        _videoController = null;
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Initialization
  // ══════════════════════════════════════════════════════════════

  Future<void> _initializePlayer() async {
    _currentVideoId = YouTubeStreamService.extractVideoId(widget.videoUrl);

    if (_currentVideoId == null) {
      AppLogger.e('[YouTubePlayer] Invalid YouTube URL: ${widget.videoUrl}');
      if (mounted) {
        setState(() {
          _errorMessage = 'course_player.video_unavailable'.tr();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 1) Resolve stream URL via youtube_explode_dart
      final result = await _streamService!.resolveStreamUrl(widget.videoUrl);

      if (!mounted) return;

      final service = sl<VideoPlayerNotifierService>();
      final isExisting = service.videoUrl == widget.videoUrl &&
          service.controller != null &&
          service.controller!.value.isInitialized;

      if (isExisting) {
        _videoController = service.controller;
        AppLogger.i('[YouTubePlayer] Reusing existing video player controller');
      } else {
        // 2) Create native VideoPlayerController from the direct URL
        _videoController = VideoPlayerController.networkUrl(
          result.streamUrl,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        await _videoController!.initialize();

        if (!mounted) return;

        // Register the new controller
        service.registerPlayer(
          _videoController!,
          widget.videoUrl,
          courseId: context.read<CoursePlayerCubit>().state.courseId ?? '',
          enrollmentId:
              context.read<CoursePlayerCubit>().state.enrollmentId ?? '',
          courseTitle: widget.courseTitle ?? '',
          lessonId:
              context.read<CoursePlayerCubit>().state.currentLesson?.id ?? '',
          lessonTitle: widget.lessonTitle ?? '',
          instructorId: context.read<CoursePlayerCubit>().state.instructorId,
          instructorName:
              context.read<CoursePlayerCubit>().state.instructorName,
          instructorAvatar:
              context.read<CoursePlayerCubit>().state.instructorAvatar,
        );
      }

      if (!mounted) return;

      // 3) Seek to saved position if resuming
      final initialPos = widget.initialPosition ?? 0;
      if (!isExisting && initialPos > 0) {
        await _videoController!.seekTo(Duration(seconds: initialPos));
      }

      // 4) Wire up Chewie with custom controls
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 16 / 9
            : _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white12,
          bufferedColor: Colors.white24,
        ),
        showOptions: true,
        showControlsOnInitialize: true,
        allowFullScreen: false,
        allowPlaybackSpeedChanging: true,
        optionsTranslation: OptionsTranslation(
          playbackSpeedButtonText: 'course_player.playback_speed'.tr(),
          cancelButtonText: 'common.cancel'.tr(),
        ),
        additionalOptions: (context) => [
          OptionItem(
            onTap: (context) {
              Navigator.pop(context);
              _openFullscreen();
            },
            iconData: Icons.fullscreen,
            title: 'course_player.fullscreen'.tr(),
          ),
        ],
      );

      // 5) Listeners
      _videoController!.addListener(_onVideoChanged);
      _startProgressTimer();
      _retryCount = 0; // Reset retry count on success

      if (mounted) {
        setState(() => _isLoading = false);
      }

      AppLogger.i(
        '[YouTubePlayer] Initialized — video: $_currentVideoId, '
        'resumeAt: ${initialPos}s',
      );
    } on YouTubeStreamException catch (e) {
      AppLogger.e('[YouTubePlayer] Stream error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorMessage(e.type);
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('[YouTubePlayer] Unexpected error', e, stack);

      // Retry on transient failures
      if (_retryCount < _maxRetries) {
        _retryCount++;
        AppLogger.i(
          '[YouTubePlayer] Retrying... attempt $_retryCount/$_maxRetries',
        );
        await Future.delayed(_retryDelay);
        if (mounted) {
          _disposeControllers();
          _initializePlayer();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _errorMessage = 'course_player.video_unavailable'.tr();
          _isLoading = false;
        });
      }
    }
  }

  String _mapErrorMessage(YouTubeStreamErrorType type) {
    switch (type) {
      case YouTubeStreamErrorType.invalidUrl:
        return 'course_player.video_unavailable'.tr();
      case YouTubeStreamErrorType.noStreams:
        return 'course_player.video_unavailable'.tr();
      case YouTubeStreamErrorType.network:
        return 'course_player.video_unavailable'.tr();
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Playback listeners & progress
  // ══════════════════════════════════════════════════════════════

  void _onVideoChanged() {
    if (!mounted || _videoController == null) return;

    if (_videoController!.value.hasError) {
      AppLogger.e(
        '[YouTubePlayer] Playback error: '
        '${_videoController!.value.errorDescription}',
      );
      setState(() {
        _errorMessage = 'course_player.video_unavailable'.tr();
      });
      return;
    }

    // Trigger a rebuild so Chewie reflects the current state
    setState(() {});
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_progressInterval, (_) {
      if (!mounted ||
          _videoController == null ||
          !_videoController!.value.isInitialized) {
        return;
      }
      if (!_videoController!.value.isPlaying) {
        return;
      }

      final seconds = _videoController!.value.position.inSeconds;
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
      if (seconds % 60 == 0) {
        AppLogger.i('[YouTubePlayer] Saving watch time: ${seconds}s');
      }
      cubit.updateProgress(
        watchedSeconds: seconds,
        lastPosition: seconds,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Fullscreen
  // ══════════════════════════════════════════════════════════════

  Future<void> _openFullscreen() async {
    if (_videoController == null) return;

    _videoController!.pause();
    final currentPos = _videoController!.value.position.inSeconds;

    final result = await Navigator.of(context, rootNavigator: true).push<int>(
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          videoUrl: widget.videoUrl,
          initialPosition: currentPos,
          courseTitle: widget.courseTitle,
          lessonTitle: widget.lessonTitle,
        ),
      ),
    );

    // Resume from the position returned by fullscreen
    if (result != null && mounted && _videoController != null) {
      await _videoController!.seekTo(Duration(seconds: result));
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    if (_isLoading) return _buildLoadingWidget();
    if (_errorMessage != null) return _buildErrorWidget();
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return _buildLoadingWidget();
    }

    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 16 / 9
            : _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  // ──────────────── Loading ────────────────

  Widget _buildLoadingWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101010), Color(0xFF000000)],
          ),
        ),
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────── Error with retry ────────────────

  Widget _buildErrorWidget() {
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
                _errorMessage ?? 'course_player.video_unavailable'.tr(),
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
