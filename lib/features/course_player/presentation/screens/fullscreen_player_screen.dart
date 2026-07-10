import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/screen_protection_service.dart';
import '../../../../core/theme/app_colors.dart';

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
  YoutubePlayerController? _controller;
  String? _errorMessage;
  int _currentPosition = 0;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    ScreenProtectionService.enable();
    unawaited(_setupFullscreen());
    _initializePlayer();
  }

  @override
  void dispose() {
    unawaited(_restorePortraitMode());
    ScreenProtectionService.disable();
    _controller?.removeListener(_onPlayerChanged);
    _controller?.dispose();
    super.dispose();
  }

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

  void _initializePlayer() {
    final videoId = _extractVideoId(widget.videoUrl);

    if (videoId == null) {
      AppLogger.e('[Fullscreen] Invalid YouTube URL: ${widget.videoUrl}');
      _errorMessage = 'errors.invalid_video_url'.tr();
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        enableCaption: false,
        forceHD: true,
        hideThumbnail: true,
        startAt: widget.initialPosition,
      ),
    )..addListener(_onPlayerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_setupFullscreen());
    });

    AppLogger.i(
      '[Fullscreen] Player initialized at position: ${widget.initialPosition}s',
    );
  }

  static String? _extractVideoId(String url) {
    final trimmed = url.trim();
    final packageResult = YoutubePlayer.convertUrlToId(trimmed);
    if (packageResult != null) return packageResult;

    final rawIdMatch = RegExp(r'^([A-Za-z0-9_-]{11})$').firstMatch(trimmed);
    return rawIdMatch?.group(1);
  }

  void _onPlayerChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final value = controller.value;
    _currentPosition = value.position.inSeconds;

    if (value.hasError) {
      AppLogger.e('[Fullscreen] Playback error: ${value.errorCode}');
      setState(() => _errorMessage = 'course_player.video_unavailable'.tr());
    }
  }

  Future<void> _exitFullscreen() async {
    if (_isExiting) return;
    _isExiting = true;
    await _restorePortraitMode();
    if (mounted) {
      Navigator.of(context).pop(_currentPosition);
    }
  }

  Future<void> _handleVideoEnded() async {
    final controller = _controller;
    if (controller != null) {
      controller.pause();
      controller.seekTo(Duration.zero);
    }
    _currentPosition = 0;
    await _exitFullscreen();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exitFullscreen());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _errorMessage != null || controller == null
            ? _buildErrorScreen()
            : Stack(
                children: [
                  Center(
                    child: YoutubePlayer(
                      controller: controller,
                      aspectRatio: 16 / 9,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: AppColors.primary,
                      progressColors: const ProgressBarColors(
                        playedColor: AppColors.primary,
                        handleColor: AppColors.primary,
                      ),
                      topActions: const [],
                      bottomActions: const [
                        CurrentPosition(),
                        ProgressBar(isExpanded: true),
                        RemainingDuration(),
                        PlaybackSpeedButton(),
                      ],
                      onEnded: (_) => unawaited(_handleVideoEnded()),
                    ),
                  ),
                  if (widget.courseTitle != null || widget.lessonTitle != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                      ),
                    ),
                ],
              ),
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
