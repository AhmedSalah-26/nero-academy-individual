import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/note_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Add Note UseCase
class AddNoteUseCase extends UseCaseWithParams<NoteEntity, AddNoteParams> {
  final CoursePlayerRepository repository;

  AddNoteUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(AddNoteParams params) {
    return repository.addNote(
      lessonId: params.lessonId,
      userId: params.userId,
      content: params.content,
      timestampSeconds: params.timestampSeconds,
    );
  }
}

/// Parameters for AddNoteUseCase
class AddNoteParams {
  final String lessonId;
  final String userId;
  final String content;
  final int timestampSeconds;

  const AddNoteParams({
    required this.lessonId,
    required this.userId,
    required this.content,
    required this.timestampSeconds,
  });
}
