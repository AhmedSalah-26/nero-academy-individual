import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/course_player/data/models/note_model.dart';
import 'package:lms_platform/features/student/course_player/data/models/bookmark_model.dart';

mixin CoursePlayerNotesMixin {
  SupabaseClient get client;

  Future<List<NoteModel>> getNotes({
    required String lessonId,
    required String userId,
  }) async {
    try {
      final response = await client
          .from('notes')
          .select()
          .eq('lesson_id', lessonId)
          .eq('user_id', userId)
          .order('timestamp_seconds', ascending: true);

      return (response as List)
          .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<NoteModel> addNote({
    required String lessonId,
    required String userId,
    required String content,
    required int timestampSeconds,
  }) async {
    try {
      final lesson = await client
          .from('lessons')
          .select('course_id')
          .eq('id', lessonId)
          .single();
      final courseId = lesson['course_id'] as String;

      final response = await client
          .from('notes')
          .insert({
            'lesson_id': lessonId,
            'user_id': userId,
            'course_id': courseId,
            'content': content,
            'timestamp_seconds': timestampSeconds,
          })
          .select()
          .single();

      return NoteModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<NoteModel>> getNotesByEnrollment({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      final enrollment = await client
          .from('enrollments')
          .select('user_id')
          .eq('id', enrollmentId)
          .single();
      final userId = enrollment['user_id'] as String;

      final response = await client
          .from('notes')
          .select()
          .eq('lesson_id', lessonId)
          .eq('user_id', userId)
          .order('timestamp_seconds', ascending: true);

      return (response as List).map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      AppLogger.e('[Notes] Failed to get notes: $e');
      throw ServerException(e.toString());
    }
  }

  Future<NoteModel> addNoteByEnrollment({
    required String lessonId,
    required String enrollmentId,
    required String content,
    required int timestampSeconds,
  }) async {
    try {
      final enrollment = await client
          .from('enrollments')
          .select('user_id, course_id')
          .eq('id', enrollmentId)
          .single();
      final userId = enrollment['user_id'] as String;
      final courseId = enrollment['course_id'] as String;

      final response = await client
          .from('notes')
          .insert({
            'lesson_id': lessonId,
            'user_id': userId,
            'course_id': courseId,
            'content': content,
            'timestamp_seconds': timestampSeconds,
          })
          .select()
          .single();

      return NoteModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<NoteModel> updateNote(
      {required String noteId, required String content}) async {
    try {
      final response = await client
          .from('notes')
          .update({'content': content})
          .eq('id', noteId)
          .select()
          .single();
      return NoteModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deleteNote({required String noteId}) async {
    try {
      await client.from('notes').delete().eq('id', noteId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

mixin CoursePlayerBookmarksMixin {
  SupabaseClient get client;

  Future<List<BookmarkModel>> getBookmarks(
      {required String enrollmentId}) async {
    try {
      final enrollment = await client
          .from('enrollments')
          .select('user_id, course_id')
          .eq('id', enrollmentId)
          .single();
      final userId = enrollment['user_id'] as String;
      final courseId = enrollment['course_id'] as String;

      final response = await client
          .from('bookmarks')
          .select('*, lessons(title_ar, title_en)')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => BookmarkModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<BookmarkModel> addBookmark({
    required String lessonId,
    required String enrollmentId,
    String? note,
  }) async {
    try {
      final enrollment = await client
          .from('enrollments')
          .select('user_id, course_id')
          .eq('id', enrollmentId)
          .single();
      final userId = enrollment['user_id'] as String;
      final courseId = enrollment['course_id'] as String;

      final response = await client
          .from('bookmarks')
          .insert({
            'lesson_id': lessonId,
            'user_id': userId,
            'course_id': courseId,
            'note': note,
          })
          .select()
          .single();

      return BookmarkModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Error adding bookmark: $e');
      throw ServerException(e.toString());
    }
  }

  Future<void> deleteBookmark({required String bookmarkId}) async {
    try {
      await client.from('bookmarks').delete().eq('id', bookmarkId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<bool> isLessonBookmarked({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      // Get user_id from enrollment
      final enrollment = await client
          .from('enrollments')
          .select('user_id')
          .eq('id', enrollmentId)
          .single();
      final userId = enrollment['user_id'] as String;

      final response = await client
          .from('bookmarks')
          .select('id')
          .eq('lesson_id', lessonId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.e('Error checking bookmark: $e');
      return false;
    }
  }
}
