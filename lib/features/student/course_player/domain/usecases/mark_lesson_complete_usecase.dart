import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/lesson_progress_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Mark Lesson Complete UseCase
class MarkLessonCompleteUseCase
    extends UseCaseWithParams<LessonProgressEntity, MarkLessonCompleteParams> {
  final CoursePlayerRepository repository;

  MarkLessonCompleteUseCase(this.repository);

  @override
  Future<Either<Failure, LessonProgressEntity>> call(
      MarkLessonCompleteParams params) {
    return repository.markLessonComplete(
      lessonId: params.lessonId,
      enrollmentId: params.enrollmentId,
    );
  }
}

/// Parameters for MarkLessonCompleteUseCase
class MarkLessonCompleteParams {
  final String lessonId;
  final String enrollmentId;

  const MarkLessonCompleteParams({
    required this.lessonId,
    required this.enrollmentId,
  });
}
