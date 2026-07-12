import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';
import 'package:lms_platform/features/student/wishlist/domain/repositories/wishlist_repository.dart';

/// Get Wishlist Use Case
class GetWishlistUseCase
    extends UseCaseWithParams<List<WishlistItemEntity>, GetWishlistParams> {
  final WishlistRepository repository;

  GetWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, List<WishlistItemEntity>>> call(
      GetWishlistParams params) {
    return repository.getWishlist(params.userId);
  }
}

/// Get Wishlist Parameters
class GetWishlistParams {
  final String userId;

  const GetWishlistParams({required this.userId});
}
