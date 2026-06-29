import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../entities/section_entity.dart';
import '../entities/lesson_entity.dart';
import '../entities/lesson_progress_entity.dart';
import '../entities/note_entity.dart';
import '../entities/bookmark_entity.dart';
import '../entities/attachment_entity.dart';
import '../entities/qa_question_entity.dart';

/// Course Player Repository - Abstract Contract
abstract class CoursePlayerRepository {
  /// Get course content (sections with lessons)
  Future<Either<Failure, List<SectionEntity>>> getCourseContent({
    required String courseId,
    required String enrollmentId,
  });

  /// Get single lesson details
  Future<Either<Failure, LessonEntity>> getLesson({
    required String lessonId,
  });

  /// Get lesson attachments
  Future<Either<Failure, List<AttachmentEntity>>> getLessonAttachments({
    required String lessonId,
  });

  /// Get lesson progress
  Future<Either<Failure, LessonProgressEntity?>> getLessonProgress({
    required String lessonId,
    required String enrollmentId,
  });

  /// Get all lesson progress for an enrollment
  Future<Either<Failure, List<LessonProgressEntity>>> getAllLessonProgress({
    required String enrollmentId,
  });

  /// Update lesson progress (watched seconds, position)
  Future<Either<Failure, LessonProgressEntity>> updateLessonProgress({
    required String lessonId,
    required String enrollmentId,
    required int watchedSeconds,
    required int lastPosition,
  });

  /// Mark lesson as complete
  Future<Either<Failure, LessonProgressEntity>> markLessonComplete({
    required String lessonId,
    required String enrollmentId,
  });

  /// Get notes for a lesson
  Future<Either<Failure, List<NoteEntity>>> getNotes({
    required String lessonId,
    required String userId,
  });

  /// Get notes for a lesson by enrollment
  Future<Either<Failure, List<NoteEntity>>> getNotesByEnrollment({
    required String lessonId,
    required String enrollmentId,
  });

  /// Add a note
  Future<Either<Failure, NoteEntity>> addNote({
    required String lessonId,
    required String userId,
    required String content,
    required int timestampSeconds,
  });

  /// Add a note by enrollment
  Future<Either<Failure, NoteEntity>> addNoteByEnrollment({
    required String lessonId,
    required String enrollmentId,
    required String content,
    required int timestampSeconds,
  });

  /// Update a note
  Future<Either<Failure, NoteEntity>> updateNote({
    required String noteId,
    required String content,
  });

  /// Delete a note
  Future<Either<Failure, void>> deleteNote({
    required String noteId,
  });

  /// Get bookmarks for enrollment
  Future<Either<Failure, List<BookmarkEntity>>> getBookmarks({
    required String enrollmentId,
  });

  /// Add a bookmark
  Future<Either<Failure, BookmarkEntity>> addBookmark({
    required String lessonId,
    required String enrollmentId,
    String? note,
  });

  /// Delete a bookmark
  Future<Either<Failure, void>> deleteBookmark({
    required String bookmarkId,
  });

  /// Check if lesson is bookmarked
  Future<Either<Failure, bool>> isLessonBookmarked({
    required String lessonId,
    required String enrollmentId,
  });

  // Q&A Methods
  /// Get questions for a course
  Future<Either<Failure, List<QAQuestionEntity>>> getQuestions({
    required String courseId,
    String? lessonId,
  });

  /// Add a question
  Future<Either<Failure, QAQuestionEntity>> addQuestion({
    required String courseId,
    required String enrollmentId,
    String? lessonId,
    required String title,
    required String content,
  });

  /// Toggle upvote on an answer
  Future<Either<Failure, bool>> toggleAnswerUpvote({
    required String answerId,
  });

  /// Check if user has upvoted an answer
  Future<Either<Failure, bool>> hasUpvotedAnswer({
    required String answerId,
  });

  /// Get course-level attachments
  Future<Either<Failure, List<AttachmentEntity>>> getCourseAttachments({
    required String courseId,
  });

  Future<Either<Failure, CourseGroupLinks>> getCourseGroupLinks({
    required String courseId,
    required String enrollmentId,
  });
}
