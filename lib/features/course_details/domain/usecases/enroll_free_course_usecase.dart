import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_details_repository.dart';

class EnrollFreeCourseUseCase {
  final CourseDetailsRepository repository;

  EnrollFreeCourseUseCase(this.repository);

  Future<Either<Failure, void>> call(String courseId, String userId) {
    return repository.enrollFreeCourse(courseId, userId);
  }
}
