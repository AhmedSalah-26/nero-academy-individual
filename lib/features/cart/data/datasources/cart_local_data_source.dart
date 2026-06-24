import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/cart_model.dart';

/// Cart Local Data Source - Local caching
abstract class CartLocalDataSource {
  Future<CartModel?> getCachedCart(String userId);
  Future<void> cacheCart(CartModel cart);
  Future<void> clearCachedCart(String userId);
}

/// Cart Local Data Source Implementation
class CartLocalDataSourceImpl implements CartLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _cartKeyPrefix = 'CACHED_CART_';

  CartLocalDataSourceImpl({required this.sharedPreferences});

  String _getCartKey(String userId) => '$_cartKeyPrefix$userId';

  @override
  Future<CartModel?> getCachedCart(String userId) async {
    try {
      final jsonString = sharedPreferences.getString(_getCartKey(userId));
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CartModel.fromJson(json);
    } catch (e) {
      throw CacheException('Failed to get cached cart: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheCart(CartModel cart) async {
    try {
      final jsonString = jsonEncode({
        'id': cart.id,
        'user_id': cart.userId,
        'cart_items': cart.items
            .map((item) => {
                  'id': item.id,
                  'course_id': item.courseId,
                  'title_ar': item.titleAr,
                  'title_en': item.titleEn,
                  'thumbnail_url': item.thumbnailUrl,
                  'instructor_name': item.instructorName,
                  'rating': item.rating,
                  'rating_count': item.ratingCount,
                  'price': item.price,
                  'discount_price': item.discountPrice,
                  'price_at_add': item.priceAtAdd,
                  'pricing_option': item.pricingOption?.toJson(),
                  'currency': item.currency,
                  'is_free': item.isFree,
                  'created_at': item.addedAt.toIso8601String(),
                })
            .toList(),
        'updated_at': cart.updatedAt?.toIso8601String(),
      });

      await sharedPreferences.setString(_getCartKey(cart.userId), jsonString);
    } catch (e) {
      throw CacheException('Failed to cache cart: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCachedCart(String userId) async {
    try {
      await sharedPreferences.remove(_getCartKey(userId));
    } catch (e) {
      throw CacheException('Failed to clear cached cart: ${e.toString()}');
    }
  }
}
