import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/features/student/auth/data/models/user_model.dart';

/// Auth Local Data Source - Handles local caching
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<void> cacheInterests(List<String> interests);
  Future<List<String>> getCachedInterests();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _cachedUserKey = 'CACHED_USER';
  static const String _cachedInterestsKey = 'CACHED_INTERESTS';

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      _cachedUserKey,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(_cachedUserKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_cachedUserKey);
    await sharedPreferences.remove(_cachedInterestsKey);
  }

  @override
  Future<void> cacheInterests(List<String> interests) async {
    await sharedPreferences.setStringList(_cachedInterestsKey, interests);
  }

  @override
  Future<List<String>> getCachedInterests() async {
    return sharedPreferences.getStringList(_cachedInterestsKey) ?? [];
  }
}
