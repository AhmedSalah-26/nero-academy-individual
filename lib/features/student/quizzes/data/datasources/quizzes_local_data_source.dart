import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Quizzes Local Data Source - Handles local caching
abstract class QuizzesLocalDataSource {
  /// Cache quiz answers during attempt
  Future<void> cacheQuizAnswers({
    required String attemptId,
    required Map<String, List<String>> answers,
  });

  /// Get cached quiz answers
  Future<Map<String, List<String>>?> getCachedAnswers({
    required String attemptId,
  });

  /// Clear cached answers
  Future<void> clearCachedAnswers({required String attemptId});

  /// Cache quiz start time
  Future<void> cacheQuizStartTime({
    required String attemptId,
    required DateTime startTime,
  });

  /// Get cached start time
  Future<DateTime?> getCachedStartTime({required String attemptId});
}

/// Quizzes Local Data Source Implementation
class QuizzesLocalDataSourceImpl implements QuizzesLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _answersPrefix = 'quiz_answers_';
  static const String _startTimePrefix = 'quiz_start_';

  QuizzesLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheQuizAnswers({
    required String attemptId,
    required Map<String, List<String>> answers,
  }) async {
    final key = '$_answersPrefix$attemptId';
    final jsonString = jsonEncode(answers);
    await sharedPreferences.setString(key, jsonString);
  }

  @override
  Future<Map<String, List<String>>?> getCachedAnswers({
    required String attemptId,
  }) async {
    final key = '$_answersPrefix$attemptId';
    final jsonString = sharedPreferences.getString(key);
    if (jsonString == null) return null;

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        (value as List).map((e) => e as String).toList(),
      ),
    );
  }

  @override
  Future<void> clearCachedAnswers({required String attemptId}) async {
    final key = '$_answersPrefix$attemptId';
    await sharedPreferences.remove(key);
  }

  @override
  Future<void> cacheQuizStartTime({
    required String attemptId,
    required DateTime startTime,
  }) async {
    final key = '$_startTimePrefix$attemptId';
    await sharedPreferences.setString(key, startTime.toIso8601String());
  }

  @override
  Future<DateTime?> getCachedStartTime({required String attemptId}) async {
    final key = '$_startTimePrefix$attemptId';
    final timeString = sharedPreferences.getString(key);
    if (timeString == null) return null;
    return DateTime.parse(timeString);
  }
}
