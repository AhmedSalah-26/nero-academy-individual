import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';
import 'package:lms_platform/features/student/course_details/domain/repositories/course_details_repository.dart';

/// Get Course Details UseCase
class GetCourseDetailsUseCase
    extends UseCaseWithParams<CourseDetailsEntity, CourseDetailsParams> {
  final CourseDetailsRepository repository;

  GetCourseDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, CourseDetailsEntity>> call(
      CourseDetailsParams params) {
    return repository.getCourseDetails(
      params.courseId,
      userId: params.userId,
    );
  }
}

/// Parameters for GetCourseDetailsUseCase
class CourseDetailsParams extends Equatable {
  final String courseId;
  final String? userId;

  const CourseDetailsParams({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}
