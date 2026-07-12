import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_entity.dart';
import 'package:lms_platform/features/student/cart/domain/repositories/cart_repository.dart';

/// Get Cart Use Case
class GetCartUseCase extends UseCaseWithParams<CartEntity, GetCartParams> {
  final CartRepository repository;

  GetCartUseCase(this.repository);

  @override
  Future<Either<Failure, CartEntity>> call(GetCartParams params) {
    return repository.getCart(params.userId);
  }
}

/// Get Cart Parameters
class GetCartParams {
  final String userId;

  const GetCartParams({required this.userId});
}
