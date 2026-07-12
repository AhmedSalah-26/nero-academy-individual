// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Web implementation for downloading and opening files
Future<void> downloadAndOpenFile({
  required String url,
  required String fileName,
  required Function() onSuccess,
  required Function(String error) onError,
}) async {
  try {
    // For web, open in new tab or trigger download
    html.window.open(url, '_blank');
    onSuccess();
  } catch (e) {
    onError('فشل في فتح الملف: $e');
  }
}
