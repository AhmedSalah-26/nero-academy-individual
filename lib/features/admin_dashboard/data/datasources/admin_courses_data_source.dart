import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/admin_entities.dart';
import '../models/admin_models.dart';

/// Admin Courses Data Source - Course and category management
class AdminCoursesDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminCoursesDS';

  AdminCoursesDataSource(this._client);

  /// Get courses
  Future<List<AdminCourseModel>> getCourses({
    CourseStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getCourses: status=$status, search=$search');
    try {
      var query = _client.from('courses').select(
          '*, instructor:profiles!instructor_id(name), category:categories(name_ar)');

      if (status != null && status != CourseStatus.all) {
        switch (status) {
          case CourseStatus.published:
            query = query.eq('is_published', true).eq('is_suspended', false);
            break;
          case CourseStatus.draft:
            query = query.eq('is_published', false);
            break;
          case CourseStatus.suspended:
            query = query.eq('is_suspended', true);
            break;
          default:
            break;
        }
      }

      if (search != null && search.isNotEmpty) {
        query = query.or('title_ar.ilike.%$search%,title_en.ilike.%$search%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success('[$_tag] getCourses: ${response.length} courses');
      return response.map((e) => AdminCourseModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCourses error', e, s);
      rethrow;
    }
  }

  /// Suspend course
  Future<bool> suspendCourse(String courseId, String reason) async {
    AppLogger.d('[$_tag] suspendCourse: $courseId');
    try {
      await _client.rpc('admin_suspend_course', params: {
        'p_course_id': courseId,
        'p_reason': reason,
      });
      AppLogger.success('[$_tag] suspendCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] suspendCourse error', e, s);
      rethrow;
    }
  }

  /// Unsuspend course
  Future<bool> unsuspendCourse(String courseId) async {
    AppLogger.d('[$_tag] unsuspendCourse: $courseId');
    try {
      await _client.from('courses').update({
        'is_suspended': false,
        'suspension_reason': null,
      }).eq('id', courseId);
      AppLogger.success('[$_tag] unsuspendCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unsuspendCourse error', e, s);
      rethrow;
    }
  }

  /// Delete course
  Future<bool> deleteCourse(String courseId) async {
    AppLogger.d('[$_tag] deleteCourse: $courseId');
    try {
      await _client.from('courses').delete().eq('id', courseId);
      AppLogger.success('[$_tag] deleteCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteCourse error', e, s);
      rethrow;
    }
  }

  /// Feature course
  Future<bool> featureCourse(String courseId) async {
    AppLogger.d('[$_tag] featureCourse: $courseId');
    try {
      await _client.from('courses').update({
        'is_featured': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      AppLogger.success('[$_tag] featureCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] featureCourse error', e, s);
      rethrow;
    }
  }

  /// Unfeature course
  Future<bool> unfeatureCourse(String courseId) async {
    AppLogger.d('[$_tag] unfeatureCourse: $courseId');
    try {
      await _client.from('courses').update({
        'is_featured': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      AppLogger.success('[$_tag] unfeatureCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unfeatureCourse error', e, s);
      rethrow;
    }
  }

  /// Get categories
  Future<List<CategoryModel>> getCategories({bool? isActive}) async {
    AppLogger.d('[$_tag] getCategories: isActive=$isActive');
    try {
      var query = _client.from('categories').select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('sort_order', ascending: true);
      AppLogger.success('[$_tag] getCategories: ${response.length} categories');
      return response.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCategories error', e, s);
      rethrow;
    }
  }

  /// Create category
  Future<CategoryModel> createCategory(Map<String, dynamic> data) async {
    AppLogger.d('[$_tag] createCategory');
    try {
      final response =
          await _client.from('categories').insert(data).select().single();
      AppLogger.success('[$_tag] createCategory success');
      return CategoryModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] createCategory error', e, s);
      rethrow;
    }
  }

  /// Update category
  Future<CategoryModel> updateCategory(
      String id, Map<String, dynamic> data) async {
    AppLogger.d('[$_tag] updateCategory: $id');
    try {
      final response = await _client
          .from('categories')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      AppLogger.success('[$_tag] updateCategory success');
      return CategoryModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] updateCategory error', e, s);
      rethrow;
    }
  }

  /// Get enrollments
  Future<List<AdminEnrollmentModel>> getEnrollments({
    EnrollmentStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getEnrollments: status=$status, page=$page');
    try {
      var query = _client.from('enrollments').select(
          '*, course:courses(title_ar), user:profiles!enrollments_user_id_fkey(name, email)');

      if (status != null && status != EnrollmentStatus.all) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('enrolled_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getEnrollments: ${response.length} enrollments');
      return response.map((e) => AdminEnrollmentModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getEnrollments error', e, s);
      rethrow;
    }
  }

  /// Process refund
  Future<bool> processRefund(String enrollmentId, String reason) async {
    AppLogger.d('[$_tag] processRefund: $enrollmentId');
    try {
      await _client.rpc('process_refund', params: {
        'p_enrollment_id': enrollmentId,
        'p_reason': reason,
      });
      AppLogger.success('[$_tag] processRefund success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] processRefund error', e, s);
      rethrow;
    }
  }

  /// Publish course (admin override)
  Future<bool> publishCourse(String courseId) async {
    AppLogger.d('[$_tag] publishCourse: $courseId');
    try {
      await _client.from('courses').update({
        'is_published': true,
        'published_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      AppLogger.success('[$_tag] publishCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] publishCourse error', e, s);
      rethrow;
    }
  }

  /// Unpublish course (admin override)
  Future<bool> unpublishCourse(String courseId) async {
    AppLogger.d('[$_tag] unpublishCourse: $courseId');
    try {
      await _client.from('courses').update({
        'is_published': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      AppLogger.success('[$_tag] unpublishCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unpublishCourse error', e, s);
      rethrow;
    }
  }

  /// Enroll student in a course (admin)
  Future<bool> enrollStudent(String studentId, String courseId) async {
    AppLogger.d('[$_tag] enrollStudent: student=$studentId, course=$courseId');
    try {
      await _client.from('enrollments').insert({
        'user_id': studentId,
        'course_id': courseId,
        'status': 'active',
        'enrolled_at': DateTime.now().toIso8601String(),
        'payment_method': 'admin_grant',
        'amount_paid': 0,
      });
      AppLogger.success('[$_tag] enrollStudent success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] enrollStudent error', e, s);
      rethrow;
    }
  }

  /// Cancel enrollment (admin)
  Future<bool> cancelEnrollment(String enrollmentId) async {
    AppLogger.d('[$_tag] cancelEnrollment: $enrollmentId');
    try {
      await _client.from('enrollments').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', enrollmentId);
      AppLogger.success('[$_tag] cancelEnrollment success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] cancelEnrollment error', e, s);
      rethrow;
    }
  }

  /// Extend enrollment access (admin)
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days) async {
    AppLogger.d('[$_tag] extendEnrollmentAccess: $enrollmentId, +$days days');
    try {
      // Get current enrollment
      final enrollment = await _client
          .from('enrollments')
          .select('access_expires_at')
          .eq('id', enrollmentId)
          .single();

      DateTime currentExpiry;
      if (enrollment['access_expires_at'] != null) {
        currentExpiry = DateTime.parse(enrollment['access_expires_at']);
      } else {
        currentExpiry = DateTime.now();
      }

      final newExpiry = currentExpiry.add(Duration(days: days));

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
}
