import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';

/// Type alias for API results using Either
typedef ApiResult<T> = Future<Either<Failure, T>>;

/// Extension methods for Either
extension EitherExtensions<L, R> on Either<L, R> {
  /// Get the right value or null
  R? get rightOrNull => fold((_) => null, (r) => r);

  /// Get the left value or null
  L? get leftOrNull => fold((l) => l, (_) => null);

  /// Check if is right
  bool get isRight => fold((_) => false, (_) => true);

  /// Check if is left
  bool get isLeft => fold((_) => true, (_) => false);

  /// Map the right value
  Either<L, T> mapRight<T>(T Function(R r) f) {
    return fold(
      (l) => Left(l),
      (r) => Right(f(r)),
    );
  }

  /// Execute a function on success
  void onSuccess(void Function(R r) f) {
    fold((_) {}, f);
  }

  /// Execute a function on failure
  void onFailure(void Function(L l) f) {
    fold(f, (_) {});
  }
}
