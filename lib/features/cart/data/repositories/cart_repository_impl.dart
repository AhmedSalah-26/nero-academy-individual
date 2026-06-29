import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';
import '../datasources/cart_remote_data_source.dart';

/// Cart Repository Implementation
class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, CartEntity>> getCart(String userId) async {
    AppLogger.i('🛒 [CartRepo] Getting cart for user: $userId');

    if (await networkInfo.isConnected) {
      try {
        final cart = await remoteDataSource.getCart(userId);
        AppLogger.success('[CartRepo] Cart loaded: ${cart.itemsCount} items');
        await localDataSource.cacheCart(cart);
        return Right(cart);
      } on ServerException catch (e) {
        AppLogger.e('[CartRepo] Server error getting cart', e);
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      AppLogger.w('[CartRepo] No network, trying cache');
      try {
        final cachedCart = await localDataSource.getCachedCart(userId);
        if (cachedCart != null) {
          AppLogger.i('[CartRepo] Using cached cart');
          return Right(cachedCart);
        }
        return const Left(NetworkFailure('No internet connection'));
      } on CacheException catch (e) {
        AppLogger.e('[CartRepo] Cache error', e);
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, CartItemEntity>> addToCart({
    required String userId,
    required String courseId,
    CoursePricingOption? pricingOption,
  }) async {
    AppLogger.i(
        '🛒 [CartRepo] Adding to cart - User: $userId, Course: $courseId');

    try {
      final item = await remoteDataSource.addToCart(
        userId,
        courseId,
        pricingOption: pricingOption,
      );
      AppLogger.success('[CartRepo] Added to cart: ${item.id}');
      return Right(item);
    } on ValidationException catch (e) {
      AppLogger.w('[CartRepo] Validation error: ${e.message}');
      return Left(ValidationFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Server error adding to cart', e);
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.e('[CartRepo] Unexpected error adding to cart', e, stack);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromCart({
    required String userId,
    required String cartItemId,
  }) async {
    AppLogger.i('🛒 [CartRepo] Removing from cart: $cartItemId');

    try {
      await remoteDataSource.removeFromCart(userId, cartItemId);
      AppLogger.success('[CartRepo] Removed from cart');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Error removing from cart', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> clearCart(String userId) async {
    AppLogger.i('🛒 [CartRepo] Clearing cart for user: $userId');

    try {
      await remoteDataSource.clearCart(userId);
      await localDataSource.clearCachedCart(userId);
      AppLogger.success('[CartRepo] Cart cleared');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Error clearing cart', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> applyCoupon({
    required String userId,
    required String couponCode,
  }) async {
    AppLogger.i('🎟️ [CartRepo] Applying coupon: $couponCode');

    try {
      final coupon = await remoteDataSource.applyCoupon(userId, couponCode);
      AppLogger.success('[CartRepo] Coupon applied: ${coupon.discountValue}%');
      return Right(coupon);
    } on NotFoundException catch (e) {
      AppLogger.w('[CartRepo] Coupon not found');
      return Left(NotFoundFailure(e.message, code: e.code));
    } on ValidationException catch (e) {
      AppLogger.w('[CartRepo] Invalid coupon: ${e.message}');
      return Left(ValidationFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Error applying coupon', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> removeCoupon(String userId) async {
    AppLogger.i('🎟️ [CartRepo] Removing coupon');

    try {
      await remoteDataSource.removeCoupon(userId);
      AppLogger.success('[CartRepo] Coupon removed');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Error removing coupon', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> validateCoupon(
      String couponCode) async {
    AppLogger.i('🎟️ [CartRepo] Validating coupon: $couponCode');

    try {
      final coupon = await remoteDataSource.validateCoupon(couponCode);
      AppLogger.success('[CartRepo] Coupon valid');
      return Right(coupon);
    } on NotFoundException catch (e) {
      AppLogger.w('[CartRepo] Coupon not found');
      return Left(NotFoundFailure(e.message, code: e.code));
    } on ValidationException catch (e) {
      AppLogger.w('[CartRepo] Invalid coupon');
      return Left(ValidationFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Error validating coupon', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, List<SavedPaymentMethodEntity>>>
      getSavedPaymentMethods(
    String userId,
  ) async {
    AppLogger.i('💳 [CartRepo] Getting saved payment methods');

    try {
      final methods = await remoteDataSource.getSavedPaymentMethods(userId);
      AppLogger.success('[CartRepo] Found ${methods.length} payment methods');
      return Right(methods);
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Error getting payment methods', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> checkout({
    required String userId,
    required PaymentMethodType paymentMethod,
    String? savedPaymentMethodId,
    Map<String, dynamic>? cardDetails,
    String? couponId,
    String? couponCode,
    double couponDiscountTotal = 0,
  }) async {
    AppLogger.i(
        '💰 [CartRepo] Processing checkout - Method: ${paymentMethod.name}');

    try {
      final order = await remoteDataSource.checkout(
        userId: userId,
        paymentMethod: paymentMethod,
        savedPaymentMethodId: savedPaymentMethodId,
        cardDetails: cardDetails,
        couponId: couponId,
        couponCode: couponCode,
        couponDiscountTotal: couponDiscountTotal,
      );
      AppLogger.success('[CartRepo] Checkout complete - Order: ${order.id}');
      await localDataSource.clearCachedCart(userId);
      return Right(order);
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Checkout failed', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  }) async {
    AppLogger.i('📚 [CartRepo] Getting recommended courses');

    try {
      final courses =
          await remoteDataSource.getRecommendedCourses(userId, limit);
      AppLogger.success('[CartRepo] Found ${courses.length} recommendations');
      return Right(courses);
    } on ServerException catch (e) {
      AppLogger.e('[CartRepo] Error getting recommendations', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, int>> getCartCount(String userId) async {
    try {
      final count = await remoteDataSource.getCartCount(userId);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
