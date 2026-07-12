import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/bookmark_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Add Bookmark UseCase
class AddBookmarkUseCase
    extends UseCaseWithParams<BookmarkEntity, AddBookmarkParams> {
  final CoursePlayerRepository repository;

  AddBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, BookmarkEntity>> call(AddBookmarkParams params) {
    return repository.addBookmark(
      lessonId: params.lessonId,
      enrollmentId: params.enrollmentId,
      note: params.note,
    );
  }
}

/// Parameters for AddBookmarkUseCase
class AddBookmarkParams {
  final String lessonId;
  final String enrollmentId;
  final String? note;

  const AddBookmarkParams({
    required this.lessonId,
    required this.enrollmentId,
    this.note,
  });
}
