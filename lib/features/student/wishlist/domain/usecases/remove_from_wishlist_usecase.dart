import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/wishlist/domain/repositories/wishlist_repository.dart';

/// Remove From Wishlist Use Case
class RemoveFromWishlistUseCase
    extends UseCaseWithParams<void, RemoveFromWishlistParams> {
  final WishlistRepository repository;

  RemoveFromWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveFromWishlistParams params) {
    return repository.removeFromWishlist(
      userId: params.userId,
      wishlistItemId: params.wishlistItemId,
    );
  }
}

/// Remove From Wishlist Parameters
class RemoveFromWishlistParams {
  final String userId;
  final String wishlistItemId;

  const RemoveFromWishlistParams({
    required this.userId,
    required this.wishlistItemId,
  });
}
