import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/features/student/course_player/data/models/lesson_progress_model.dart';

/// Course Player Local Data Source - For caching
abstract class CoursePlayerLocalDataSource {
  Future<void> cacheLastPosition({
    required String lessonId,
    required int position,
  });

  Future<int?> getLastPosition({required String lessonId});

  Future<void> cacheLessonProgress({
    required String lessonId,
    required LessonProgressModel progress,
  });

  Future<LessonProgressModel?> getCachedLessonProgress({
    required String lessonId,
  });

  Future<void> clearCache();
}

/// Implementation of CoursePlayerLocalDataSource
class CoursePlayerLocalDataSourceImpl implements CoursePlayerLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _lastPositionPrefix = 'lesson_position_';
  static const String _progressPrefix = 'lesson_progress_';

  CoursePlayerLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheLastPosition({
    required String lessonId,
    required int position,
  }) async {
    await sharedPreferences.setInt('$_lastPositionPrefix$lessonId', position);
  }

  @override
  Future<int?> getLastPosition({required String lessonId}) async {
    return sharedPreferences.getInt('$_lastPositionPrefix$lessonId');
  }

  @override
  Future<void> cacheLessonProgress({
    required String lessonId,
    required LessonProgressModel progress,
  }) async {
    final jsonString = jsonEncode(progress.toJson());
    await sharedPreferences.setString('$_progressPrefix$lessonId', jsonString);
  }

  @override
  Future<LessonProgressModel?> getCachedLessonProgress({
    required String lessonId,
  }) async {
    final jsonString = sharedPreferences.getString('$_progressPrefix$lessonId');
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return LessonProgressModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_lastPositionPrefix) ||
          key.startsWith(_progressPrefix)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
