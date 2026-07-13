import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_models.dart';

/// Instructor Enrollments Data Source - Enrollment management
class InstructorEnrollmentsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorEnrollmentsDS';

  InstructorEnrollmentsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get enrollments
  Future<List<InstructorEnrollmentModel>> getEnrollments({
    InstructorEnrollmentStatus? status,
    String? courseId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getEnrollments: status=$status, courseId=$courseId');
    try {
      var query = _client
          .from('enrollments')
          .select('''*, course:courses!inner(title_ar, teacher_id),
            user:profiles!enrollments_user_id_fkey(name, avatar_url)''').eq('course.teacher_id', _userId);

      if (courseId != null) query = query.eq('course_id', courseId);
      if (status != null && status != InstructorEnrollmentStatus.all) {
        if (status == InstructorEnrollmentStatus.completed) {
          query = query.eq('status', 'completed');
        } else if (status == InstructorEnrollmentStatus.active) {
          query = query.eq('status', 'active');
        }
      }
      if (startDate != null) {
        query = query.gte('enrolled_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('enrolled_at', endDate.toIso8601String());
      }

      final response = await query
          .order('enrolled_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getEnrollments: ${(response as List).length} enrollments');
      return response
          .map((e) => InstructorEnrollmentModel.fromJson(e))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getEnrollments error', e, s);
      rethrow;
    }
  }

  /// Extend enrollment access
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days) async {
    AppLogger.d('[$_tag] extendEnrollmentAccess: $enrollmentId, days=$days');
    try {
      final enrollment = await _client
          .from('enrollments')
          .select('access_expires_at, course:courses!inner(teacher_id)')
          .eq('id', enrollmentId)
          .eq('course.teacher_id', _userId)
          .single();

      DateTime newExpiry;
      if (enrollment['access_expires_at'] != null) {
        final currentExpiry =
            DateTime.parse(enrollment['access_expires_at'] as String);
        newExpiry = currentExpiry.add(Duration(days: days));
      } else {
        newExpiry = DateTime.now().add(Duration(days: days));
      }

      await _client.from('enrollments').update({
        'access_expires_at': newExpiry.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', enrollmentId);

      AppLogger.success('[$_tag] extendEnrollmentAccess success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] extendEnrollmentAccess error', e, s);
      rethrow;
    }
  }

  /// Reset enrollment progress
  Future<bool> resetEnrollmentProgress(String enrollmentId) async {
    AppLogger.d('[$_tag] resetEnrollmentProgress: $enrollmentId');
    try {
      final enrollment = await _client
          .from('enrollments')
          .select('user_id, course_id, course:courses!inner(teacher_id)')
          .eq('id', enrollmentId)
          .eq('course.teacher_id', _userId)
          .single();

      final odId = enrollment['user_id'] as String;
      final courseId = enrollment['course_id'] as String;

      await _client
          .from('lesson_progress')
          .delete()
          .eq('user_id', odId)
          .eq('course_id', courseId);

      await _client.from('enrollments').update({
        'progress_percentage': 0,
        'completed_lessons': 0,
        'total_watch_time': 0,
        'completed_at': null,
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', enrollmentId);

      AppLogger.success('[$_tag] resetEnrollmentProgress success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] resetEnrollmentProgress error', e, s);
      rethrow;
    }
  }

  /// Update enrollment status
  Future<bool> updateEnrollmentStatus(
      String enrollmentId, String status) async {
    AppLogger.d(
        '[$_tag] updateEnrollmentStatus: $enrollmentId, status=$status');
    try {
      await _client
          .from('enrollments')
          .select('id, course:courses!inner(teacher_id)')
          .eq('id', enrollmentId)
          .eq('course.teacher_id', _userId)
          .single();

      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        updateData['progress_percentage'] = 100;
      }

      await _client
          .from('enrollments')
          .update(updateData)
          .eq('id', enrollmentId);

      AppLogger.success('[$_tag] updateEnrollmentStatus success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateEnrollmentStatus error', e, s);
      rethrow;
    }
  }

  /// Mark enrollment as completed (certificates feature removed)
  Future<bool> markAsCompleted(String enrollmentId) async {
    AppLogger.d('[$_tag] markAsCompleted: $enrollmentId');
    try {
      // Verify instructor owns this enrollment
      await _client
          .from('enrollments')
          .select('id, course:courses!inner(teacher_id)')
          .eq('id', enrollmentId)
          .eq('course.teacher_id', _userId)
          .single();

      await _client.from('enrollments').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'progress_percentage': 100,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', enrollmentId);

      AppLogger.success('[$_tag] markAsCompleted success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] issueCertificate error', e, s);
      rethrow;
    }
  }

  /// Enroll student in a course
  Future<bool> enrollStudent(String studentId, String courseId) async {
    AppLogger.d(
        '[$_tag] enrollStudent: studentId=$studentId, courseId=$courseId');
    try {
      await _client
          .from('courses')
          .select('id')
          .eq('id', courseId)
          .eq('teacher_id', _userId)
          .single();

      await _client.from('enrollments').insert({
        'user_id': studentId,
        'course_id': courseId,
        'teacher_id': _userId,
        'price': 0,
        'discount': 0,
        'status': 'active',
        'enrolled_at': DateTime.now().toIso8601String(),
      });

      await _client
          .rpc('increment_enrolled_count', params: {'p_course_id': courseId});

      AppLogger.success('[$_tag] enrollStudent success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] enrollStudent error', e, s);
      rethrow;
    }
  }

  /// Unenroll student from a course
  Future<bool> unenrollStudent(String enrollmentId) async {
    AppLogger.d('[$_tag] unenrollStudent: $enrollmentId');
    try {
      final enrollment = await _client
          .from('enrollments')
          .select('course_id, user_id, course:courses!inner(teacher_id)')
          .eq('id', enrollmentId)
          .eq('course.teacher_id', _userId)
          .single();

      final courseId = enrollment['course_id'] as String;
      final odId = enrollment['user_id'] as String;

      await _client
          .from('lesson_progress')
          .delete()
          .eq('user_id', odId)
          .eq('course_id', courseId);

      await _client.from('enrollments').delete().eq('id', enrollmentId);

      // Decrement enrolled_count on the course (non-fatal if function missing)
      try {
        await _client
            .rpc('decrement_enrolled_count', params: {'p_course_id': courseId});
      } catch (rpcError) {
        AppLogger.w(
            '[$_tag] decrement_enrolled_count RPC failed (non-fatal): $rpcError');
      }

      AppLogger.success('[$_tag] unenrollStudent success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unenrollStudent error', e, s);
      rethrow;
    }
  }

  /// Get available courses for student enrollment
  Future<List<AvailableCourseForEnrollment>> getAvailableCoursesForStudent(
      String studentId) async {
    AppLogger.d('[$_tag] getAvailableCoursesForStudent: $studentId');
    try {
      final allCourses = await _client
          .from('courses')
          .select('id, title_ar, title_en, thumbnail_url')
          .eq('teacher_id', _userId)
          .eq('is_published', true);

      final enrolledResponse = await _client
          .from('enrollments')
          .select('course_id, course:courses!inner(teacher_id)')
          .eq('user_id', studentId)
          .eq('course.teacher_id', _userId);

      final enrolledCourseIds = (enrolledResponse as List)
          .map((e) => e['course_id'] as String)
          .toSet();

      final availableCourses = (allCourses as List)
          .where((c) => !enrolledCourseIds.contains(c['id']))
          .map((c) =>
              AvailableCourseForEnrollment.fromJson(c as Map<String, dynamic>))
          .toList();

      AppLogger.success(
          '[$_tag] getAvailableCoursesForStudent: ${availableCourses.length}');
      return availableCourses;
    } catch (e, s) {
      AppLogger.e('[$_tag] getAvailableCoursesForStudent error', e, s);
      rethrow;
    }
  }
}
