import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/note_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Get Notes UseCase
class GetNotesUseCase
    extends UseCaseWithParams<List<NoteEntity>, GetNotesParams> {
  final CoursePlayerRepository repository;

  GetNotesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(GetNotesParams params) {
    return repository.getNotes(
      lessonId: params.lessonId,
      userId: params.userId,
    );
  }
}

/// Parameters for GetNotesUseCase
class GetNotesParams {
  final String lessonId;
  final String userId;

  const GetNotesParams({
    required this.lessonId,
    required this.userId,
  });
}
