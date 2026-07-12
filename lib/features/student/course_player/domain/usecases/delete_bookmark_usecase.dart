import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Delete Bookmark UseCase
class DeleteBookmarkUseCase
    extends UseCaseWithParams<void, DeleteBookmarkParams> {
  final CoursePlayerRepository repository;

  DeleteBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBookmarkParams params) {
    return repository.deleteBookmark(bookmarkId: params.bookmarkId);
  }
}

/// Parameters for DeleteBookmarkUseCase
class DeleteBookmarkParams {
  final String bookmarkId;

  const DeleteBookmarkParams({required this.bookmarkId});
}
