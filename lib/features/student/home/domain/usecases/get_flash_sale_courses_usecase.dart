import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/home/domain/repositories/home_repository.dart';

/// Get Flash Sale Courses UseCase Params
class GetFlashSaleCoursesParams {
  final int limit;
  const GetFlashSaleCoursesParams({this.limit = 10});
}

/// Get Flash Sale Courses UseCase
class GetFlashSaleCoursesUseCase
    implements
        UseCaseWithParams<List<CourseEntity>, GetFlashSaleCoursesParams> {
  final HomeRepository repository;

  GetFlashSaleCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(
      GetFlashSaleCoursesParams params) {
    return repository.getFlashSaleCourses(limit: params.limit);
  }
}
