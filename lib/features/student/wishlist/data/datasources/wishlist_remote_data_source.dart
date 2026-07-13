import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/services/teacher_context_service.dart';
import 'package:lms_platform/features/student/wishlist/data/models/wishlist_item_model.dart';

/// Wishlist Remote Data Source - API calls to Supabase
abstract class WishlistRemoteDataSource {
  Future<List<WishlistItemModel>> getWishlist(String userId);
  Future<WishlistItemModel> addToWishlist(String userId, String courseId);
  Future<void> removeFromWishlist(String userId, String wishlistItemId);
  Future<void> removeFromWishlistByCourseId(String userId, String courseId);
  Future<bool> isInWishlist(String userId, String courseId);
  Future<void> clearWishlist(String userId);
  Future<int> getWishlistCount(String userId);
}

/// Wishlist Remote Data Source Implementation
class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final SupabaseClient supabase;

  WishlistRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<WishlistItemModel>> getWishlist(String userId) async {
    AppLogger.i('❤️ [WishlistRemote] Getting wishlist for user: $userId');
    try {
      final teacherId = TeacherContextService.instance.selectedTeacherId;

      final wishlistResponse = await supabase
          .from('wishlist')
          .select('id, user_id, course_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      final wishlistRows = (wishlistResponse as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (wishlistRows.isEmpty) {
        AppLogger.success('[WishlistRemote] Loaded 0 items');
        return const [];
      }

      final courseIds = wishlistRows
          .map((item) => item['course_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      if (courseIds.isEmpty) {
        AppLogger.success('[WishlistRemote] Loaded 0 valid items');
        return const [];
      }

      var coursesQuery = supabase.from('courses').select('''
            id, teacher_id, title_ar, title_en, thumbnail_url, price, discount_price,
            is_flash_sale, flash_sale_start, flash_sale_end,
            currency, is_free, rating, rating_count
          ''').inFilter('id', courseIds);
      if (teacherId != null) {
        coursesQuery = coursesQuery.eq('teacher_id', teacherId);
      }
      final coursesResponse =
          await coursesQuery.timeout(const Duration(seconds: 8));
      final coursesById = {
        for (final course in (coursesResponse as List).whereType<Map>())
          course['id'] as String: Map<String, dynamic>.from(course),
      };

      if (coursesById.isEmpty) {
        AppLogger.success('[WishlistRemote] Loaded 0 items for teacher');
        return const [];
      }

      final enrollmentResponse = await supabase
          .from('enrollments')
          .select('id, course_id')
          .eq('user_id', userId)
          .inFilter('course_id', coursesById.keys.toList())
          .timeout(const Duration(seconds: 8));
      final enrolledCourseIds = (enrollmentResponse as List)
          .whereType<Map>()
          .map((item) => item['course_id'] as String?)
          .whereType<String>()
          .toSet();

      final List<Map<String, dynamic>> result = [];
      for (final item in wishlistRows) {
        final courseId = item['course_id'] as String?;
        final course = courseId == null ? null : coursesById[courseId];
        if (course == null) continue;

        final itemWithEnrollment = Map<String, dynamic>.from(item);
        itemWithEnrollment['courses'] = Map<String, dynamic>.from(course)
          ..['enrollments'] =
              enrolledCourseIds.contains(courseId) ? const [{}] : const [];
        result.add(itemWithEnrollment);
      }

      AppLogger.success('[WishlistRemote] Loaded ${result.length} items');
      return result.map((e) => WishlistItemModel.fromJson(e)).toList();
    } on TimeoutException {
      AppLogger.e('[WishlistRemote] Wishlist query timed out');
      throw const ServerException('Wishlist loading timed out');
    } on PostgrestException catch (e) {
      AppLogger.e('[WishlistRemote] Error getting wishlist: ${e.message}');
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('[WishlistRemote] Unexpected error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<WishlistItemModel> addToWishlist(
      String userId, String courseId) async {
    AppLogger.i('❤️ [WishlistRemote] Adding to wishlist - course: $courseId');
    try {
      final response = await supabase.from('wishlist').insert({
        'user_id': userId,
        'course_id': courseId,
      }).select('''
            *,
            courses (
              id, title_ar, title_en, thumbnail_url, price, discount_price,
              is_flash_sale, flash_sale_start, flash_sale_end,
              currency, is_free, rating, rating_count,
              profiles:instructor_id (name, avatar_url)
            )
          ''').single();

      AppLogger.success('[WishlistRemote] Added to wishlist');
      return WishlistItemModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        AppLogger.w('[WishlistRemote] Course already in wishlist');
        throw const ValidationException('Course already in wishlist');
      }
      AppLogger.e('[WishlistRemote] Error adding: ${e.message}');
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('[WishlistRemote] Unexpected error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFromWishlist(String userId, String wishlistItemId) async {
    AppLogger.i('❤️ [WishlistRemote] Removing item: $wishlistItemId');
    try {
      await supabase
          .from('wishlist')
          .delete()
          .eq('id', wishlistItemId)
          .eq('user_id', userId);
      AppLogger.success('[WishlistRemote] Removed from wishlist');
    } on PostgrestException catch (e) {
      AppLogger.e('[WishlistRemote] Error removing: ${e.message}');
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('[WishlistRemote] Unexpected error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFromWishlistByCourseId(
      String userId, String courseId) async {
    AppLogger.i('❤️ [WishlistRemote] Removing course: $courseId');
    try {
      await supabase
          .from('wishlist')
          .delete()
          .eq('user_id', userId)
          .eq('course_id', courseId);
      AppLogger.success('[WishlistRemote] Removed course from wishlist');
    } on PostgrestException catch (e) {
      AppLogger.e('[WishlistRemote] Error removing: ${e.message}');
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('[WishlistRemote] Unexpected error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> isInWishlist(String userId, String courseId) async {
    AppLogger.i('❤️ [WishlistRemote] Checking if in wishlist: $courseId');
    try {
      final response = await supabase
          .from('wishlist')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      final result = response != null;
      AppLogger.i('[WishlistRemote] isInWishlist: $result');
      return result;
    } on PostgrestException catch (e) {
      AppLogger.e('[WishlistRemote] Error checking: ${e.message}');
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('[WishlistRemote] Unexpected error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> clearWishlist(String userId) async {
    AppLogger.i('❤️ [WishlistRemote] Clearing wishlist for user: $userId');
    try {
      await supabase.from('wishlist').delete().eq('user_id', userId);
      AppLogger.success('[WishlistRemote] Wishlist cleared');
    } on PostgrestException catch (e) {
      AppLogger.e('[WishlistRemote] Error clearing: ${e.message}');
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('[WishlistRemote] Unexpected error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> getWishlistCount(String userId) async {
    try {
      final response =
          await supabase.from('wishlist').select('id').eq('user_id', userId);
      return (response as List).length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
