import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/cart/domain/entities/coupon_entity.dart';
import 'package:lms_platform/features/student/cart/domain/repositories/cart_repository.dart';

/// Apply Coupon Use Case
class ApplyCouponUseCase
    extends UseCaseWithParams<CouponEntity, ApplyCouponParams> {
  final CartRepository repository;

  ApplyCouponUseCase(this.repository);

  @override
  Future<Either<Failure, CouponEntity>> call(ApplyCouponParams params) {
    return repository.applyCoupon(
      userId: params.userId,
      couponCode: params.couponCode,
    );
  }
}

/// Apply Coupon Parameters
class ApplyCouponParams {
  final String userId;
  final String couponCode;

  const ApplyCouponParams({
    required this.userId,
    required this.couponCode,
  });
}
