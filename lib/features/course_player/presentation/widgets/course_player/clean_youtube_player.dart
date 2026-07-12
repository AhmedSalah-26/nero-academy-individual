import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../../core/services/app_logger.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_player_cubit.dart';
import '../../screens/fullscreen_player_screen.dart';

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
  static const Duration _progressInterval = Duration(seconds: 30);

  YoutubePlayerController? _controller;
  String? _currentVideoId;
  String? _errorMessage;
  int _lastSavedPosition = 0;
  DateTime _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl == widget.videoUrl) return;

    final newVideoId = _extractVideoId(widget.videoUrl);
    if (newVideoId == null) {
      _controller?.dispose();
      _controller = null;
      _currentVideoId = null;
      setState(() => _errorMessage = 'course_player.video_unavailable'.tr());
      return;
    }

    if (newVideoId != _currentVideoId) {
      _currentVideoId = newVideoId;
      _lastSavedPosition = 0;
      _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);
      _errorMessage = null;
      _controller?.load(newVideoId, startAt: widget.initialPosition ?? 0);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _initializePlayer() {
    _currentVideoId = _extractVideoId(widget.videoUrl);

    if (_currentVideoId == null) {
      AppLogger.e('[YouTubePlayer] Invalid YouTube URL: ${widget.videoUrl}');
      _errorMessage = 'course_player.video_unavailable'.tr();
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: _currentVideoId!,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        enableCaption: false,
        forceHD: true,
        hideThumbnail: true,
        startAt: widget.initialPosition ?? 0,
      ),
    )..addListener(_onPlayerChanged);

    AppLogger.i(
      '[YouTubePlayer] Initialized video: $_currentVideoId, '
      'resumeAt: ${widget.initialPosition ?? 0}s',
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
    if (value.hasError) {
      AppLogger.e('[YouTubePlayer] Playback error: ${value.errorCode}');
      setState(() => _errorMessage = 'course_player.video_unavailable'.tr());
      return;
    }

    final seconds = value.position.inSeconds;
    if (seconds > _lastSavedPosition) {
      _lastSavedPosition = seconds;
      _saveProgressThrottled(seconds);
    }
  }

  void _handleVideoEnded() {
    final controller = _controller;
    if (controller == null) return;

    AppLogger.i('[YouTubePlayer] Video completed');
    _lastSavedPosition = 0;

    controller.pause();
    controller.seekTo(Duration.zero);
    _saveProgressReset();

    if (mounted) setState(() {});
  }

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
      cubit.updateProgress(
        watchedSeconds: seconds,
        lastPosition: seconds,
      );
    }
  }

  void _saveProgressReset() {
    if (!mounted) return;

    CoursePlayerCubit? cubit;
    try {
      cubit = context.read<CoursePlayerCubit>();
    } catch (_) {
      return;
    }

    if (cubit.state.currentLesson != null && cubit.state.enrollmentId != null) {
      final watchedSeconds = cubit.state.currentProgress?.watchedSeconds ?? 0;
      cubit.updateProgress(
        watchedSeconds:
            watchedSeconds > _lastSavedPosition ? watchedSeconds : 0,
        lastPosition: 0,
      );
    }
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final currentPosition = controller.value.position.inSeconds;
    controller.pause();

    final result = await navigator.push<int>(
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          videoUrl: widget.videoUrl,
          initialPosition: currentPosition,
          courseTitle: widget.courseTitle,
          lessonTitle: widget.lessonTitle,
        ),
      ),
    );

    if (!mounted || result == null) return;
    controller.seekTo(Duration(seconds: result));
    if (result <= 0) {
      controller.pause();
      _saveProgressReset();
      setState(() {});
      return;
    }
    controller.play();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final controller = _controller;
    if (_errorMessage != null) return _buildErrorWidget();
    if (controller == null) return _buildLoadingWidget();

    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            YoutubePlayer(
              controller: controller,
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
              onEnded: (_) => _handleVideoEnded(),
            ),
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
