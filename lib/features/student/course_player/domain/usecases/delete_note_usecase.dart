import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Delete Note UseCase
class DeleteNoteUseCase extends UseCaseWithParams<void, DeleteNoteParams> {
  final CoursePlayerRepository repository;

  DeleteNoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteNoteParams params) {
    return repository.deleteNote(noteId: params.noteId);
  }
}

/// Parameters for DeleteNoteUseCase
class DeleteNoteParams {
  final String noteId;

  const DeleteNoteParams({required this.noteId});
}
