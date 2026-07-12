import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/models/course_commerce_models.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_item_entity.dart';
import 'package:lms_platform/features/student/cart/domain/repositories/cart_repository.dart';

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
