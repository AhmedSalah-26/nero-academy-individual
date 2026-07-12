import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/features/student/course_details/data/models/course_details_model.dart';

/// Course Details Local Data Source - Cache
abstract class CourseDetailsLocalDataSource {
  Future<CourseDetailsModel?> getCachedCourseDetails(String courseId);
  Future<void> cacheCourseDetails(String courseId, CourseDetailsModel course);
  Future<void> clearCache(String courseId);
}

class CourseDetailsLocalDataSourceImpl implements CourseDetailsLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _cachePrefix = 'course_details_';

  CourseDetailsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<CourseDetailsModel?> getCachedCourseDetails(String courseId) async {
    final jsonString = sharedPreferences.getString('$_cachePrefix$courseId');
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return CourseDetailsModel.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> cacheCourseDetails(
      String courseId, CourseDetailsModel course) async {
    // Note: CourseDetailsModel doesn't have toJson, so we skip caching for now
    // In production, implement toJson method
  }

  @override
  Future<void> clearCache(String courseId) async {
    await sharedPreferences.remove('$_cachePrefix$courseId');
  }
}
