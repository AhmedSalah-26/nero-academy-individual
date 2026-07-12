import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/cart/domain/repositories/cart_repository.dart';

/// Remove from Cart Use Case
class RemoveFromCartUseCase
    extends UseCaseWithParams<void, RemoveFromCartParams> {
  final CartRepository repository;

  RemoveFromCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveFromCartParams params) {
    return repository.removeFromCart(
      userId: params.userId,
      cartItemId: params.cartItemId,
    );
  }
}

/// Remove from Cart Parameters
class RemoveFromCartParams {
  final String userId;
  final String cartItemId;

  const RemoveFromCartParams({
    required this.userId,
    required this.cartItemId,
  });
}
