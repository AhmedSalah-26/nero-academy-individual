import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/home/domain/repositories/home_repository.dart';

/// Get Popular Courses UseCase Params
class GetPopularCoursesParams {
  final int limit;
  const GetPopularCoursesParams({this.limit = 10});
}

/// Get Popular Courses UseCase
class GetPopularCoursesUseCase
    implements UseCaseWithParams<List<CourseEntity>, GetPopularCoursesParams> {
  final HomeRepository repository;

  GetPopularCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(
      GetPopularCoursesParams params) {
    return repository.getPopularCourses(limit: params.limit);
  }
}
