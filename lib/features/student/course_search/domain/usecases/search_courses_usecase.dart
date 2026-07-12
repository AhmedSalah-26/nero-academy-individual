import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';
import 'package:lms_platform/features/student/course_search/domain/repositories/course_search_repository.dart';

/// Search Courses Use Case
class SearchCoursesUseCase
    implements UseCaseWithParams<CourseSearchResult, SearchFilterEntity> {
  final CourseSearchRepository _repository;

  SearchCoursesUseCase(this._repository);

  @override
  Future<Either<Failure, CourseSearchResult>> call(
    SearchFilterEntity params,
  ) async {
    return await _repository.searchCourses(params);
  }
}
