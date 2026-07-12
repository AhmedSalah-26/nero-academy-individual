import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';

/// Wishlist Repository - Abstract Contract
abstract class WishlistRepository {
  /// Get user's wishlist
  Future<Either<Failure, List<WishlistItemEntity>>> getWishlist(String userId);

  /// Add course to wishlist
  Future<Either<Failure, WishlistItemEntity>> addToWishlist({
    required String userId,
    required String courseId,
  });

  /// Remove item from wishlist
  Future<Either<Failure, void>> removeFromWishlist({
    required String userId,
    required String wishlistItemId,
  });

  /// Remove by course ID
  Future<Either<Failure, void>> removeFromWishlistByCourseId({
    required String userId,
    required String courseId,
  });

  /// Toggle wishlist (add if not exists, remove if exists)
  Future<Either<Failure, bool>> toggleWishlist({
    required String userId,
    required String courseId,
  });

  /// Check if course is in wishlist
  Future<Either<Failure, bool>> isInWishlist({
    required String userId,
    required String courseId,
  });

  /// Clear all items from wishlist
  Future<Either<Failure, void>> clearWishlist(String userId);

  /// Get wishlist count (quick check)
  Future<Either<Failure, int>> getWishlistCount(String userId);
}
