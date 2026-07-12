import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/course_details/domain/repositories/course_details_repository.dart';

class EnrollFreeCourseUseCase {
  final CourseDetailsRepository repository;

  EnrollFreeCourseUseCase(this.repository);

  Future<Either<Failure, void>> call(String courseId, String userId) {
    return repository.enrollFreeCourse(courseId, userId);
  }
}
