import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/features/student/wishlist/data/models/wishlist_item_model.dart';

/// Wishlist Local Data Source - Local caching
abstract class WishlistLocalDataSource {
  Future<List<WishlistItemModel>?> getCachedWishlist(String userId);
  Future<void> cacheWishlist(String userId, List<WishlistItemModel> items);
  Future<void> clearCachedWishlist(String userId);
  Future<Set<String>> getCachedWishlistCourseIds(String userId);
  Future<void> addToCachedWishlistIds(String userId, String courseId);
  Future<void> removeFromCachedWishlistIds(String userId, String courseId);
}

/// Wishlist Local Data Source Implementation
class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _wishlistKeyPrefix = 'CACHED_WISHLIST_';
  static const String _wishlistIdsKeyPrefix = 'CACHED_WISHLIST_IDS_';

  WishlistLocalDataSourceImpl({required this.sharedPreferences});

  String _getWishlistKey(String userId) => '$_wishlistKeyPrefix$userId';
  String _getWishlistIdsKey(String userId) => '$_wishlistIdsKeyPrefix$userId';

  @override
  Future<List<WishlistItemModel>?> getCachedWishlist(String userId) async {
    try {
      final jsonString = sharedPreferences.getString(_getWishlistKey(userId));
      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get cached wishlist: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheWishlist(
      String userId, List<WishlistItemModel> items) async {
    try {
      final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
      await sharedPreferences.setString(_getWishlistKey(userId), jsonString);

      // Also cache course IDs for quick lookup
      final courseIds = items.map((e) => e.courseId).toSet();
      await sharedPreferences.setStringList(
        _getWishlistIdsKey(userId),
        courseIds.toList(),
      );
    } catch (e) {
      throw CacheException('Failed to cache wishlist: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCachedWishlist(String userId) async {
    try {
      await sharedPreferences.remove(_getWishlistKey(userId));
      await sharedPreferences.remove(_getWishlistIdsKey(userId));
    } catch (e) {
      throw CacheException('Failed to clear cached wishlist: ${e.toString()}');
    }
  }

  @override
  Future<Set<String>> getCachedWishlistCourseIds(String userId) async {
    try {
      final ids = sharedPreferences.getStringList(_getWishlistIdsKey(userId));
      return ids?.toSet() ?? {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> addToCachedWishlistIds(String userId, String courseId) async {
    try {
      final ids = await getCachedWishlistCourseIds(userId);
      ids.add(courseId);
      await sharedPreferences.setStringList(
        _getWishlistIdsKey(userId),
        ids.toList(),
      );
    } catch (e) {
      // Ignore cache errors
    }
  }

  @override
  Future<void> removeFromCachedWishlistIds(
      String userId, String courseId) async {
    try {
      final ids = await getCachedWishlistCourseIds(userId);
      ids.remove(courseId);
      await sharedPreferences.setStringList(
        _getWishlistIdsKey(userId),
        ids.toList(),
      );
    } catch (e) {
      // Ignore cache errors
    }
  }
}
