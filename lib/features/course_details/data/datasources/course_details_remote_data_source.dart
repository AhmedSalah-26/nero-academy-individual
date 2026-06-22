import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/utils/availability_window.dart';
import '../../domain/entities/course_details_entity.dart';
import '../models/course_details_model.dart';
import '../models/section_model.dart';
import '../models/review_model.dart';

/// Course Details Remote Data Source - API calls
abstract class CourseDetailsRemoteDataSource {
  Future<CourseDetailsModel> getCourseDetails(String courseId,
      {String? userId});
  Future<List<SectionModel>> getCourseCurriculum(String courseId,
      {String? userId});
  Future<List<ReviewModel>> getCourseReviews(String courseId,
      {int page, int limit, String? sortBy});
  Future<RatingSummaryModel> getRatingSummary(String courseId);
  Future<bool> toggleWishlist(String courseId, String userId);
  Future<bool> isInWishlist(String courseId, String userId);
  Future<bool> isInCart(String courseId, String userId);
}

class CourseDetailsRemoteDataSourceImpl
    implements CourseDetailsRemoteDataSource {
  final SupabaseClient supabaseClient;

  CourseDetailsRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<CourseDetailsModel> getCourseDetails(String courseId,
      {String? userId}) async {
    try {
      // First get course with basic instructor info from profiles.
      // Use maybeSingle to avoid hard failure when no row is returned
      // (e.g., instructor previewing draft/suspended course).
      final query = supabaseClient.from('courses').select('''
        *,
        profiles!courses_instructor_id_fkey(
          id, name, avatar_url
        ),
        sections(
          id, course_id, title_ar, title_en, sort_order, is_published,
          lessons(
            id, section_id, title_ar, title_en, type, video_url, video_provider,
            video_duration, is_preview, is_mandatory, is_published, sort_order,
            available_from, available_until
          )
        ),
        quizzes!quizzes_course_id_fkey(count)
      ''').eq('id', courseId);

      final data = await (userId == null
          ? query.eq('is_published', true).maybeSingle()
          : query.maybeSingle());

      if (data == null) {
        throw const ServerException('Course not found');
      }

      final isPublished = data['is_published'] == true;
      final instructorId = data['instructor_id'] as String?;
      final isOwnerInstructor = userId != null && instructorId == userId;

      // Allow non-published course access only for owner instructor.
      if (!isPublished && !isOwnerInstructor) {
        throw const ServerException('Course not found');
      }
      if (!isOwnerInstructor && !AvailabilityWindow.isJsonActive(data)) {
        throw const ServerException('Course not found');
      }

      // Extract quizzes count
      final quizzesData = data['quizzes'] as List?;
      final quizzesCount = quizzesData?.isNotEmpty == true
          ? quizzesData!.first['count'] as int? ?? 0
          : 0;
      data['total_quizzes'] = quizzesCount;

      // Get instructor_profiles for additional stats
      if (instructorId != null) {
        final instructorProfile =
            await supabaseClient.from('instructor_profiles').select('''
              id, display_name, headline_ar, headline_en, bio_ar, bio_en,
              avatar_url, cover_image_url, expertise, social_links, website_url,
              total_students, total_courses, average_rating, is_verified
            ''').eq('instructor_id', instructorId).limit(1).maybeSingle();

        if (instructorProfile != null) {
          data['instructor_profiles'] = instructorProfile;
        } else {
          // Use profiles data as fallback
          final profile = data['profiles'] as Map<String, dynamic>?;
          if (profile != null) {
            data['instructor_profiles'] = {
              'id': profile['id'],
              'display_name': profile['name'],
              'avatar_url': profile['avatar_url'],
              'headline_ar': null,
              'headline_en': null,
              'bio_ar': null,
              'bio_en': null,
              'cover_image_url': null,
              'expertise': const <String>[],
              'social_links': const <String, dynamic>{},
              'website_url': null,
              'total_students': 0,
              'total_courses': 0,
              'average_rating': 0.0,
              'is_verified': false,
            };
          }
        }
      }

      // Check wishlist and cart status if user is logged in
      bool isInWishlist = false;
      bool isInCart = false;
      String? enrollmentStatus;
      String? enrollmentId;
      double progressPercentage = 0;

      if (userId != null) {
        final wishlistResult = await supabaseClient
            .from('wishlist')
            .select('id')
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .limit(1)
            .maybeSingle();
        isInWishlist = wishlistResult != null;

        final cartResult = await supabaseClient
            .from('cart_items')
            .select('id')
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .limit(1)
            .maybeSingle();
        isInCart = cartResult != null;

        // Check enrollment status
        final enrollmentResult = await supabaseClient
            .from('enrollments')
            .select('id, status, progress_percentage')
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .limit(1)
            .maybeSingle();

        if (enrollmentResult != null) {
          enrollmentId = enrollmentResult['id'] as String?;
          enrollmentStatus = enrollmentResult['status'] as String?;
          progressPercentage =
              (enrollmentResult['progress_percentage'] as num?)?.toDouble() ??
                  0;
        }
      }

      data['is_in_wishlist'] = isInWishlist;
      data['is_in_cart'] = isInCart;
      data['enrollment_id'] = enrollmentId;
      data['enrollment_status'] = enrollmentStatus;
      data['progress_percentage'] = progressPercentage;

      // Students should never see unpublished sections/lessons.
      if (!isOwnerInstructor) {
        _filterUnpublishedCurriculumForStudent(data, updateCounts: false);
      }

      // For non-enrolled users, RLS may return only preview lessons.
      // Fallback to SECURITY DEFINER RPC to get full curriculum metadata
      // so locked lessons are still visible in course details.
      await _hydratePublicCurriculumIfNeeded(courseId: courseId, data: data);

      if (!isOwnerInstructor) {
        _filterUnpublishedCurriculumForStudent(data);
      }

      return CourseDetailsModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> _hydratePublicCurriculumIfNeeded({
    required String courseId,
    required Map<String, dynamic> data,
  }) async {
    final enrollmentStatus =
        EnrollmentStatus.fromString(data['enrollment_status'] as String?);
    final isEnrolled = enrollmentStatus == EnrollmentStatus.enrolled ||
        enrollmentStatus == EnrollmentStatus.completed;
    if (isEnrolled) return;

    final currentSections = (data['sections'] as List?)?.cast<dynamic>() ?? [];
    final visibleLessonsCount = _countLessonsInSections(currentSections);
    final totalLessons = (data['total_lessons'] as int?) ?? 0;

    // No fallback needed when curriculum is already complete.
    if (totalLessons <= 0 || visibleLessonsCount >= totalLessons) {
      return;
    }

    final previewVideoByLessonId = _buildPreviewVideoLookup(currentSections);
    final locale = _resolveLocale(data['language'] as String?);

    try {
      final rpcResult = await supabaseClient.rpc(
        'get_course_details',
        params: {
          'p_course_id': courseId,
          'p_locale': locale,
        },
      );

      if (rpcResult is! Map<String, dynamic>) {
        return;
      }

      final rpcSections = (rpcResult['sections'] as List?)?.cast<dynamic>();
      if (rpcSections == null || rpcSections.isEmpty) {
        return;
      }

      final mappedSections = <Map<String, dynamic>>[];

      for (var sectionIndex = 0;
          sectionIndex < rpcSections.length;
          sectionIndex++) {
        final sectionRaw = rpcSections[sectionIndex];
        if (sectionRaw is! Map<String, dynamic>) continue;

        final sectionId = (sectionRaw['id'] ?? '').toString();
        if (sectionId.isEmpty) continue;

        final sectionTitle = (sectionRaw['title'] ?? '').toString();
        final lessonsRaw =
            (sectionRaw['lessons'] as List?)?.cast<dynamic>() ?? [];

        final mappedLessons = <Map<String, dynamic>>[];
        for (var lessonIndex = 0;
            lessonIndex < lessonsRaw.length;
            lessonIndex++) {
          final lessonRaw = lessonsRaw[lessonIndex];
          if (lessonRaw is! Map<String, dynamic>) continue;

          final lessonId = (lessonRaw['id'] ?? '').toString();
          if (lessonId.isEmpty) continue;

          final lessonTitle = (lessonRaw['title'] ?? '').toString();
          final previewVideo = previewVideoByLessonId[lessonId];

          mappedLessons.add({
            'id': lessonId,
            'section_id': sectionId,
            'title_ar': lessonTitle,
            'title_en': lessonTitle,
            'type': (lessonRaw['type'] ?? 'video').toString(),
            'video_url': previewVideo?['video_url'],
            'video_provider': previewVideo?['video_provider'],
            'video_duration': _toInt(lessonRaw['duration']),
            'is_preview': lessonRaw['is_preview'] == true,
            'is_mandatory': true,
            'is_published': true,
            'sort_order': lessonIndex,
            'available_from': lessonRaw['available_from'],
            'available_until': lessonRaw['available_until'],
          });
        }

        mappedSections.add({
          'id': sectionId,
          'course_id': courseId,
          'title_ar': sectionTitle,
          'title_en': sectionTitle,
          'sort_order': sectionIndex,
          'is_published': true,
          'lessons': mappedLessons,
        });
      }

      if (mappedSections.isNotEmpty) {
        data['sections'] = mappedSections;
      }
    } catch (e) {
      AppLogger.w(
          '[CourseDetailsDS] Public curriculum RPC fallback failed, keeping original sections',
          e);
    }
  }

  int _countLessonsInSections(List<dynamic> sections) {
    var count = 0;
    for (final section in sections) {
      if (section is! Map<String, dynamic>) continue;
      final lessons = (section['lessons'] as List?)?.cast<dynamic>() ?? [];
      count += lessons.length;
    }
    return count;
  }

  Map<String, Map<String, dynamic>> _buildPreviewVideoLookup(
      List<dynamic> sections) {
    final result = <String, Map<String, dynamic>>{};
    for (final section in sections) {
      if (section is! Map<String, dynamic>) continue;
      final lessons = (section['lessons'] as List?)?.cast<dynamic>() ?? [];
      for (final lesson in lessons) {
        if (lesson is! Map<String, dynamic>) continue;
        final lessonId = (lesson['id'] ?? '').toString();
        if (lessonId.isEmpty) continue;
        final videoUrl = lesson['video_url'];
        if (videoUrl == null || (videoUrl as String).trim().isEmpty) continue;

        result[lessonId] = {
          'video_url': videoUrl,
          'video_provider': lesson['video_provider'],
        };
      }
    }
    return result;
  }

  String _resolveLocale(String? language) {
    final normalized = (language ?? '').toLowerCase();
    if (normalized.startsWith('en')) {
      return 'en';
    }
    return 'ar';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _filterUnpublishedCurriculumForStudent(
    Map<String, dynamic> data, {
    bool updateCounts = true,
  }) {
    final rawSections = (data['sections'] as List?)?.cast<dynamic>() ?? [];
    final filteredSections = _filterPublishedSections(rawSections);
    data['sections'] = filteredSections;

    if (updateCounts) {
      final lessonsCount = filteredSections.fold<int>(0, (sum, section) {
        final lessons = (section['lessons'] as List?)?.cast<dynamic>() ?? [];
        return sum + lessons.length;
      });
      data['total_sections'] = filteredSections.length;
      data['total_lessons'] = lessonsCount;
    }
  }

  List<Map<String, dynamic>> _filterPublishedSections(
      List<dynamic> rawSections) {
    final filteredSections = <Map<String, dynamic>>[];

    for (final sectionRaw in rawSections) {
      if (sectionRaw is! Map<String, dynamic>) continue;

      final sectionPublished = sectionRaw['is_published'];
      if (sectionPublished is bool && !sectionPublished) continue;

      final rawLessons =
          (sectionRaw['lessons'] as List?)?.cast<dynamic>() ?? [];
      final filteredLessons = <Map<String, dynamic>>[];

      for (final lessonRaw in rawLessons) {
        if (lessonRaw is! Map<String, dynamic>) continue;
        final lessonPublished = lessonRaw['is_published'];
        if (lessonPublished is bool && !lessonPublished) continue;
        if (!AvailabilityWindow.isJsonActive(lessonRaw)) continue;
        filteredLessons.add(Map<String, dynamic>.from(lessonRaw));
      }

      if (filteredLessons.isEmpty) continue;

      final section = Map<String, dynamic>.from(sectionRaw);
      section['lessons'] = filteredLessons;
      filteredSections.add(section);
    }

    return filteredSections;
  }

  @override
  Future<List<SectionModel>> getCourseCurriculum(String courseId,
      {String? userId}) async {
    try {
      String lessonSelect = '''
        id, section_id, title_ar, title_en, type, video_url, video_provider,
        video_duration, is_preview, is_mandatory, is_published, sort_order,
        available_from, available_until
      ''';

      // Add lesson progress if user is logged in
      if (userId != null) {
        lessonSelect += ', lesson_progress!left(is_completed, last_position)';
      }

      final data = await supabaseClient
          .from('sections')
          .select('*, lessons($lessonSelect)')
          .eq('course_id', courseId)
          .eq('is_published', true)
          .order('sort_order');

      final filteredSections =
          _filterPublishedSections((data as List).cast<dynamic>());

      return filteredSections.map((e) => SectionModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ReviewModel>> getCourseReviews(String courseId,
      {int page = 1, int limit = 10, String? sortBy}) async {
    try {
      final offset = (page - 1) * limit;
      final baseQuery = supabaseClient.from('course_reviews').select('''
        *,
        profiles!course_reviews_user_id_fkey(name, avatar_url)
      ''').eq('course_id', courseId);

      // Apply sorting and get data
      final data = sortBy == 'helpful'
          ? await baseQuery
              .order('helpful_count', ascending: false)
              .range(offset, offset + limit - 1)
          : await baseQuery
              .order('created_at', ascending: false)
              .range(offset, offset + limit - 1);

      return (data as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RatingSummaryModel> getRatingSummary(String courseId) async {
    try {
      final data = await supabaseClient
          .from('courses')
          .select('rating, rating_count')
          .eq('id', courseId)
          .single();

      // Get rating breakdown
      final reviews = await supabaseClient
          .from('course_reviews')
          .select('rating')
          .eq('course_id', courseId);

      int fiveStar = 0, fourStar = 0, threeStar = 0, twoStar = 0, oneStar = 0;
      for (final review in reviews as List) {
        switch (review['rating'] as int) {
          case 5:
            fiveStar++;
            break;
          case 4:
            fourStar++;
            break;
          case 3:
            threeStar++;
            break;
          case 2:
            twoStar++;
            break;
          case 1:
            oneStar++;
            break;
        }
      }

      return RatingSummaryModel(
        averageRating: (data['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: data['rating_count'] as int? ?? 0,
        fiveStarCount: fiveStar,
        fourStarCount: fourStar,
        threeStarCount: threeStar,
        twoStarCount: twoStar,
        oneStarCount: oneStar,
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> toggleWishlist(String courseId, String userId) async {
    try {
      final existing = await supabaseClient
          .from('wishlist')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        await supabaseClient.from('wishlist').delete().eq('id', existing['id']);
        return false;
      } else {
        await supabaseClient.from('wishlist').insert({
          'user_id': userId,
          'course_id': courseId,
        });
        return true;
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> isInWishlist(String courseId, String userId) async {
    try {
      final result = await supabaseClient
          .from('wishlist')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .limit(1)
          .maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isInCart(String courseId, String userId) async {
    try {
      final result = await supabaseClient
          .from('cart_items')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .limit(1)
          .maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }
}
