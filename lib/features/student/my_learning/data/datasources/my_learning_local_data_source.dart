import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/features/student/my_learning/data/models/enrollment_model.dart';

/// My Learning Local Data Source - Abstract Contract
abstract class MyLearningLocalDataSource {
  Future<List<EnrollmentModel>> getCachedEnrollments(String userId);
  Future<void> cacheEnrollments(
      String userId, List<EnrollmentModel> enrollments);
  Future<EnrollmentModel?> getCachedContinueLearning(String userId);
  Future<void> cacheContinueLearning(
      String userId, EnrollmentModel? enrollment);
  Future<void> clearCache(String userId);
}

/// My Learning Local Data Source Implementation
class MyLearningLocalDataSourceImpl implements MyLearningLocalDataSource {
  final SharedPreferences _prefs;

  MyLearningLocalDataSourceImpl(this._prefs);

  static const _enrollmentsKey = 'my_learning_enrollments_';
  static const _continueKey = 'my_learning_continue_';

  @override
  Future<List<EnrollmentModel>> getCachedEnrollments(String userId) async {
    final jsonStr = _prefs.getString('$_enrollmentsKey$userId');
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.map((j) => EnrollmentModel.fromJson(j)).toList();
  }

  @override
  Future<void> cacheEnrollments(
    String userId,
    List<EnrollmentModel> enrollments,
  ) async {
    final jsonList = enrollments.map((e) => e.toJson()).toList();
    await _prefs.setString('$_enrollmentsKey$userId', json.encode(jsonList));
  }

  @override
  Future<EnrollmentModel?> getCachedContinueLearning(String userId) async {
    final jsonStr = _prefs.getString('$_continueKey$userId');
    if (jsonStr == null) return null;

    return EnrollmentModel.fromJson(json.decode(jsonStr));
  }

  @override
  Future<void> cacheContinueLearning(
    String userId,
    EnrollmentModel? enrollment,
  ) async {
    if (enrollment == null) {
      await _prefs.remove('$_continueKey$userId');
    } else {
      await _prefs.setString(
        '$_continueKey$userId',
        json.encode(enrollment.toJson()),
      );
    }
  }

  @override
  Future<void> clearCache(String userId) async {
    await _prefs.remove('$_enrollmentsKey$userId');
    await _prefs.remove('$_continueKey$userId');
  }
}
