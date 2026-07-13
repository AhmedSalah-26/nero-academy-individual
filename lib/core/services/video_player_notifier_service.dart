import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'app_logger.dart';

class VideoPlayerNotifierService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('nero_academy/media_notification');

  VideoPlayerController? _controller;
  String? _videoUrl;

  // Metadata
  String? courseId;
  String? enrollmentId;
  String? courseTitle;
  String? lessonId;
  String? lessonTitle;
  String? teacherId;
  String? instructorName;
  String? instructorAvatar;

  bool _isPlayerScreenActive = false;

  final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  VideoPlayerController? get controller => _controller;
  String? get videoUrl => _videoUrl;
  bool get isPlayerScreenActive => _isPlayerScreenActive;

  VideoPlayerNotifierService() {
    _channel.setMethodCallHandler(_handleNativeAction);
  }

  void registerPlayer(
    VideoPlayerController controller,
    String videoUrl, {
    required String courseId,
    required String enrollmentId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
    String? teacherId,
    String? instructorName,
    String? instructorAvatar,
  }) {
    AppLogger.i(
        '[VideoPlayerNotifierService] Registering player for $videoUrl');

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
    this.teacherId = teacherId;
    this.instructorName = instructorName;
    this.instructorAvatar = instructorAvatar;

    _controller!.addListener(_onControllerChanged);
    isPlaying.value = _controller!.value.isPlaying;
    unawaited(_showOrUpdateNotification(force: true));

    notifyListeners();
  }

  void _onControllerChanged() {
    if (_controller != null) {
      isPlaying.value = _controller!.value.isPlaying;
      unawaited(_showOrUpdateNotification());
      notifyListeners();
    }
  }

  void setPlayerScreenActive(bool active) {
    AppLogger.i('[VideoPlayerNotifierService] Player screen active: $active');
    _isPlayerScreenActive = active;

    if (active) {
      // Back on the player screen — hide the persistent notification
      isVisible.value = false;
      unawaited(_hideNotification());
    } else {
      // Left the player screen — pause the video and show the notification
      // so the user can tap it to come back and resume.
      if (_controller != null && _controller!.value.isInitialized) {
        _controller!.pause();
        isVisible.value = true;
        unawaited(_showOrUpdateNotification(force: true));
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
    AppLogger.i('[VideoPlayerNotifierService] Dismissing media session');
    isVisible.value = false;
    if (_controller != null) {
      _controller!.removeListener(_onControllerChanged);
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
    _videoUrl = null;
    unawaited(_hideNotification());
    notifyListeners();
  }

  Future<void> _handleNativeAction(MethodCall call) async {
    if (call.method != 'mediaAction') return;

    switch (call.arguments as String?) {
      case 'close':
        dismiss();
        break;
    }
  }

  Future<void> _showOrUpdateNotification({bool force = false}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    // Only show once (force=true on register) — no live position updates needed
    if (!force) return;

    try {
      await _channel.invokeMethod<void>('show', {
        'title': _safeText(lessonTitle, fallback: courseTitle ?? 'نسق'),
        'subtitle': _safeText(courseTitle, fallback: ''),
        'continueLabel': 'كمّل الدرس',
        'ongoing': !_isPlayerScreenActive,
      });
    } catch (e) {
      AppLogger.w(
          '[VideoPlayerNotifierService] Media notification unavailable: $e');
    }
  }

  Future<void> _hideNotification() async {
    try {
      await _channel.invokeMethod<void>('hide');
    } catch (_) {}
  }

  String _safeText(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_onControllerChanged);
      _controller!.dispose();
    }
    unawaited(_hideNotification());
    super.dispose();
  }
}
