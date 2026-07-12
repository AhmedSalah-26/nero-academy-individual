import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/home/domain/repositories/home_repository.dart';

/// Get New Courses UseCase Params
class GetNewCoursesParams {
  final int limit;
  const GetNewCoursesParams({this.limit = 10});
}

/// Get New Courses UseCase
class GetNewCoursesUseCase
    implements UseCaseWithParams<List<CourseEntity>, GetNewCoursesParams> {
  final HomeRepository repository;

  GetNewCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(GetNewCoursesParams params) {
    return repository.getNewCourses(limit: params.limit);
  }
}
