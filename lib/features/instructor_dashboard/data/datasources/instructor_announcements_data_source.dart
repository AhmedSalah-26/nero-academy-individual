import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';

/// Instructor Announcements Data Source
/// Uses the 'announcements' table (DB column: instructor_id, not user_id)
class InstructorAnnouncementsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorAnnouncementsDS';

  InstructorAnnouncementsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get announcements for a course
  Future<List<Map<String, dynamic>>> getAnnouncements({
    required String courseId,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAnnouncements: courseId=$courseId, page=$page');
    try {
      final response = await _client
          .from('announcements')
          .select(
              '*, instructor:profiles!announcements_instructor_id_fkey(name, avatar_url)')
          .eq('course_id', courseId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getAnnouncements: ${(response as List).length} items');
      // Normalize: add 'user_id' alias for instructor_id for UI compatibility
      return (response as List).map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        map['user_id'] = map['instructor_id'];
        return map;
      }).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getAnnouncements error', e, s);
      rethrow;
    }
  }

  /// Get all courses owned by the instructor (for selecting which course to announce to)
  Future<List<Map<String, dynamic>>> getMyCourses() async {
    AppLogger.d('[$_tag] getMyCourses');
    try {
      final response = await _client
          .from('courses')
          .select('id, title_ar, title_en')
          .eq('instructor_id', _userId)
          .eq('is_published', true)
          .order('title_ar');

      AppLogger.success(
          '[$_tag] getMyCourses: ${(response as List).length} courses');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] getMyCourses error', e, s);
      rethrow;
    }
  }

  /// Create announcement
  Future<bool> createAnnouncement({
    required String courseId,
    required String titleAr,
    String? titleEn,
    String? contentAr,
    String? contentEn,
  }) async {
    AppLogger.d('[$_tag] createAnnouncement: courseId=$courseId');
    try {
      await _client.from('announcements').insert({
        'course_id': courseId,
        'instructor_id': _userId, // DB column is instructor_id
        'title_ar': titleAr,
        'title_en': titleEn,
        'content_ar': contentAr,
        'content_en': contentEn,
        'is_published': true,
      });
      AppLogger.success('[$_tag] createAnnouncement success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] createAnnouncement error', e, s);
      rethrow;
    }
  }

  /// Update announcement
  Future<bool> updateAnnouncement(
      String announcementId, Map<String, dynamic> data) async {
    AppLogger.d('[$_tag] updateAnnouncement: $announcementId');
    try {
      // Remove user_id if passed (DB uses instructor_id)
      final dbData = Map<String, dynamic>.from(data);
      if (dbData.containsKey('user_id')) {
        dbData['instructor_id'] = dbData.remove('user_id');
      }
      dbData['updated_at'] = DateTime.now().toIso8601String();
      await _client
          .from('announcements')
          .update(dbData)
          .eq('id', announcementId)
          .eq('instructor_id', _userId);
      AppLogger.success('[$_tag] updateAnnouncement success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateAnnouncement error', e, s);
      rethrow;
    }
  }

  /// Delete announcement
  Future<bool> deleteAnnouncement(String announcementId) async {
    AppLogger.d('[$_tag] deleteAnnouncement: $announcementId');
    try {
      await _client
          .from('announcements')
          .delete()
          .eq('id', announcementId)
          .eq('instructor_id', _userId);
      AppLogger.success('[$_tag] deleteAnnouncement success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAnnouncement error', e, s);
      rethrow;
    }
  }
}
