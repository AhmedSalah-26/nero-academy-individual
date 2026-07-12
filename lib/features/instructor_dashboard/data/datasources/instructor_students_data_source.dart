import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_models.dart';

/// Instructor Students Data Source - Student management
class InstructorStudentsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorStudentsDS';

  InstructorStudentsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get students enrolled in instructor's courses
  Future<List<InstructorStudentModel>> getStudents({
    String? courseId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getStudents: courseId=$courseId, search=$search');
    try {
      var query = _client.from('enrollments').select('''
            id, user_id, course_id, progress_percentage, enrolled_at, last_accessed_at,
            completed_at, total_watch_time, status,
            user:profiles!enrollments_user_id_fkey(
              id, name, email, phone, avatar_url, role,
              interests, is_active, is_banned, banned_until, ban_reason,
              created_at, updated_at
            ),
            course:courses!inner(id, title_ar, title_en, instructor_id)
          ''').eq('course.instructor_id', _userId);

      if (courseId != null) {
        query = query.eq('course_id', courseId);
      }

      final response = await query
          .order('enrolled_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final Map<String, Map<String, dynamic>> studentsMap = {};

      for (final enrollment in (response as List)) {
        final user = enrollment['user'] as Map<String, dynamic>;
        final odId = user['id'] as String;
        final isCompleted = enrollment['completed_at'] != null;
        final watchTime = (enrollment['total_watch_time'] as int?) ?? 0;

        if (!studentsMap.containsKey(odId)) {
          studentsMap[odId] = {
            'id': odId,
            'name': user['name'] ?? '',
            'email': user['email'] ?? '',
            'phone': user['phone'],
            'avatar_url': user['avatar_url'],
            'role': user['role'] ?? 'student',
            'interests': user['interests'] ?? [],
            'is_active': user['is_active'] ?? true,
            'is_banned': user['is_banned'] ?? false,
            'banned_until': user['banned_until'],
            'ban_reason': user['ban_reason'],
            'created_at': user['created_at'],
            'updated_at': user['updated_at'],
            'enrolled_courses': 1,
            'completed_courses': isCompleted ? 1 : 0,
            'total_progress':
                (enrollment['progress_percentage'] as num?)?.toDouble() ?? 0,
            'total_watch_time': watchTime,
            'last_active_at': enrollment['last_accessed_at'],
            'enrolled_at': enrollment['enrolled_at'],
          };
        } else {
          studentsMap[odId]!['enrolled_courses'] =
              (studentsMap[odId]!['enrolled_courses'] as int) + 1;
          if (isCompleted) {
            studentsMap[odId]!['completed_courses'] =
                (studentsMap[odId]!['completed_courses'] as int) + 1;
          }
          studentsMap[odId]!['total_progress'] =
              (studentsMap[odId]!['total_progress'] as double) +
                  ((enrollment['progress_percentage'] as num?)?.toDouble() ??
                      0);
          studentsMap[odId]!['total_watch_time'] =
              (studentsMap[odId]!['total_watch_time'] as int) + watchTime;
        }
      }

      // Calculate average progress
      for (final student in studentsMap.values) {
        final count = student['enrolled_courses'] as int;
        if (count > 1) {
          student['total_progress'] =
              (student['total_progress'] as double) / count;
        }
      }

      var students = studentsMap.values.toList();
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        students = students.where((s) {
          final name = (s['name'] as String).toLowerCase();
          final email = (s['email'] as String).toLowerCase();
          final phone = (s['phone'] as String?)?.toLowerCase() ?? '';
          return name.contains(searchLower) ||
              email.contains(searchLower) ||
              phone.contains(searchLower);
        }).toList();
      }

      AppLogger.success('[$_tag] getStudents: ${students.length} students');
      return students.map((e) => InstructorStudentModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getStudents error', e, s);
      rethrow;
    }
  }

  /// Get student enrollments
  Future<List<StudentEnrollmentDetail>> getStudentEnrollments(
      String studentId) async {
    AppLogger.d(
        '[$_tag] getStudentEnrollments: studentId=$studentId, instructorId=$_userId');
    try {
      // First, get all courses owned by this instructor
      final instructorCourses = await _client
          .from('courses')
          .select('id')
          .eq('instructor_id', _userId);

      final courseIds =
          (instructorCourses as List).map((c) => c['id'] as String).toList();

      AppLogger.d('[$_tag] Instructor course IDs: $courseIds');

      if (courseIds.isEmpty) {
        AppLogger.d('[$_tag] No courses found for instructor');
        return [];
      }

      // Get enrollments for this student in instructor's courses
      final response = await _client
          .from('enrollments')
          .select('''
            id, course_id, progress_percentage, completed_lessons, status,
            enrolled_at, last_accessed_at, completed_at,
            course:courses(title_ar, title_en, thumbnail_url, instructor_id, total_lessons)
          ''')
          .eq('user_id', studentId)
          .inFilter('course_id', courseIds)
          .order('enrolled_at', ascending: false);

      AppLogger.success(
          '[$_tag] getStudentEnrollments: ${(response as List).length} enrollments found');
      return response.map((e) => StudentEnrollmentDetail.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getStudentEnrollments error', e, s);
      rethrow;
    }
  }

  /// Get student progress
  Future<List<StudentCourseProgress>> getStudentProgress(
      String studentId) async {
    AppLogger.d(
        '[$_tag] getStudentProgress: studentId=$studentId, instructorId=$_userId');
    try {
      // First, get all courses owned by this instructor
      final instructorCourses = await _client
          .from('courses')
          .select('id')
          .eq('instructor_id', _userId);

      final courseIds =
          (instructorCourses as List).map((c) => c['id'] as String).toList();

      if (courseIds.isEmpty) {
        AppLogger.d('[$_tag] No courses found for instructor');
        return [];
      }

      final enrollments = await _client.from('enrollments').select('''
            course_id, progress_percentage,
            course:courses(title_ar, title_en, instructor_id)
          ''').eq('user_id', studentId).inFilter('course_id', courseIds);

      final List<StudentCourseProgress> progressList = [];

      for (final enrollment in enrollments as List) {
        final courseId = enrollment['course_id'] as String;

        final lessonProgress = await _client.from('lesson_progress').select('''
              lesson_id, is_completed, watch_time, completed_at,
              lesson:lessons(title_ar, title_en, type)
            ''').eq('user_id', studentId).eq('course_id', courseId);

        final lessons = (lessonProgress as List).map((lp) {
          return StudentLessonProgress(
            lessonId: lp['lesson_id'] as String,
            titleAr: lp['lesson']?['title_ar'] as String? ?? '',
            titleEn: lp['lesson']?['title_en'] as String? ?? '',
            type: lp['lesson']?['type'] as String? ?? 'video',
            isCompleted: lp['is_completed'] as bool? ?? false,
            watchTimeSeconds: lp['watch_time'] as int? ?? 0,
            completedAt: lp['completed_at'] != null
                ? DateTime.parse(lp['completed_at'] as String)
                : null,
          );
        }).toList();

        progressList.add(StudentCourseProgress(
          courseId: courseId,
          courseTitleAr: enrollment['course']?['title_ar'] as String? ?? '',
          courseTitleEn: enrollment['course']?['title_en'] as String? ?? '',
          overallProgress:
              (enrollment['progress_percentage'] as num?)?.toDouble() ?? 0,
          lessons: lessons,
        ));
      }

      AppLogger.success(
          '[$_tag] getStudentProgress: ${progressList.length} courses');
      return progressList;
    } catch (e, s) {
      AppLogger.e('[$_tag] getStudentProgress error', e, s);
      rethrow;
    }
  }

  /// Send message to student
  Future<bool> sendMessageToStudent(
      String studentId, String subject, String message) async {
    AppLogger.d('[$_tag] sendMessageToStudent: studentId=$studentId');
    try {
      await _client.from('notifications').insert({
        'user_id': studentId,
        'type': 'instructor_message',
        'title_ar': subject,
        'title_en': subject,
        'body_ar': message,
        'body_en': message,
        'data': {'from_instructor_id': _userId, 'type': 'direct_message'},
      });
      AppLogger.success('[$_tag] sendMessageToStudent success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] sendMessageToStudent error', e, s);
      rethrow;
    }
  }
}
