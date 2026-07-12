import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/errors/exceptions.dart';

/// Course Search Local Data Source - Abstract
abstract class CourseSearchLocalDataSource {
  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearch(String query);
  Future<void> clearRecentSearches();
}

/// Course Search Local Data Source Implementation
class CourseSearchLocalDataSourceImpl implements CourseSearchLocalDataSource {
  final SharedPreferences _prefs;
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  CourseSearchLocalDataSourceImpl(this._prefs);

  @override
  Future<List<String>> getRecentSearches() async {
    try {
      final jsonString = _prefs.getString(_recentSearchesKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      throw CacheException('Failed to get recent searches: $e');
    }
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    try {
      final searches = await getRecentSearches();

      // Remove if already exists
      searches.remove(query);

      // Add to beginning
      searches.insert(0, query);

      // Keep only max items
      final trimmed = searches.take(_maxRecentSearches).toList();

      await _prefs.setString(_recentSearchesKey, json.encode(trimmed));
    } catch (e) {
      throw CacheException('Failed to save recent search: $e');
    }
  }

  @override
  Future<void> clearRecentSearches() async {
    try {
      await _prefs.remove(_recentSearchesKey);
    } catch (e) {
      throw CacheException('Failed to clear recent searches: $e');
    }
  }
}
