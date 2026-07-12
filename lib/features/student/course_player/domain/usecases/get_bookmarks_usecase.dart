import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/bookmark_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Get Bookmarks UseCase
class GetBookmarksUseCase
    extends UseCaseWithParams<List<BookmarkEntity>, GetBookmarksParams> {
  final CoursePlayerRepository repository;

  GetBookmarksUseCase(this.repository);

  @override
  Future<Either<Failure, List<BookmarkEntity>>> call(
      GetBookmarksParams params) {
    return repository.getBookmarks(enrollmentId: params.enrollmentId);
  }
}

/// Parameters for GetBookmarksUseCase
class GetBookmarksParams {
  final String enrollmentId;

  const GetBookmarksParams({required this.enrollmentId});
}
