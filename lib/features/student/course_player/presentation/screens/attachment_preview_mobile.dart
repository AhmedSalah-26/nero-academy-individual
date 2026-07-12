import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

/// Mobile implementation for downloading and opening files
Future<void> downloadAndOpenFile({
  required String url,
  required String fileName,
  required Function() onSuccess,
  required Function(String error) onError,
}) async {
  try {
    // Get temp directory
    final tempDir = await getTemporaryDirectory();
    final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
    final filePath = '${tempDir.path}/$safeFileName';

    // Download file
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Open file
      final result = await OpenFilex.open(filePath);
      if (result.type == ResultType.done) {
        onSuccess();
      } else {
        onError('لا يمكن فتح هذا النوع من الملفات');
      }
    } else {
      onError('فشل في تحميل الملف (${response.statusCode})');
    }
  } catch (e) {
    onError('فشل في تحميل الملف: $e');
  }
}
