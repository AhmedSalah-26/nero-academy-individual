import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/instructor_repository.dart';

/// Instructor Course Editor Data Source - Course editor methods
class InstructorCourseEditorDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorCourseEditorDS';

  InstructorCourseEditorDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get categories for course editor
  Future<List<CategoryOption>> getCategories() async {
    AppLogger.d('[$_tag] getCategories');
    try {
      final response = await _client
          .from('categories')
          .select('id, name_ar, name_en')
          .eq('is_active', true)
          .order('sort_order');

      AppLogger.success(
          '[$_tag] getCategories: ${(response as List).length} categories');
      return response.map((c) {
        return CategoryOption(
          id: c['id'] as String,
          nameAr: c['name_ar'] as String? ?? '',
          nameEn: c['name_en'] as String? ?? '',
        );
      }).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCategories error', e, s);
      rethrow;
    }
  }

  /// Get course details for editing
  Future<CourseDetails?> getCourseForEdit(String courseId) async {
    AppLogger.d('[$_tag] getCourseForEdit: $courseId');
    try {
      final courseResponse = await _client
          .from('courses')
          .select()
          .eq('id', courseId)
          .eq('instructor_id', _userId)
          .maybeSingle();

      if (courseResponse == null) {
        AppLogger.w('[$_tag] getCourseForEdit: course not found');
        return null;
      }

      final sectionsResponse = await _client
          .from('sections')
          .select('*, lessons(*)')
          .eq('course_id', courseId)
          .order('sort_order');

      final sections = (sectionsResponse as List).map((s) {
        final lessons = (s['lessons'] as List? ?? []).map((l) {
          return LessonDto(
            id: l['id'] as String?,
            titleAr: l['title_ar'] as String? ?? '',
            titleEn: l['title_en'] as String? ?? '',
            type: l['type'] as String? ?? 'video',
            order: l['sort_order'] as int? ?? 0,
            durationMinutes: ((l['video_duration'] as int? ?? 0) / 60).round(),
            isFree: l['is_preview'] as bool? ?? false,
            isPublished: l['is_published'] as bool? ?? true,
            availableFrom: l['available_from'] != null
                ? DateTime.parse(l['available_from'] as String)
                : null,
            availableUntil: l['available_until'] != null
                ? DateTime.parse(l['available_until'] as String)
                : null,
            videoUrl: l['video_url'] as String?,
            articleContent: l['article_content_ar'] as String?,
            fileUrl: l['file_url'] as String?,
            fileName: l['file_name'] as String?,
            fileSize: l['file_size'] as int?,
            fileType: l['file_type'] as String?,
          );
        }).toList();

        return SectionDto(
          id: s['id'] as String?,
          titleAr: s['title_ar'] as String? ?? '',
          titleEn: s['title_en'] as String? ?? '',
          order: s['sort_order'] as int? ?? 0,
          isPublished: s['is_published'] as bool? ?? true,
          lessons: lessons,
        );
      }).toList();

      AppLogger.success(
          '[$_tag] getCourseForEdit: ${sections.length} sections');
      return CourseDetails(
        id: courseResponse['id'] as String,
        titleAr: courseResponse['title_ar'] as String? ?? '',
        titleEn: courseResponse['title_en'] as String? ?? '',
        subtitleAr: courseResponse['subtitle_ar'] as String?,
        subtitleEn: courseResponse['subtitle_en'] as String?,
        descriptionAr: courseResponse['description_ar'] as String?,
        descriptionEn: courseResponse['description_en'] as String?,
        thumbnailUrl: courseResponse['thumbnail_url'] as String?,
        previewVideoUrl: courseResponse['preview_video_url'] as String?,
        categoryId: courseResponse['category_id'] as String?,
        level: courseResponse['level'] as String? ?? 'beginner',
        price: (courseResponse['price'] as num?)?.toDouble() ?? 0,
        discountPrice: (courseResponse['discount_price'] as num?)?.toDouble(),
        currency: courseResponse['currency'] as String? ?? 'EGP',
        isPublished: courseResponse['is_published'] as bool? ?? false,
        badge: courseResponse['badge'] as String?,
        isFlashSale: courseResponse['is_flash_sale'] as bool? ?? false,
        flashSaleStart: courseResponse['flash_sale_start'] != null
            ? DateTime.parse(courseResponse['flash_sale_start'] as String)
            : null,
        flashSaleEnd: courseResponse['flash_sale_end'] != null
            ? DateTime.parse(courseResponse['flash_sale_end'] as String)
            : null,
        availableFrom: courseResponse['available_from'] != null
            ? DateTime.parse(courseResponse['available_from'] as String)
            : null,
        availableUntil: courseResponse['available_until'] != null
            ? DateTime.parse(courseResponse['available_until'] as String)
            : null,
        sections: sections,
      );
    } catch (e, s) {
      AppLogger.e('[$_tag] getCourseForEdit error', e, s);
      rethrow;
    }
  }

  /// Create new course
  Future<String> createCourse(CourseCreateDto dto) async {
    AppLogger.d('[$_tag] createCourse: ${dto.titleAr}');
    try {
      final data = dto.toJson();
      data['instructor_id'] = _userId;

      final response =
          await _client.from('courses').insert(data).select().single();
      AppLogger.success('[$_tag] createCourse success: ${response['id']}');
      return response['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] createCourse error', e, s);
      rethrow;
    }
  }

  /// Update course
  Future<bool> updateCourse(String courseId, CourseUpdateDto dto) async {
    AppLogger.d('[$_tag] updateCourse: $courseId');
    try {
      final data = dto.toJson();
      await _client
          .from('courses')
          .update(data)
          .eq('id', courseId)
          .eq('instructor_id', _userId);
      AppLogger.success('[$_tag] updateCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateCourse error', e, s);
      rethrow;
    }
  }

  /// Save sections and lessons using Bulk Upsert (Highly Optimized)
  Future<bool> saveSectionsAndLessons(
      String courseId, List<SectionDto> sections) async {
    AppLogger.d('[$_tag] saveSectionsAndLessons (bulk): courseId=$courseId');
    try {
      const uuid = Uuid();

      final sectionIdsToKeep = <String>[];
      final lessonIdsToKeep = <String>[];

      final sectionsToUpsert = <Map<String, dynamic>>[];
      final lessonsToUpsert = <Map<String, dynamic>>[];

      // 1. Prepare data for bulk upsert
      for (final section in sections) {
        final sectionId = section.id ?? uuid.v4();
        sectionIdsToKeep.add(sectionId);

        sectionsToUpsert.add({
          'id': sectionId,
          'course_id': courseId,
          'title_ar': section.titleAr,
          'title_en': section.titleEn,
          'sort_order': section.order,
          'is_published': section.isPublished,
        });

        for (final lesson in section.lessons) {
          final lessonId = lesson.id ?? uuid.v4();
          lessonIdsToKeep.add(lessonId);

          lessonsToUpsert.add({
            'id': lessonId,
            'section_id': sectionId,
            'course_id': courseId,
            'title_ar': lesson.titleAr,
            'title_en': lesson.titleEn,
            'type': lesson.type,
            'sort_order': lesson.order,
            'video_duration': (lesson.durationMinutes * 60),
            'is_preview': lesson.isFree,
            'is_published': lesson.isPublished,
            'available_from': lesson.availableFrom?.toUtc().toIso8601String(),
            'available_until':
                lesson.availableUntil?.toUtc().toIso8601String(),
            'video_url': lesson.videoUrl,
            'article_content_ar': lesson.articleContent,
            'file_url': lesson.fileUrl,
            'file_name': lesson.fileName,
            'file_size': lesson.fileSize,
            'file_type': lesson.fileType,
          });
        }
      }

      // 2. Delete sections that are removed
      final existingSectionsQuery =
          await _client.from('sections').select('id').eq('course_id', courseId);
      final existingSections = existingSectionsQuery as List;
      for (final existing in existingSections) {
        final id = existing['id'] as String;
        if (!sectionIdsToKeep.contains(id)) {
          await _client.from('sections').delete().eq('id', id);
          AppLogger.d('[$_tag] Deleted section: $id');
        }
      }

      // 3. Delete lessons that are removed
      final existingLessonsQuery =
          await _client.from('lessons').select('id').eq('course_id', courseId);
      final existingLessons = existingLessonsQuery as List;
      for (final existing in existingLessons) {
        final id = existing['id'] as String;
        if (!lessonIdsToKeep.contains(id)) {
          await _client.from('lessons').delete().eq('id', id);
          AppLogger.d('[$_tag] Deleted lesson: $id');
        }
      }

      // 4. Bulk upsert sections
      if (sectionsToUpsert.isNotEmpty) {
        await _client.from('sections').upsert(sectionsToUpsert);
        AppLogger.d('[$_tag] Upserted ${sectionsToUpsert.length} sections');
      }

      // 5. Bulk upsert lessons
      if (lessonsToUpsert.isNotEmpty) {
        await _client.from('lessons').upsert(lessonsToUpsert);
        AppLogger.d('[$_tag] Upserted ${lessonsToUpsert.length} lessons');
      }

      AppLogger.success('[$_tag] saveSectionsAndLessons success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] saveSectionsAndLessons error', e, s);
      rethrow;
    }
  }

  /// Create a single section
  Future<String> createSection(String courseId, SectionCreateDto dto) async {
    AppLogger.d('[$_tag] createSection: courseId=$courseId');
    try {
      int sortOrder = dto.sortOrder ?? 0;
      if (dto.sortOrder == null) {
        final existing = await _client
            .from('sections')
            .select('sort_order')
            .eq('course_id', courseId)
            .order('sort_order', ascending: false)
            .limit(1);
        if ((existing as List).isNotEmpty) {
          sortOrder = (existing[0]['sort_order'] as int? ?? 0) + 1;
        }
      }

      final data = dto.toJson();
      data['course_id'] = courseId;
      data['sort_order'] = sortOrder;

      final response =
          await _client.from('sections').insert(data).select().single();
      AppLogger.success('[$_tag] createSection success: ${response['id']}');
      return response['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] createSection error', e, s);
      rethrow;
    }
  }

  /// Update a single section
  Future<bool> updateSection(String sectionId, SectionUpdateDto dto) async {
    AppLogger.d('[$_tag] updateSection: sectionId=$sectionId');
    try {
      final data = dto.toJson();
      if (data.isEmpty) return true;

      await _client.from('sections').update(data).eq('id', sectionId);
      AppLogger.success('[$_tag] updateSection success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateSection error', e, s);
      rethrow;
    }
  }

  /// Delete a single section
  Future<bool> deleteSection(String sectionId) async {
    AppLogger.d('[$_tag] deleteSection: sectionId=$sectionId');
    try {
      await _client.from('sections').delete().eq('id', sectionId);
      AppLogger.success('[$_tag] deleteSection success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteSection error', e, s);
      rethrow;
    }
  }

  /// Reorder sections
  Future<bool> reorderSections(String courseId, List<String> sectionIds) async {
    AppLogger.d('[$_tag] reorderSections: courseId=$courseId');
    try {
      for (int i = 0; i < sectionIds.length; i++) {
        await _client
            .from('sections')
            .update({'sort_order': i})
            .eq('id', sectionIds[i])
            .eq('course_id', courseId);
      }
      AppLogger.success('[$_tag] reorderSections success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reorderSections error', e, s);
      rethrow;
    }
  }

  /// Create a single lesson
  Future<String> createLesson(
      String sectionId, String courseId, LessonCreateDto dto) async {
    AppLogger.d('[$_tag] createLesson: sectionId=$sectionId');
    try {
      int sortOrder = dto.sortOrder ?? 0;
      if (dto.sortOrder == null) {
        final existing = await _client
            .from('lessons')
            .select('sort_order')
            .eq('section_id', sectionId)
            .order('sort_order', ascending: false)
            .limit(1);
        if ((existing as List).isNotEmpty) {
          sortOrder = (existing[0]['sort_order'] as int? ?? 0) + 1;
        }
      }

      final data = dto.toJson();
      data['section_id'] = sectionId;
      data['course_id'] = courseId;
      data['sort_order'] = sortOrder;

      final response =
          await _client.from('lessons').insert(data).select().single();
      AppLogger.success('[$_tag] createLesson success: ${response['id']}');
      return response['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] createLesson error', e, s);
      rethrow;
    }
  }

  /// Update a single lesson
  Future<bool> updateLesson(String lessonId, LessonUpdateDto dto) async {
    AppLogger.d('[$_tag] updateLesson: lessonId=$lessonId');
    try {
      final data = dto.toJson();
      if (data.isEmpty) return true;

      await _client.from('lessons').update(data).eq('id', lessonId);
      AppLogger.success('[$_tag] updateLesson success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateLesson error', e, s);
      rethrow;
    }
  }

  /// Delete a single lesson
  Future<bool> deleteLesson(String lessonId) async {
    AppLogger.d('[$_tag] deleteLesson: lessonId=$lessonId');
    try {
      await _client.from('lessons').delete().eq('id', lessonId);
      AppLogger.success('[$_tag] deleteLesson success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteLesson error', e, s);
      rethrow;
    }
  }

  /// Reorder lessons within a section
  Future<bool> reorderLessons(String sectionId, List<String> lessonIds) async {
    AppLogger.d('[$_tag] reorderLessons: sectionId=$sectionId');
    try {
      for (int i = 0; i < lessonIds.length; i++) {
        await _client
            .from('lessons')
            .update({'sort_order': i})
            .eq('id', lessonIds[i])
            .eq('section_id', sectionId);
      }
      AppLogger.success('[$_tag] reorderLessons success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reorderLessons error', e, s);
      rethrow;
    }
  }

  /// Add course attachment
  Future<String> addCourseAttachment({
    required String courseId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
    required int sortOrder,
  }) async {
    AppLogger.d(
        '[$_tag] addCourseAttachment: courseId=$courseId, fileName=$fileName');
    try {
      final response = await _client
          .from('course_attachments')
          .insert({
            'course_id': courseId,
            'file_name': fileName,
            'file_url': fileUrl,
            'file_type': fileType,
            'file_size': fileSize,
            'sort_order': sortOrder,
          })
          .select()
          .single();

      AppLogger.success(
          '[$_tag] addCourseAttachment success: ${response['id']}');
      return response['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] addCourseAttachment error', e, s);
      rethrow;
    }
  }

  /// Delete all course attachments
  Future<bool> deleteAllCourseAttachments(String courseId) async {
    AppLogger.d('[$_tag] deleteAllCourseAttachments: courseId=$courseId');
    try {
      await _client
          .from('course_attachments')
          .delete()
          .eq('course_id', courseId);
      AppLogger.success('[$_tag] deleteAllCourseAttachments success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAllCourseAttachments error', e, s);
      rethrow;
    }
  }

  /// Get all course attachments
  Future<List<AttachmentDto>> getCourseAttachments(String courseId) async {
    AppLogger.d('[$_tag] getCourseAttachments: courseId=$courseId');
    try {
      final response = await _client
          .from('course_attachments')
          .select('*')
          .eq('course_id', courseId)
          .order('sort_order');

      AppLogger.success(
          '[$_tag] getCourseAttachments: ${(response as List).length} attachments');
      return response.map((a) {
        return AttachmentDto(
          id: a['id'] as String?,
          fileName: a['file_name'] as String? ?? '',
          fileUrl: a['file_url'] as String? ?? '',
          fileType: a['file_type'] as String? ?? '',
          fileSize: a['file_size'] as int? ?? 0,
          sortOrder: a['sort_order'] as int? ?? 0,
        );
      }).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCourseAttachments error', e, s);
      rethrow;
    }
  }

  // ============================================================
  // Section & Lesson Activation Control
  // ============================================================

  /// Toggle section published status
  Future<bool> toggleSectionPublished(String sectionId) async {
    AppLogger.d('[$_tag] toggleSectionPublished: sectionId=$sectionId');
    try {
      final response = await _client.rpc('toggle_section_published', params: {
        'p_section_id': sectionId,
        'p_instructor_id': _userId,
      });

      final result = response as Map<String, dynamic>;
      if (result['success'] == true) {
        AppLogger.success(
            '[$_tag] toggleSectionPublished: is_published=${result['is_published']}');
        return result['is_published'] as bool;
      } else {
        throw Exception(result['error'] ?? 'Failed to toggle section');
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleSectionPublished error', e, s);
      rethrow;
    }
  }

  /// Schedule section publishing
  Future<void> scheduleSectionPublish(
    String sectionId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  }) async {
    AppLogger.d('[$_tag] scheduleSectionPublish: sectionId=$sectionId');
    try {
      await _client.from('sections').update({
        'available_from': publishAt?.toUtc().toIso8601String(),
        'available_until': unpublishAt?.toUtc().toIso8601String(),
      }).eq('id', sectionId);
      AppLogger.success('[$_tag] scheduleSectionPublish success');
    } catch (e, s) {
      AppLogger.e('[$_tag] scheduleSectionPublish error', e, s);
      rethrow;
    }
  }

  /// Toggle lesson published status
  Future<bool> toggleLessonPublished(String lessonId) async {
    AppLogger.d('[$_tag] toggleLessonPublished: lessonId=$lessonId');
    try {
      final response = await _client.rpc('toggle_lesson_published', params: {
        'p_lesson_id': lessonId,
        'p_instructor_id': _userId,
      });

      final result = response as Map<String, dynamic>;
      if (result['success'] == true) {
        AppLogger.success(
            '[$_tag] toggleLessonPublished: is_published=${result['is_published']}');
        return result['is_published'] as bool;
      } else {
        throw Exception(result['error'] ?? 'Failed to toggle lesson');
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleLessonPublished error', e, s);
      rethrow;
    }
  }

  /// Schedule lesson publishing
  Future<void> scheduleLessonPublish(
    String lessonId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  }) async {
    AppLogger.d('[$_tag] scheduleLessonPublish: lessonId=$lessonId');
    try {
      await _client.from('lessons').update({
        'available_from': publishAt?.toUtc().toIso8601String(),
        'available_until': unpublishAt?.toUtc().toIso8601String(),
      }).eq('id', lessonId);
      AppLogger.success('[$_tag] scheduleLessonPublish success');
    } catch (e, s) {
      AppLogger.e('[$_tag] scheduleLessonPublish error', e, s);
      rethrow;
    }
  }

  /// Set section published status directly
  Future<void> setSectionPublished(String sectionId, bool isPublished) async {
    AppLogger.d(
        '[$_tag] setSectionPublished: sectionId=$sectionId, isPublished=$isPublished');
    try {
      await _client.from('sections').update({
        'is_published': isPublished,
        'available_from': null,
        'available_until': null,
      }).eq('id', sectionId);
      AppLogger.success('[$_tag] setSectionPublished success');
    } catch (e, s) {
      AppLogger.e('[$_tag] setSectionPublished error', e, s);
      rethrow;
    }
  }

  /// Set lesson published status directly
  Future<void> setLessonPublished(String lessonId, bool isPublished) async {
    AppLogger.d(
        '[$_tag] setLessonPublished: lessonId=$lessonId, isPublished=$isPublished');
    try {
      await _client.from('lessons').update({
        'is_published': isPublished,
        'available_from': null,
        'available_until': null,
      }).eq('id', lessonId);
      AppLogger.success('[$_tag] setLessonPublished success');
    } catch (e, s) {
      AppLogger.e('[$_tag] setLessonPublished error', e, s);
      rethrow;
    }
  }
}
