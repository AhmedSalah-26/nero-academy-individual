import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';
import 'package:lms_platform/features/student/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:lms_platform/features/student/wishlist/data/datasources/wishlist_local_data_source.dart';
import 'package:lms_platform/features/student/wishlist/data/datasources/wishlist_remote_data_source.dart';

/// Wishlist Repository Implementation
class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;
  final WishlistLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  WishlistRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<WishlistItemEntity>>> getWishlist(
      String userId) async {
    AppLogger.i('❤️ [WishlistRepo] Getting wishlist for user: $userId');

    if (await networkInfo.isConnected) {
      try {
        final items = await remoteDataSource.getWishlist(userId);
        AppLogger.success('[WishlistRepo] Wishlist loaded: ${items.length}');
        await localDataSource.cacheWishlist(userId, items);
        return Right(items);
      } on ServerException catch (e) {
        AppLogger.e('[WishlistRepo] Server error getting wishlist', e);
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      AppLogger.w('[WishlistRepo] No network, trying cache');
      try {
        final cachedItems = await localDataSource.getCachedWishlist(userId);
        if (cachedItems != null) {
          AppLogger.i('[WishlistRepo] Using cached wishlist');
          return Right(cachedItems);
        }
        return const Left(NetworkFailure('No internet connection'));
      } on CacheException catch (e) {
        AppLogger.e('[WishlistRepo] Cache error', e);
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, WishlistItemEntity>> addToWishlist({
    required String userId,
    required String courseId,
  }) async {
    AppLogger.i(
        '❤️ [WishlistRepo] Adding to wishlist - User: $userId, Course: $courseId');

    try {
      final item = await remoteDataSource.addToWishlist(userId, courseId);
      AppLogger.success('[WishlistRepo] Added to wishlist: ${item.id}');
      await localDataSource.addToCachedWishlistIds(userId, courseId);
      return Right(item);
    } on ValidationException catch (e) {
      AppLogger.w('[WishlistRepo] Validation error: ${e.message}');
      return Left(ValidationFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      AppLogger.e('[WishlistRepo] Server error adding to wishlist', e);
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.e('[WishlistRepo] Unexpected error', e, stack);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromWishlist({
    required String userId,
    required String wishlistItemId,
  }) async {
    AppLogger.i('❤️ [WishlistRepo] Removing from wishlist: $wishlistItemId');

    try {
      await remoteDataSource.removeFromWishlist(userId, wishlistItemId);
      AppLogger.success('[WishlistRepo] Removed from wishlist');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.e('[WishlistRepo] Error removing from wishlist', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromWishlistByCourseId({
    required String userId,
    required String courseId,
  }) async {
    AppLogger.i('❤️ [WishlistRepo] Removing course from wishlist: $courseId');

    try {
      await remoteDataSource.removeFromWishlistByCourseId(userId, courseId);
      await localDataSource.removeFromCachedWishlistIds(userId, courseId);
      AppLogger.success('[WishlistRepo] Removed course from wishlist');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.e('[WishlistRepo] Error removing course from wishlist', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleWishlist({
    required String userId,
    required String courseId,
  }) async {
    AppLogger.i('❤️ [WishlistRepo] Toggling wishlist for course: $courseId');

    try {
      final isInWishlist =
          await remoteDataSource.isInWishlist(userId, courseId);

      if (isInWishlist) {
        await remoteDataSource.removeFromWishlistByCourseId(userId, courseId);
        await localDataSource.removeFromCachedWishlistIds(userId, courseId);
        AppLogger.success('[WishlistRepo] Removed from wishlist');
        return const Right(false);
      } else {
        await remoteDataSource.addToWishlist(userId, courseId);
        await localDataSource.addToCachedWishlistIds(userId, courseId);
        AppLogger.success('[WishlistRepo] Added to wishlist');
        return const Right(true);
      }
    } on ServerException catch (e) {
      AppLogger.e('[WishlistRepo] Error toggling wishlist', e);
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.e(
          '[WishlistRepo] Unexpected error toggling wishlist', e, stack);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isInWishlist({
    required String userId,
    required String courseId,
  }) async {
    try {
      // First check local cache for quick response
      final cachedIds =
          await localDataSource.getCachedWishlistCourseIds(userId);
      if (cachedIds.contains(courseId)) {
        return const Right(true);
      }

      // Then check remote
      final result = await remoteDataSource.isInWishlist(userId, courseId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearWishlist(String userId) async {
    AppLogger.i('❤️ [WishlistRepo] Clearing wishlist for user: $userId');

    try {
      await remoteDataSource.clearWishlist(userId);
      await localDataSource.clearCachedWishlist(userId);
      AppLogger.success('[WishlistRepo] Wishlist cleared');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.e('[WishlistRepo] Error clearing wishlist', e);
      return Left(ServerFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, int>> getWishlistCount(String userId) async {
    try {
      final count = await remoteDataSource.getWishlistCount(userId);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
