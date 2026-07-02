import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flex_video_player/flex_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/screen_protection_service.dart';
import '../../data/services/youtube_stream_service.dart';

/// Landscape fullscreen player for YouTube videos.
///
/// Uses [YouTubeStreamService] to fetch direct stream URLs (no iframes),
/// then plays natively via [flex_video_player].
///
/// Returns the last playback position (in seconds) via [Navigator.pop]
/// so the caller can resume from where the user left off.
class FullscreenPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final int initialPosition;
  final String? courseTitle;
  final String? lessonTitle;

  const FullscreenPlayerScreen({
    super.key,
    required this.videoUrl,
    this.initialPosition = 0,
    this.courseTitle,
    this.lessonTitle,
  });

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  YouTubeStreamService? _streamService;
  FlexVideoController? _flexController;
  StreamSubscription<FlexVideoProgress>? _progressSub;

  bool _isLoading = true;
  String? _errorMessage;
  int _currentPosition = 0;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _streamService = YouTubeStreamService();
    ScreenProtectionService.enable();
    unawaited(_setupFullscreen());
    _initializePlayer();
  }

  @override
  void dispose() {
    unawaited(_restorePortraitMode());
    _progressSub?.cancel();
    _flexController?.dispose();
    _streamService?.dispose();
    _streamService = null;
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  Orientation & System UI
  // ══════════════════════════════════════════════════════════════

  Future<void> _setupFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restorePortraitMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  //  Player initialization
  // ══════════════════════════════════════════════════════════════

  Future<void> _initializePlayer() async {
    final videoId = YouTubeStreamService.extractVideoId(widget.videoUrl);

    if (videoId == null) {
      AppLogger.e('[Fullscreen] Invalid YouTube URL: ${widget.videoUrl}');
      if (mounted) {
        setState(() {
          _errorMessage = 'errors.invalid_video_url'.tr();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 1) Resolve direct stream URL
      final result = await _streamService!.resolveStreamUrl(widget.videoUrl);
      if (!mounted) return;

      // 2) Build FlexVideoController with positional URL
      _flexController = FlexVideoController(
        source: FlexVideoSource.network(result.streamUrl.toString()),
        config: const FlexVideoConfig(
          autoPlay: true,
          wakelock: FlexWakelockConfig(enabled: true),
          retry: FlexRetryConfig(enabled: true, maxRetries: 2),
          // We own the fullscreen lifecycle — disable the built-in handler
          // so it never restores orientation or system UI under us.
          fullscreen: FlexFullscreenConfig(
            enabled: false,
            hideSystemUI: false,
          ),
          controls: FlexControlsConfig(
            showFullscreen: false,
            showSpeed: true,
          ),
        ),
      );

      // 3) Initialize
      await _flexController!.initialize();
      if (!mounted) return;

      // 4) Seek to saved position
      if (widget.initialPosition > 0) {
        await _flexController!.seekTo(Duration(seconds: widget.initialPosition));
      }

      // 5) Track current position via progressStream
      _progressSub = _flexController!.progressStream.listen((progress) {
        if (!mounted) return;
        _currentPosition = progress.position.inSeconds;
      });

      if (mounted) {
        setState(() => _isLoading = false);
        // Re-apply immersive mode after FlexVideoPlayer mounts
        // (the widget may reset system UI during its own initialization)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_setupFullscreen());
        });
      }

      AppLogger.i(
        '[Fullscreen] Player initialized at position: ${widget.initialPosition}s',
      );
    } on YouTubeStreamException catch (e) {
      AppLogger.e('[Fullscreen] Stream error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'course_player.video_unavailable'.tr();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('[Fullscreen] Failed to initialize', e, stack);
      if (mounted) {
        setState(() {
          _errorMessage = 'course_player.video_unavailable'.tr();
          _isLoading = false;
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Navigation
  // ══════════════════════════════════════════════════════════════

  Future<void> _exitFullscreen() async {
    if (_isExiting) return;
    _isExiting = true;
    await _restorePortraitMode();
    if (mounted) {
      Navigator.of(context).pop(_currentPosition);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exitFullscreen());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? _buildLoadingScreen()
            : _errorMessage != null
                ? _buildErrorScreen()
                : Stack(
                    children: [
                      FlexVideoPlayer(
                        controller: _flexController!,
                        onCompleted: () => unawaited(_exitFullscreen()),
                        onError: (error) {
                          AppLogger.e(
                            '[Fullscreen] Playback error: ${error.message}',
                          );
                          if (mounted) {
                            setState(() {
                              _errorMessage =
                                  'course_player.video_unavailable'.tr();
                            });
                          }
                        },
                      ),
                      // Exit fullscreen button (top-left)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      unawaited(_exitFullscreen()),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.courseTitle != null)
                                        Text(
                                          widget.courseTitle!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (widget.lessonTitle != null)
                                        Text(
                                          widget.lessonTitle!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════════════

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'common.loading'.tr(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'errors.invalid_video_url'.tr(),
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => unawaited(_exitFullscreen()),
            icon: const Icon(Icons.arrow_back),
            label: Text('common.back'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}