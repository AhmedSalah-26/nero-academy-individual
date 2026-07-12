import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';
import 'package:lms_platform/features/student/course_search/domain/repositories/course_search_repository.dart';

/// Get Categories Use Case
class GetCategoriesUseCase implements UseCase<List<CategoryEntity>> {
  final CourseSearchRepository _repository;

  GetCategoriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call() async {
    return await _repository.getCategories();
  }
}
