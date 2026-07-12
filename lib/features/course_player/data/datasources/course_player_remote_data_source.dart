import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../models/section_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_progress_model.dart';
import '../models/note_model.dart';
import '../models/bookmark_model.dart';
import '../models/attachment_model.dart';
import '../models/qa_question_model.dart';

import 'mixins/course_content_mixin.dart';
import 'mixins/course_progress_mixin.dart';
import 'mixins/course_interaction_mixin.dart';
import 'mixins/course_qa_mixin.dart';

/// Course Player Remote Data Source
abstract class CoursePlayerRemoteDataSource {
  Future<List<SectionModel>> getCourseContent({
    required String courseId,
    required String enrollmentId,
  });

  Future<LessonModel> getLesson({required String lessonId});

  Future<List<AttachmentModel>> getLessonAttachments(
      {required String lessonId});

  Future<LessonProgressModel?> getLessonProgress({
    required String lessonId,
    required String enrollmentId,
  });

  Future<List<LessonProgressModel>> getAllLessonProgress({
    required String enrollmentId,
  });

  Future<LessonProgressModel> updateLessonProgress({
    required String lessonId,
    required String enrollmentId,
    required int watchedSeconds,
    required int lastPosition,
  });

  Future<LessonProgressModel> markLessonComplete({
    required String lessonId,
    required String enrollmentId,
  });

  Future<List<NoteModel>> getNotes({
    required String lessonId,
    required String userId,
  });

  Future<List<NoteModel>> getNotesByEnrollment({
    required String lessonId,
    required String enrollmentId,
  });

  Future<NoteModel> addNote({
    required String lessonId,
    required String userId,
    required String content,
    required int timestampSeconds,
  });

  Future<NoteModel> addNoteByEnrollment({
    required String lessonId,
    required String enrollmentId,
    required String content,
    required int timestampSeconds,
  });

  Future<NoteModel> updateNote({
    required String noteId,
    required String content,
  });

  Future<void> deleteNote({required String noteId});

  Future<List<BookmarkModel>> getBookmarks({required String enrollmentId});

  Future<BookmarkModel> addBookmark({
    required String lessonId,
    required String enrollmentId,
    String? note,
  });

  Future<void> deleteBookmark({required String bookmarkId});

  Future<bool> isLessonBookmarked({
    required String lessonId,
    required String enrollmentId,
  });

  // Q&A Methods
  Future<List<QAQuestionModel>> getQuestions({
    required String courseId,
    String? lessonId,
  });

  Future<QAQuestionModel> addQuestion({
    required String courseId,
    required String enrollmentId,
    String? lessonId,
    required String title,
    required String content,
  });

  Future<bool> toggleAnswerUpvote({required String answerId});

  Future<bool> hasUpvotedAnswer({required String answerId});

  // Course Attachments Methods
  Future<List<AttachmentModel>> getCourseAttachments({
    required String courseId,
  });

  Future<CourseGroupLinks> getCourseGroupLinks({
    required String courseId,
    required String enrollmentId,
  });
}

/// Implementation of CoursePlayerRemoteDataSource
class CoursePlayerRemoteDataSourceImpl
    with
        CoursePlayerContentMixin,
        CoursePlayerProgressMixin,
        CoursePlayerNotesMixin,
        CoursePlayerBookmarksMixin,
        CoursePlayerQAMixin
    implements CoursePlayerRemoteDataSource {
  @override
  final SupabaseClient client;

  CoursePlayerRemoteDataSourceImpl(this.client);

  @override
  Future<CourseGroupLinks> getCourseGroupLinks({
    required String courseId,
    required String enrollmentId,
  }) async {
    final enrollment = await client
        .from('enrollments')
        .select('id, parent_enrollments!inner(payment_status)')
        .eq('id', enrollmentId)
        .eq('course_id', courseId)
        .inFilter('status', ['active', 'completed'])
        .eq('parent_enrollments.payment_status', 'paid')
        .maybeSingle();

    if (enrollment == null) {
      return const CourseGroupLinks();
    }

    final response = await client
        .from('courses')
        .select('group_links')
        .eq('id', courseId)
        .single();
    return CourseGroupLinks.fromJson(
      response['group_links'] as Map<String, dynamic>?,
    );
  }
}
