import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_search/domain/repositories/course_search_repository.dart';

/// Get Recent Searches Use Case
class GetRecentSearchesUseCase implements UseCase<List<String>> {
  final CourseSearchRepository _repository;

  GetRecentSearchesUseCase(this._repository);

  @override
  Future<Either<Failure, List<String>>> call() async {
    return await _repository.getRecentSearches();
  }
}
