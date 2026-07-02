import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flex_video_player/flex_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/app_logger.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/services/youtube_stream_service.dart';
import '../../cubit/course_player_cubit.dart';
import '../../screens/fullscreen_player_screen.dart';

/// Native YouTube video player that uses [youtube_explode_dart] to fetch
/// direct muxed stream URLs (MP4) and plays them via [flex_video_player].
///
/// **No iframes or WebViews** — renders through a native Surface/Texture.
///
/// Features:
/// - Quality fallback: muxed → video-only
/// - Auto-retry on transient network failures (up to [_maxRetries] attempts)
/// - Progress saving every 30 s via [CoursePlayerCubit]
/// - Fullscreen mode via [FullscreenPlayerScreen]
/// - FlexVideoPlayer native controls with speed, seek, fullscreen
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
  FlexVideoController? _flexController;
  StreamSubscription<FlexVideoProgress>? _progressSub;

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
    _progressSub?.cancel();
    _disposeControllers();
    _streamService?.dispose();
    _streamService = null;
    super.dispose();
  }

  void _disposeControllers() {
    _progressSub?.cancel();
    _progressSub = null;
    _flexController?.dispose();
    _flexController = null;
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

      // 2) Build FlexVideoController with the resolved MP4 URL
      _flexController = FlexVideoController(
        source: FlexVideoSource.network(result.streamUrl.toString()),
        config: FlexVideoConfig(
          autoPlay: true,
          wakelock: const FlexWakelockConfig(enabled: true),
          retry: const FlexRetryConfig(enabled: true, maxRetries: 2),
          // Disable built-in fullscreen — we use our own FullscreenPlayerScreen
          fullscreen: const FlexFullscreenConfig(enabled: false),
          controls: const FlexControlsConfig(
            showFullscreen: false, // hide built-in button; custom button used
            showSpeed: true,
            autoHide: true,
          ),
        ),
      );

      // 3) Initialize — FlexVideoPlayer auto-initializes when mounted,
      //    but we still need to call it here so we can seekTo() reliably.
      await _flexController!.initialize();
      if (!mounted) return;

      // 4) Seek to saved position if resuming
      final initialPos = widget.initialPosition ?? 0;
      if (initialPos > 0) {
        await _flexController!.seekTo(Duration(seconds: initialPos));
      }

      // 5) Wire up progress saving via progressStream
      _progressSub = _flexController!.progressStream.listen((progress) {
        if (!mounted) return;
        final seconds = progress.position.inSeconds;
        if (seconds > _lastSavedPosition) {
          _lastSavedPosition = seconds;
          _saveProgressThrottled(seconds);
        }
      });

      _retryCount = 0;

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
      case YouTubeStreamErrorType.noStreams:
      case YouTubeStreamErrorType.network:
        return 'course_player.video_unavailable'.tr();
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Progress saving
  // ══════════════════════════════════════════════════════════════

  DateTime _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _saveProgressThrottled(int seconds) {
    final now = DateTime.now();
    if (now.difference(_lastSaveTime) < _progressInterval) return;
    _lastSaveTime = now;
    _saveProgress(seconds);
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
    final ctrl = _flexController;
    if (ctrl == null) return;

    // Cache navigator before async gap to avoid BuildContext warning
    final navigator = Navigator.of(context, rootNavigator: true);

    await ctrl.pause();
    final currentPos = ctrl.position.inSeconds;

    final result = await navigator.push<int>(
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          videoUrl: widget.videoUrl,
          initialPosition: currentPos,
          courseTitle: widget.courseTitle,
          lessonTitle: widget.lessonTitle,
        ),
      ),
    );

    if (result != null && mounted && _flexController != null) {
      await _flexController!.seekTo(Duration(seconds: result));
      await _flexController!.play();
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return _buildLoadingWidget();
    if (_errorMessage != null) return _buildErrorWidget();
    if (_flexController == null) return _buildLoadingWidget();

    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            FlexVideoPlayer(
              controller: _flexController!,
              onCompleted: () {
                AppLogger.i('[YouTubePlayer] Video completed');
              },
              onError: (error) {
                AppLogger.e('[YouTubePlayer] Playback error: ${error.message}');
                if (mounted) {
                  setState(() {
                    _errorMessage = 'course_player.video_unavailable'.tr();
                  });
                }
              },
            ),
            // Fullscreen button overlay (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openFullscreen,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  // ──────────────── Error ────────────────

  Widget _buildErrorWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade900, Colors.black],
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
