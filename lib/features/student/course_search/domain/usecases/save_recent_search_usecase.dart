import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_search/domain/repositories/course_search_repository.dart';

/// Save Recent Search Use Case
class SaveRecentSearchUseCase implements UseCaseWithParams<void, String> {
  final CourseSearchRepository _repository;

  SaveRecentSearchUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(String query) async {
    if (query.trim().isEmpty) {
      return const Right(null);
    }
    return await _repository.saveRecentSearch(query.trim());
  }
}
