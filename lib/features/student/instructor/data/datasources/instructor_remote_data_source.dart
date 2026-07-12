import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/instructor/domain/entities/instructor_entity.dart';
import 'package:lms_platform/features/student/instructor/domain/entities/instructor_course_entity.dart';

abstract class InstructorRemoteDataSource {
  Future<InstructorEntity?> getInstructor(String visitorId);
  Future<List<InstructorCourseEntity>> getInstructorCourses(String visitorId);
  Future<List<InstructorEntity>> getTopInstructors({int limit = 10});
}

class InstructorRemoteDataSourceImpl implements InstructorRemoteDataSource {
  final SupabaseClient client;

  InstructorRemoteDataSourceImpl(this.client);

  @override
  Future<InstructorEntity?> getInstructor(String visitorId) async {
    AppLogger.i('[Instructor] Loading instructor: $visitorId');

    // 1. Fetch profile
    final profile = await client
        .from('profiles')
        .select()
        .eq('id', visitorId)
        .maybeSingle();

    if (profile == null) {
      AppLogger.w('[Instructor] Profile not found: $visitorId');
      return null;
    }

    // 2. Fetch teacher details (for display name, bio fallback, etc.)
    final teacher = await client
        .from('teachers')
        .select('display_name, avatar_url, bio')
        .eq('profile_id', visitorId)
        .maybeSingle();

    // 3. Gather stats from courses
    final coursesResponse = await client
        .from('courses')
        .select('id, rating, rating_count')
        .eq('instructor_id', visitorId);

    final courses = coursesResponse as List;
    int totalStudents = 0;
    double totalRating = 0;
    int totalReviews = 0;

    for (final course in courses) {
      final row = course as Map<String, dynamic>;
      totalRating += _asDouble(row['rating']);
      totalReviews += row['rating_count'] as int? ?? 0;
    }

    if (courses.isNotEmpty) {
      final courseIds = courses
          .map((c) => (c as Map<String, dynamic>)['id'])
          .where((id) => id != null)
          .toList();
      if (courseIds.isNotEmpty) {
        final enrollmentsResponse = await client
            .from('enrollments')
            .select('id')
            .inFilter('course_id', courseIds);
        totalStudents = (enrollmentsResponse as List).length;
      }
    }

    final socialLinks = profile['social_links'] as Map<String, dynamic>?;

    return InstructorEntity(
      id: profile['id'] as String,
      name: teacher?['display_name'] ??
          profile['name'] ??
          profile['email']?.split('@').first ??
          'Instructor',
      avatarUrl: teacher?['avatar_url'] ?? profile['avatar_url'],
      coverImageUrl: null,
      headline: _sanitizeText(profile['headline_ar']) ??
          _sanitizeText(profile['headline_en']),
      bio: _sanitizeText(profile['bio_ar']) ??
          _sanitizeText(profile['bio_en']) ??
          teacher?['bio'],
      expertise: profile['expertise'] != null
          ? List<String>.from(profile['expertise'] as List)
          : null,
      totalStudents: totalStudents,
      totalCourses: courses.length,
      averageRating: courses.isNotEmpty ? totalRating / courses.length : 0.0,
      totalReviews: totalReviews,
      website: _sanitizeText(socialLinks?['website']),
      linkedin: _sanitizeText(socialLinks?['linkedin']),
      twitter: _sanitizeText(socialLinks?['twitter']),
      facebook: _sanitizeText(socialLinks?['facebook']),
      youtube: _sanitizeText(socialLinks?['youtube']),
      joinedAt: _parseDate(profile['created_at']),
    );
  }

  String? _sanitizeText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _parseDate(dynamic value) {
    final raw = _sanitizeText(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Future<List<InstructorCourseEntity>> getInstructorCourses(
      String visitorId) async {
    AppLogger.i('[Instructor] Loading courses for: $visitorId');

    final response = await client
        .from('courses')
        .select()
        .eq('instructor_id', visitorId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final row = json as Map<String, dynamic>;
      return InstructorCourseEntity(
        id: row['id'] as String,
        title: row['title_en'] ?? row['title_ar'] ?? '',
        titleAr: row['title_ar'] as String?,
        thumbnailUrl: row['thumbnail_url'] as String?,
        price: _asDouble(row['price']),
        discountPrice: row['discount_price'] != null
            ? _asDouble(row['discount_price'])
            : null,
        isFlashSale: row['is_flash_sale'] == true,
        flashSaleStart: row['flash_sale_start'] != null
            ? DateTime.tryParse(row['flash_sale_start'].toString())
            : null,
        flashSaleEnd: row['flash_sale_end'] != null
            ? DateTime.tryParse(row['flash_sale_end'].toString())
            : null,
        currency: row['currency'] as String? ?? 'EGP',
        rating: _asDouble(row['rating']),
        ratingCount: row['rating_count'] as int? ?? 0,
        enrolledCount: row['enrolled_count'] as int? ?? 0,
        isFree: row['is_free'] == true,
        isBestseller: (row['enrolled_count'] as int? ?? 0) > 100,
      );
    }).toList();
  }

  @override
  Future<List<InstructorEntity>> getTopInstructors({int limit = 10}) async {
    AppLogger.i('[Instructor] Loading top instructors (limit: $limit)');

    final instructors = <InstructorEntity>[];

    var query = client
        .from('profiles')
        .select()
        .eq('role', 'instructor')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final response = limit > 0 ? await query.limit(limit) : await query;

    for (final row in (response as List)) {
      final profile = row as Map<String, dynamic>;
      final profileId = profile['id'] as String;

      final mapped = await getInstructor(profileId);
      if (mapped != null) {
        instructors.add(mapped);
      }
    }

    return instructors;
  }
}
