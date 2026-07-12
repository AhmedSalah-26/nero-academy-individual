import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/section_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Get Course Content UseCase
class GetCourseContentUseCase
    extends UseCaseWithParams<List<SectionEntity>, GetCourseContentParams> {
  final CoursePlayerRepository repository;

  GetCourseContentUseCase(this.repository);

  @override
  Future<Either<Failure, List<SectionEntity>>> call(
      GetCourseContentParams params) {
    return repository.getCourseContent(
      courseId: params.courseId,
      enrollmentId: params.enrollmentId,
    );
  }
}

/// Parameters for GetCourseContentUseCase
class GetCourseContentParams {
  final String courseId;
  final String enrollmentId;

  const GetCourseContentParams({
    required this.courseId,
    required this.enrollmentId,
  });
}
