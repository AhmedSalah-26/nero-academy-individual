import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';

/// Base UseCase - No parameters
abstract class UseCase<Result> {
  Future<Either<Failure, Result>> call();
}

/// Base UseCase with parameters
abstract class UseCaseWithParams<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// No Parameters class
class NoParams {
  const NoParams();
}
