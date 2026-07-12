import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/home/domain/repositories/home_repository.dart';

/// Get Featured Courses UseCase Params
class GetFeaturedCoursesParams {
  final int limit;
  const GetFeaturedCoursesParams({this.limit = 10});
}

/// Get Featured Courses UseCase
class GetFeaturedCoursesUseCase
    implements UseCaseWithParams<List<CourseEntity>, GetFeaturedCoursesParams> {
  final HomeRepository repository;

  GetFeaturedCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(
      GetFeaturedCoursesParams params) {
    return repository.getFeaturedCourses(limit: params.limit);
  }
}
