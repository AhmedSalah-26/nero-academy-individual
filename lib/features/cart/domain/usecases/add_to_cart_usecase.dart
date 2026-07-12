import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

/// Add to Cart Use Case
class AddToCartUseCase
    extends UseCaseWithParams<CartItemEntity, AddToCartParams> {
  final CartRepository repository;

  AddToCartUseCase(this.repository);

  @override
  Future<Either<Failure, CartItemEntity>> call(AddToCartParams params) {
    return repository.addToCart(
      userId: params.userId,
      courseId: params.courseId,
      pricingOption: params.pricingOption,
    );
  }
}

/// Add to Cart Parameters
class AddToCartParams {
  final String userId;
  final String courseId;
  final CoursePricingOption? pricingOption;

  const AddToCartParams({
    required this.userId,
    required this.courseId,
    this.pricingOption,
  });
}
