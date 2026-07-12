import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/features/student/home/data/models/banner_model.dart';
import 'package:lms_platform/features/student/home/data/models/category_model.dart';
import 'package:lms_platform/features/student/home/data/models/course_model.dart';

/// Home Local Data Source - Handles local caching for Home
abstract class HomeLocalDataSource {
  Future<List<BannerModel>> getCachedBanners();
  Future<void> cacheBanners(List<BannerModel> banners);
  Future<List<CategoryModel>> getCachedCategories();
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<List<CourseModel>> getCachedCourses(String key);
  Future<void> cacheCourses(String key, List<CourseModel> courses);
  Future<void> clearCache();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final SharedPreferences prefs;

  static const _bannersKey = 'cached_banners';
  static const _categoriesKey = 'cached_categories';
  static const _cacheTimestampKey = 'home_cache_timestamp';
  static const _cacheDuration = Duration(hours: 1);

  HomeLocalDataSourceImpl(this.prefs);

  bool _isCacheValid() {
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  @override
  Future<List<BannerModel>> getCachedBanners() async {
    if (!_isCacheValid()) {
      throw const CacheException('Cache expired');
    }
    final jsonString = prefs.getString(_bannersKey);
    if (jsonString == null) {
      throw const CacheException('No cached banners');
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => BannerModel.fromJson(j)).toList();
  }

  @override
  Future<void> cacheBanners(List<BannerModel> banners) async {
    final jsonList = banners.map((b) => b.toJson()).toList();
    await prefs.setString(_bannersKey, json.encode(jsonList));
    await prefs.setInt(
        _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    if (!_isCacheValid()) {
      throw const CacheException('Cache expired');
    }
    final jsonString = prefs.getString(_categoriesKey);
    if (jsonString == null) {
      throw const CacheException('No cached categories');
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => CategoryModel.fromJson(j)).toList();
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    final jsonList = categories.map((c) => c.toJson()).toList();
    await prefs.setString(_categoriesKey, json.encode(jsonList));
  }

  @override
  Future<List<CourseModel>> getCachedCourses(String key) async {
    if (!_isCacheValid()) {
      throw const CacheException('Cache expired');
    }
    final jsonString = prefs.getString('cached_courses_$key');
    if (jsonString == null) {
      throw CacheException('No cached courses for $key');
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => CourseModel.fromJson(j)).toList();
  }

  @override
  Future<void> cacheCourses(String key, List<CourseModel> courses) async {
    final jsonList = courses.map((c) => c.toJson()).toList();
    await prefs.setString('cached_courses_$key', json.encode(jsonList));
  }

  @override
  Future<void> clearCache() async {
    await prefs.remove(_bannersKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_cacheTimestampKey);
    // Clear all course caches
    final keys = prefs.getKeys().where((k) => k.startsWith('cached_courses_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
