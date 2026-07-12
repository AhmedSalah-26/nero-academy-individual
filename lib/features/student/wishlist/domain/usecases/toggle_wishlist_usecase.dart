import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/wishlist/domain/repositories/wishlist_repository.dart';

/// Toggle Wishlist Use Case - Returns true if added, false if removed
class ToggleWishlistUseCase
    extends UseCaseWithParams<bool, ToggleWishlistParams> {
  final WishlistRepository repository;

  ToggleWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ToggleWishlistParams params) {
    return repository.toggleWishlist(
      userId: params.userId,
      courseId: params.courseId,
    );
  }
}

/// Toggle Wishlist Parameters
class ToggleWishlistParams {
  final String userId;
  final String courseId;

  const ToggleWishlistParams({
    required this.userId,
    required this.courseId,
  });
}
