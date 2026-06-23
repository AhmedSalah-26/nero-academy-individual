import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'app_logger.dart';

class VideoPlayerNotifierService extends ChangeNotifier {
  VideoPlayerController? _controller;
  String? _videoUrl;

  // Metadata
  String? courseId;
  String? enrollmentId;
  String? courseTitle;
  String? lessonId;
  String? lessonTitle;
  String? instructorId;
  String? instructorName;
  String? instructorAvatar;

  bool _isPlayerScreenActive = false;

  final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  VideoPlayerController? get controller => _controller;
  String? get videoUrl => _videoUrl;
  bool get isPlayerScreenActive => _isPlayerScreenActive;

  void registerPlayer(
    VideoPlayerController controller,
    String videoUrl, {
    required String courseId,
    required String enrollmentId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
    String? instructorId,
    String? instructorName,
    String? instructorAvatar,
  }) {
    AppLogger.i('[VideoPlayerNotifierService] Registering player for $videoUrl');
    
    if (_controller != null && _controller != controller) {
      _controller!.removeListener(_onControllerChanged);
      _controller!.dispose();
    }

    _controller = controller;
    _videoUrl = videoUrl;
    this.courseId = courseId;
    this.enrollmentId = enrollmentId;
    this.courseTitle = courseTitle;
    this.lessonId = lessonId;
    this.lessonTitle = lessonTitle;
    this.instructorId = instructorId;
    this.instructorName = instructorName;
    this.instructorAvatar = instructorAvatar;

    _controller!.addListener(_onControllerChanged);
    isPlaying.value = _controller!.value.isPlaying;
    
    notifyListeners();
  }

  void _onControllerChanged() {
    if (_controller != null) {
      isPlaying.value = _controller!.value.isPlaying;
      notifyListeners();
    }
  }

  void setPlayerScreenActive(bool active) {
    AppLogger.i('[VideoPlayerNotifierService] Player screen active: $active');
    _isPlayerScreenActive = active;

    if (active) {
      // If we entered the player screen, hide the mini player overlay
      isVisible.value = false;
    } else {
      // If we left the player screen, and we have an active player that was playing/initialized
      if (_controller != null && _controller!.value.isInitialized) {
        // Automatically pause video
        _controller!.pause();
        // Show the mini player
        isVisible.value = true;
      }
    }
    notifyListeners();
  }

  void play() {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.play();
    }
  }

  void pause() {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.pause();
    }
  }

  void dismiss() {
    AppLogger.i('[VideoPlayerNotifierService] Dismissing mini-player');
    isVisible.value = false;
    if (_controller != null) {
      _controller!.removeListener(_onControllerChanged);
      _controller!.dispose();
      _controller = null;
    }
    _videoUrl = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_onControllerChanged);
      _controller!.dispose();
    }
    super.dispose();
  }
}
