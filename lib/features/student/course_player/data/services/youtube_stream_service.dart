import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeStreamService {
  const YouTubeStreamService();

  static String? extractVideoId(String url) {
    final trimmed = url.trim();
    final packageResult = YoutubePlayer.convertUrlToId(trimmed);
    if (packageResult != null) return packageResult;

    final rawIdMatch = RegExp(r'^([A-Za-z0-9_-]{11})$').firstMatch(trimmed);
    return rawIdMatch?.group(1);
  }

  void dispose() {}
}
