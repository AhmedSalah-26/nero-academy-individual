import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/home/domain/entities/category_entity.dart';
import 'package:lms_platform/features/student/home/domain/repositories/home_repository.dart';

/// Get Categories UseCase
class GetCategoriesUseCase implements UseCase<List<CategoryEntity>> {
  final HomeRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call() {
    return repository.getCategories();
  }
}
