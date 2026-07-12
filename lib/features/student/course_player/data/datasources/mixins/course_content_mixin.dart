import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/utils/availability_window.dart';
import 'package:lms_platform/features/student/course_player/data/models/section_model.dart';
import 'package:lms_platform/features/student/course_player/data/models/lesson_model.dart';
import 'package:lms_platform/features/student/course_player/data/models/attachment_model.dart';

mixin CoursePlayerContentMixin {
  SupabaseClient get client;

  Future<List<SectionModel>> getCourseContent({
    required String courseId,
    required String enrollmentId,
  }) async {
    try {
      AppLogger.i('📚 [DataSource] Loading course content for: $courseId');

      final course = await client
          .from('courses')
          .select('available_from, available_until, is_published')
          .eq('id', courseId)
          .maybeSingle();
      if (course == null ||
          course['is_published'] != true ||
          !AvailabilityWindow.isJsonActive(course)) {
        throw const ServerException('Course is not available');
      }

      final response = await client
          .from('sections')
          .select('''
            id,
            course_id,
            title_ar,
            title_en,
            description_ar,
            description_en,
            sort_order,
            is_published,
            available_from,
            available_until,
            created_at,
            lessons!inner(
              id,
              section_id,
              course_id,
              title_ar,
              title_en,
              description_ar,
              description_en,
              type,
              video_url,
              video_provider,
              video_duration,
              article_content_ar,
              article_content_en,
              file_url,
              file_name,
              file_size,
              file_type,
              is_preview,
              is_mandatory,
              sort_order,
              is_published,
              available_from,
              available_until,
              created_at
            )
          ''')
          .eq('course_id', courseId)
          .eq('is_published', true)
          .eq('lessons.is_published', true)
          .order('sort_order', ascending: true)
          .order('sort_order', referencedTable: 'lessons', ascending: true);

      AppLogger.i('📚 [DataSource] Raw response: ${response.length} sections');

      // Log the raw JSON to debug
      if (response.isNotEmpty) {
        AppLogger.i('📚 [DataSource] First section raw JSON: ${response[0]}');
      }

      final sections = (response as List)
          .map((e) {
            final json = e as Map<String, dynamic>;
            if (!AvailabilityWindow.isJsonActive(json)) {
              return null;
            }
            AppLogger.i('📚 [DataSource] Parsing section: ${json['title_en']}');
            AppLogger.i('📚 [DataSource] Lessons in JSON: ${json['lessons']}');

            final rawLessons =
                (json['lessons'] as List?)?.cast<dynamic>() ?? [];
            json['lessons'] = rawLessons
                .where((lesson) =>
                    lesson is Map<String, dynamic> &&
                    AvailabilityWindow.isJsonActive(lesson))
                .toList();

            final section = SectionModel.fromJson(json);
            AppLogger.i(
                '📚 [DataSource] Section "${section.titleEn}" has ${section.lessons.length} lessons after parsing');
            return section;
          })
          .whereType<SectionModel>()
          .where((section) => section.lessons.isNotEmpty)
          .toList();

      AppLogger.success(
          '[DataSource] Loaded ${sections.length} sections with lessons');
      return sections;
    } catch (e) {
      AppLogger.e('[DataSource] Failed to load course content: $e');
      throw ServerException(e.toString());
    }
  }

  Future<LessonModel> getLesson({required String lessonId}) async {
    try {
      final response = await client
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .eq('is_published', true)
          .single();
      if (!AvailabilityWindow.isJsonActive(response)) {
        throw const ServerException('Lesson is not available');
      }
      return LessonModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<AttachmentModel>> getLessonAttachments({
    required String lessonId,
  }) async {
    try {
      final response = await client
          .from('lesson_attachments')
          .select()
          .eq('lesson_id', lessonId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<AttachmentModel>> getCourseAttachments({
    required String courseId,
  }) async {
    try {
      AppLogger.i('📎 [DataSource] Loading course attachments for: $courseId');

      final response = await client
          .from('course_attachments')
          .select('*')
          .eq('course_id', courseId)
          .order('sort_order', ascending: true);

      AppLogger.success(
          '[DataSource] Loaded ${response.length} course attachments');

      return (response as List)
          .map((json) => AttachmentModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('[DataSource] Failed to load course attachments: $e');
      throw ServerException('فشل في تحميل مرفقات الكورس: $e');
    }
  }
}
