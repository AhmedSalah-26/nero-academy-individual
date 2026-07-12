import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/services/teacher_context_service.dart';
import 'package:lms_platform/core/utils/availability_window.dart';
import 'package:lms_platform/features/student/home/data/models/banner_model.dart';
import 'package:lms_platform/features/student/home/data/models/category_model.dart';
import 'package:lms_platform/features/student/home/data/models/course_model.dart';

/// Home Remote Data Source - Handles Supabase operations for Home
abstract class HomeRemoteDataSource {
  Future<List<BannerModel>> getBanners();
  Future<List<CategoryModel>> getCategories();
  Future<List<CourseModel>> getFeaturedCourses({int limit = 10});
  Future<List<CourseModel>> getPopularCourses({int limit = 10});
  Future<List<CourseModel>> getNewCourses({int limit = 10});
  Future<List<CourseModel>> getFlashSaleCourses({int limit = 10});
  Future<List<CourseModel>> getCoursesByCategory(String categoryId,
      {int limit = 10});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient supabase;

  HomeRemoteDataSourceImpl(this.supabase);

  static const _courseSelect = '''
    id, title_ar, title_en, subtitle_ar, subtitle_en, thumbnail_url, preview_video_url,
    teacher_id, instructor_id, category_id, level, language, price, discount_price, currency,
    is_free, is_flash_sale, flash_sale_start, flash_sale_end,
    badge, pricing_options,
    rating, rating_count, enrolled_count, total_duration, total_lessons,
    is_featured, is_published, published_at, created_at,
    available_from, available_until,
    profiles:instructor_id(name, avatar_url)
  ''';

  List<CourseModel> _mapAvailableCourses(List<dynamic> response, {int? limit}) {
    final courses = response
        .cast<Map<String, dynamic>>()
        .where(AvailabilityWindow.isJsonActive)
        .map((json) => CourseModel.fromJson(json))
        .toList();
    return limit == null ? courses : courses.take(limit).toList();
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyTeacherScope(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
  ) {
    final teacherId = TeacherContextService.instance.selectedTeacherId;
    return teacherId == null ? query : query.eq('teacher_id', teacherId);
  }

  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await supabase
          .from('banners')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => BannerModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    }
  }

  @override
  Future<List<CourseModel>> getFeaturedCourses({int limit = 10}) async {
    try {
      final query = _applyTeacherScope(supabase
              .from('courses')
              .select(_courseSelect)
              .eq('is_published', true)
              .eq('is_featured', true))
          .order('published_at', ascending: false)
          .limit(limit * 3);
      final response = await query;

      return _mapAvailableCourses(response as List, limit: limit);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    }
  }

  @override
  Future<List<CourseModel>> getPopularCourses({int limit = 10}) async {
    try {
      final query = _applyTeacherScope(supabase
              .from('courses')
              .select(_courseSelect)
              .eq('is_published', true))
          .order('enrolled_count', ascending: false)
          .limit(limit * 3);
      final response = await query;

      return _mapAvailableCourses(response as List, limit: limit);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    }
  }

  @override
  Future<List<CourseModel>> getNewCourses({int limit = 10}) async {
    try {
      final query = _applyTeacherScope(supabase
              .from('courses')
              .select(_courseSelect)
              .eq('is_published', true))
          .order('published_at', ascending: false)
          .limit(limit * 3);
      final response = await query;

      return _mapAvailableCourses(response as List, limit: limit);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    }
  }

  @override
  Future<List<CourseModel>> getFlashSaleCourses({int limit = 10}) async {
    try {
      final now = DateTime.now().toIso8601String();
      final query = _applyTeacherScope(supabase
              .from('courses')
              .select(_courseSelect)
              .eq('is_published', true)
              .eq('is_flash_sale', true)
              .lte('flash_sale_start', now)
              .gte('flash_sale_end', now))
          .order('flash_sale_end', ascending: true)
          .limit(limit * 3);
      final response = await query;

      return _mapAvailableCourses(response as List, limit: limit);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    }
  }

  @override
  Future<List<CourseModel>> getCoursesByCategory(String categoryId,
      {int limit = 10}) async {
    try {
      final query = _applyTeacherScope(supabase
              .from('courses')
              .select(_courseSelect)
              .eq('is_published', true)
              .eq('category_id', categoryId))
          .order('enrolled_count', ascending: false)
          .limit(limit * 3);
      final response = await query;

      return _mapAvailableCourses(response as List, limit: limit);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    }
  }
}
