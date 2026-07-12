import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/teacher_context_service.dart';
import '../models/wishlist_item_model.dart';

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
      // Get wishlist items with course details
      final teacherId = TeacherContextService.instance.selectedTeacherId;
      var query = supabase.from('wishlist').select('''
            *,
            courses!inner (
              id, teacher_id, title_ar, title_en, thumbnail_url, price, discount_price,
              is_flash_sale, flash_sale_start, flash_sale_end,
              currency, is_free, rating, rating_count,
              profiles:instructor_id (name, avatar_url)
            )
          ''').eq('user_id', userId);
      if (teacherId != null) {
        query = query.eq('courses.teacher_id', teacherId);
      }
      final wishlistResponse =
          await query.order('created_at', ascending: false);

      // Check enrollment for each course
      final List<Map<String, dynamic>> result = [];
      for (final item in wishlistResponse as List) {
        final courseId = item['course_id'];
        final enrollment = await supabase
            .from('enrollments')
            .select('id')
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .maybeSingle();

        // Add enrollment info to the item
        final itemWithEnrollment = Map<String, dynamic>.from(item);
        if (itemWithEnrollment['courses'] != null) {
          itemWithEnrollment['courses'] =
              Map<String, dynamic>.from(itemWithEnrollment['courses']);
          itemWithEnrollment['courses']['enrollments'] =
              enrollment != null ? [enrollment] : [];
        }
        result.add(itemWithEnrollment);
      }

      AppLogger.success('[WishlistRemote] Loaded ${result.length} items');
      return result.map((e) => WishlistItemModel.fromJson(e)).toList();
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
