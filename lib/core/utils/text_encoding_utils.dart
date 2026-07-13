import 'dart:convert';

class TextEncodingUtils {
  const TextEncodingUtils._();

  static final RegExp _mojibakePattern = RegExp(r'[ØÙÃÂÅâ]');

  static String clean(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || !_mojibakePattern.hasMatch(text)) return text;

    try {
      final decoded = utf8.decode(text.codeUnits, allowMalformed: true).trim();
      if (decoded.isNotEmpty && !_mojibakePattern.hasMatch(decoded)) {
        return decoded;
      }
    } catch (_) {
      // Keep original text if it cannot be decoded safely.
    }

    return text;
  }
}
