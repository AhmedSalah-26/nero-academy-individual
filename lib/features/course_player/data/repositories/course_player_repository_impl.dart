import 'package:dartz/dartz.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/lesson_progress_entity.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/entities/bookmark_entity.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/entities/qa_question_entity.dart';
import '../../domain/repositories/course_player_repository.dart';
import '../datasources/course_player_remote_data_source.dart';
import '../datasources/course_player_local_data_source.dart';

/// Course Player Repository Implementation
class CoursePlayerRepositoryImpl implements CoursePlayerRepository {
  final CoursePlayerRemoteDataSource remoteDataSource;
  final CoursePlayerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CoursePlayerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<SectionEntity>>> getCourseContent({
    required String courseId,
    required String enrollmentId,
  }) async {
    try {
      final sections = await remoteDataSource.getCourseContent(
        courseId: courseId,
        enrollmentId: enrollmentId,
      );
      return Right(sections);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, LessonEntity>> getLesson({
    required String lessonId,
  }) async {
    try {
      final lesson = await remoteDataSource.getLesson(lessonId: lessonId);
      return Right(lesson);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<AttachmentEntity>>> getLessonAttachments({
    required String lessonId,
  }) async {
    try {
      final attachments = await remoteDataSource.getLessonAttachments(
        lessonId: lessonId,
      );
      return Right(attachments);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, LessonProgressEntity?>> getLessonProgress({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      final progress = await remoteDataSource.getLessonProgress(
        lessonId: lessonId,
        enrollmentId: enrollmentId,
      );
      return Right(progress);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<LessonProgressEntity>>> getAllLessonProgress({
    required String enrollmentId,
  }) async {
    try {
      final progressList = await remoteDataSource.getAllLessonProgress(
        enrollmentId: enrollmentId,
      );
      return Right(progressList);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getIncompleteQuizLessonIds({
    required String courseId,
    required String enrollmentId,
  }) async {
    try {
      final lessonIds = await remoteDataSource.getIncompleteQuizLessonIds(
        courseId: courseId,
        enrollmentId: enrollmentId,
      );
      return Right(lessonIds);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, LessonProgressEntity>> updateLessonProgress({
    required String lessonId,
    required String enrollmentId,
    required int watchedSeconds,
    required int lastPosition,
  }) async {
    try {
      // Cache locally first
      await localDataSource.cacheLastPosition(
        lessonId: lessonId,
        position: lastPosition,
      );

      final progress = await remoteDataSource.updateLessonProgress(
        lessonId: lessonId,
        enrollmentId: enrollmentId,
        watchedSeconds: watchedSeconds,
        lastPosition: lastPosition,
      );
      return Right(progress);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, LessonProgressEntity>> markLessonComplete({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      final progress = await remoteDataSource.markLessonComplete(
        lessonId: lessonId,
        enrollmentId: enrollmentId,
      );
      return Right(progress);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getNotes({
    required String lessonId,
    required String userId,
  }) async {
    try {
      final notes = await remoteDataSource.getNotes(
        lessonId: lessonId,
        userId: userId,
      );
      return Right(notes);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getNotesByEnrollment({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      final notes = await remoteDataSource.getNotesByEnrollment(
        lessonId: lessonId,
        enrollmentId: enrollmentId,
      );
      return Right(notes);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> addNote({
    required String lessonId,
    required String userId,
    required String content,
    required int timestampSeconds,
  }) async {
    try {
      final note = await remoteDataSource.addNote(
        lessonId: lessonId,
        userId: userId,
        content: content,
        timestampSeconds: timestampSeconds,
      );
      return Right(note);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> addNoteByEnrollment({
    required String lessonId,
    required String enrollmentId,
    required String content,
    required int timestampSeconds,
  }) async {
    try {
      final note = await remoteDataSource.addNoteByEnrollment(
        lessonId: lessonId,
        enrollmentId: enrollmentId,
        content: content,
        timestampSeconds: timestampSeconds,
      );
      return Right(note);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> updateNote({
    required String noteId,
    required String content,
  }) async {
    try {
      final note = await remoteDataSource.updateNote(
        noteId: noteId,
        content: content,
      );
      return Right(note);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote({required String noteId}) async {
    try {
      await remoteDataSource.deleteNote(noteId: noteId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<BookmarkEntity>>> getBookmarks({
    required String enrollmentId,
  }) async {
    try {
      final bookmarks = await remoteDataSource.getBookmarks(
        enrollmentId: enrollmentId,
      );
      return Right(bookmarks);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, BookmarkEntity>> addBookmark({
    required String lessonId,
    required String enrollmentId,
    String? note,
  }) async {
    try {
      final bookmark = await remoteDataSource.addBookmark(
        lessonId: lessonId,
        enrollmentId: enrollmentId,
        note: note,
      );
      return Right(bookmark);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, void>> deleteBookmark({
    required String bookmarkId,
  }) async {
    try {
      await remoteDataSource.deleteBookmark(bookmarkId: bookmarkId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, bool>> isLessonBookmarked({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      final isBookmarked = await remoteDataSource.isLessonBookmarked(
        lessonId: lessonId,
        enrollmentId: enrollmentId,
      );
      return Right(isBookmarked);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  // Q&A Methods
  @override
  Future<Either<Failure, List<QAQuestionEntity>>> getQuestions({
    required String courseId,
    String? lessonId,
  }) async {
    try {
      final questions = await remoteDataSource.getQuestions(
        courseId: courseId,
        lessonId: lessonId,
      );
      return Right(questions);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, QAQuestionEntity>> addQuestion({
    required String courseId,
    required String enrollmentId,
    String? lessonId,
    required String title,
    required String content,
  }) async {
    try {
      final question = await remoteDataSource.addQuestion(
        courseId: courseId,
        enrollmentId: enrollmentId,
        lessonId: lessonId,
        title: title,
        content: content,
      );
      return Right(question);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, bool>> toggleAnswerUpvote({
    required String answerId,
  }) async {
    try {
      final result = await remoteDataSource.toggleAnswerUpvote(
        answerId: answerId,
      );
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, bool>> hasUpvotedAnswer({
    required String answerId,
  }) async {
    try {
      final result = await remoteDataSource.hasUpvotedAnswer(
        answerId: answerId,
      );
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<AttachmentEntity>>> getCourseAttachments({
    required String courseId,
  }) async {
    try {
      final result = await remoteDataSource.getCourseAttachments(
        courseId: courseId,
      );
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, CourseGroupLinks>> getCourseGroupLinks({
    required String courseId,
    required String enrollmentId,
  }) async {
    try {
      final result = await remoteDataSource.getCourseGroupLinks(
        courseId: courseId,
        enrollmentId: enrollmentId,
      );
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
