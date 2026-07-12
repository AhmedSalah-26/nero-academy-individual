import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/teacher_context_service.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../models/enrollment_model.dart';
import '../models/learning_progress_model.dart';

/// My Learning Remote Data Source - Abstract Contract
abstract class MyLearningRemoteDataSource {
  Future<List<EnrollmentModel>> getEnrollments({
    required String userId,
    EnrollmentStatus? status,
    int page = 1,
    int limit = 20,
  });

  Future<EnrollmentModel?> getContinueLearning(String userId);

  Future<EnrollmentModel> getEnrollmentById(String enrollmentId);

  Future<LearningProgressModel> updateLessonProgress({
    required String enrollmentId,
    required String lessonId,
    required int watchedSeconds,
    bool isCompleted = false,
  });

  Future<LearningProgressModel?> getLessonProgress({
    required String enrollmentId,
    required String lessonId,
  });

  Future<EnrollmentModel> markCourseCompleted(String enrollmentId);

  Future<List<EnrollmentModel>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  });
}

/// My Learning Remote Data Source Implementation
class MyLearningRemoteDataSourceImpl implements MyLearningRemoteDataSource {
  final SupabaseClient _client;

  MyLearningRemoteDataSourceImpl(this._client);

  static const _enrollmentSelect = '''
    id,
    course_id,
    user_id,
    progress_percentage,
    completed_lessons,
    status,
    enrolled_at,
    last_accessed_at,
    completed_at,
    access_expires_at,
    courses!inner (
      title_ar,
      title_en,
      thumbnail_url,
      total_lessons,
      total_duration,
      rating,
      rating_count,
      available_from,
      available_until,
      teacher_id,
      instructor_id,
      profiles!courses_instructor_id_fkey (id, name, avatar_url)
    )
  ''';

  @override
  Future<List<EnrollmentModel>> getEnrollments({
    required String userId,
    EnrollmentStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final teacherId = TeacherContextService.instance.selectedTeacherId;
      var query = _client
          .from('enrollments')
          .select(_enrollmentSelect)
          .eq('user_id', userId)
          .neq('status', 'refunded') // exclude refunded enrollments
          .or('access_expires_at.is.null,access_expires_at.gt.${DateTime.now().toUtc().toIso8601String()}');

      if (teacherId != null) {
        query = query.eq('courses.teacher_id', teacherId);
      }

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('last_accessed_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final enrollments = (response as List)
          .map((json) => EnrollmentModel.fromJson(json))
          .toList();

      // Enrich with instructor data
      final enrichedEnrollments = <EnrollmentModel>[];
      for (final enrollment in enrollments) {
        if (enrollment.instructorId != null) {
          final instructorData =
              await _getInstructorProfile(enrollment.instructorId!);
          if (instructorData != null) {
            enrichedEnrollments.add(enrollment.copyWithInstructor(
              instructorName: instructorData['display_name'] as String?,
              instructorAvatar: instructorData['avatar_url'] as String?,
            ));
            continue;
          }
        }
        enrichedEnrollments.add(enrollment);
      }

      return enrichedEnrollments;
    } catch (e) {
      throw ServerException('Failed to load enrollments: $e');
    }
  }

  @override
  Future<EnrollmentModel?> getContinueLearning(String userId) async {
    try {
      final teacherId = TeacherContextService.instance.selectedTeacherId;
      var query = _client
          .from('enrollments')
          .select(_enrollmentSelect)
          .eq('user_id', userId)
          .eq('status', 'active')
          .or('access_expires_at.is.null,access_expires_at.gt.${DateTime.now().toUtc().toIso8601String()}')
          .gt('progress_percentage', 0);
      if (teacherId != null) {
        query = query.eq('courses.teacher_id', teacherId);
      }
      final response = await query
          .order('last_accessed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // Get instructor full data from instructor_profiles
      final enrollment = EnrollmentModel.fromJson(response);

      if (enrollment.instructorId != null) {
        final instructorData =
            await _getInstructorProfile(enrollment.instructorId!);
        if (instructorData != null) {
          final enriched = enrollment.copyWithInstructor(
            instructorName: instructorData['display_name'] as String?,
            instructorAvatar: instructorData['avatar_url'] as String?,
          );
          return enriched;
        }
      }

      return enrollment;
    } catch (e) {
      throw ServerException('Failed to load continue learning: $e');
    }
  }

  /// Get instructor profile data
  Future<Map<String, dynamic>?> _getInstructorProfile(
      String instructorId) async {
    try {
      final response = await _client
          .from('teachers')
          .select('display_name, avatar_url')
          .eq('profile_id', instructorId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<EnrollmentModel> getEnrollmentById(String enrollmentId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select(_enrollmentSelect)
          .eq('id', enrollmentId)
          .single();

      return EnrollmentModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to load enrollment: $e');
    }
  }

  @override
  Future<LearningProgressModel> updateLessonProgress({
    required String enrollmentId,
    required String lessonId,
    required int watchedSeconds,
    bool isCompleted = false,
  }) async {
    try {
      // Use the database function which triggers enrollment progress update
      await _client.rpc('update_lesson_progress', params: {
        'p_lesson_id': lessonId,
        'p_watch_time': watchedSeconds,
        'p_last_position': watchedSeconds,
        'p_is_completed': isCompleted,
      });

      // Fetch the updated progress
      final response = await _client
          .from('lesson_progress')
          .select()
          .eq('enrollment_id', enrollmentId)
          .eq('lesson_id', lessonId)
          .single();

      return LearningProgressModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update progress: $e');
    }
  }

  @override
  Future<LearningProgressModel?> getLessonProgress({
    required String enrollmentId,
    required String lessonId,
  }) async {
    try {
      final response = await _client
          .from('lesson_progress')
          .select()
          .eq('enrollment_id', enrollmentId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (response == null) return null;
      return LearningProgressModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to load lesson progress: $e');
    }
  }

  @override
  Future<EnrollmentModel> markCourseCompleted(String enrollmentId) async {
    try {
      final response = await _client
          .from('enrollments')
          .update({
            'status': 'completed',
            'progress_percentage': 100,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', enrollmentId)
          .select(_enrollmentSelect)
          .single();

      return EnrollmentModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to mark course completed: $e');
    }
  }

  @override
  Future<List<EnrollmentModel>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  }) async {
    try {
      // Get courses user hasn't enrolled in, based on popular courses
      final response = await _client.rpc(
        'get_recommended_courses',
        params: {'p_user_id': userId, 'p_limit': limit},
      );

      return (response as List)
          .map((json) => EnrollmentModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback: return empty list if RPC doesn't exist
      return [];
    }
  }
}
