import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/availability_window.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../models/course_model.dart';
import '../models/search_filter_model.dart';

/// Course Search Remote Data Source - Abstract
abstract class CourseSearchRemoteDataSource {
  Future<CourseSearchRemoteResult> searchCourses(SearchFilterModel filter);
  Future<List<CategoryModel>> getCategories();
  Future<List<String>> getPopularSearches();
}

/// Course Search Remote Result
class CourseSearchRemoteResult {
  final List<CourseModel> courses;
  final int totalCount;

  const CourseSearchRemoteResult({
    required this.courses,
    required this.totalCount,
  });
}

/// Course Search Remote Data Source Implementation
class CourseSearchRemoteDataSourceImpl implements CourseSearchRemoteDataSource {
  final SupabaseClient _supabase;

  CourseSearchRemoteDataSourceImpl(this._supabase);

  @override
  Future<CourseSearchRemoteResult> searchCourses(
    SearchFilterModel filter,
  ) async {
    try {
      // Build base query with correct column names from schema
      var queryBuilder = _supabase.from('courses').select('''
        id,
        title_ar,
        title_en,
        thumbnail_url,
        price,
        discount_price,
        flash_sale_start,
        flash_sale_end,
        rating,
        rating_count,
        level,
        total_duration,
        total_lessons,
        is_featured,
        is_flash_sale,
        badge,
        available_from,
        available_until,
        created_at,
        category_id,
        categories(name_ar, name_en),
        profiles!courses_instructor_id_fkey(name, avatar_url)
      ''');

      // Apply filters using dynamic query building
      PostgrestFilterBuilder<List<Map<String, dynamic>>> filteredQuery =
          queryBuilder;

      // Apply search query (search in both Arabic and English titles)
      if (filter.query != null && filter.query!.isNotEmpty) {
        filteredQuery = filteredQuery.or(
            'title_ar.ilike.%${filter.query}%,title_en.ilike.%${filter.query}%');
      }

      // Apply category filter
      if (filter.categoryIds.isNotEmpty) {
        filteredQuery =
            filteredQuery.inFilter('category_id', filter.categoryIds);
      }

      // Apply price filters
      if (filter.minPrice != null) {
        filteredQuery = filteredQuery.gte('price', filter.minPrice!);
      }
      if (filter.maxPrice != null) {
        filteredQuery = filteredQuery.lte('price', filter.maxPrice!);
      }

      // Apply rating filter
      if (filter.minRating != null) {
        filteredQuery = filteredQuery.gte('rating', filter.minRating!);
      }

      // Apply level filter
      if (filter.level != null && filter.level != CourseLevel.all) {
        filteredQuery = filteredQuery.eq('level', filter.level!.name);
      }

      // Only show published and active courses
      filteredQuery = filteredQuery.eq('is_published', true);
      filteredQuery = filteredQuery.eq('is_active', true);

      // Get total count
      final countResponse = await _supabase
          .from('courses')
          .select('id')
          .eq('is_published', true)
          .eq('is_active', true)
          .count(CountOption.exact);
      final totalCount = countResponse.count;

      // Apply sorting and pagination
      final offset = (filter.page - 1) * filter.pageSize;
      final sortColumn = _getSortColumn(filter.sortBy);
      final ascending = _isSortAscending(filter.sortBy);

      final response = await filteredQuery
          .order(sortColumn, ascending: ascending)
          .range(offset, offset + (filter.pageSize * 3) - 1);

      final courses = response.where(AvailabilityWindow.isJsonActive).map((json) {
        final courseJson = Map<String, dynamic>.from(json);
        final now = DateTime.now();
        final flashSaleStart = _parseDateTime(courseJson['flash_sale_start']);
        final flashSaleEnd = _parseDateTime(courseJson['flash_sale_end']);
        final isFlashSaleActive = courseJson['is_flash_sale'] == true &&
            (flashSaleStart == null || !now.isBefore(flashSaleStart)) &&
            (flashSaleEnd == null || !now.isAfter(flashSaleEnd));

        // Flatten nested data
        if (courseJson['profiles'] != null) {
          courseJson['instructor_name'] = courseJson['profiles']['name'] ?? '';
          courseJson['instructor_avatar'] =
              courseJson['profiles']['avatar_url'];
        }
        if (courseJson['categories'] != null) {
          courseJson['category_name'] =
              courseJson['categories']['name_ar'] ?? '';
        }
        // Map fields to model expected names
        courseJson['title'] = courseJson['title_ar'] ?? courseJson['title_en'];
        courseJson['review_count'] = courseJson['rating_count'] ?? 0;
        final originalPrice = (courseJson['price'] as num?)?.toDouble() ?? 0;
        final discountPrice =
            (courseJson['discount_price'] as num?)?.toDouble();
        final isFlashSaleCourse = courseJson['is_flash_sale'] == true;

        // Discount applies if: permanent (no flash sale) OR flash sale is active
        final showDiscount = discountPrice != null &&
            discountPrice < originalPrice &&
            (!isFlashSaleCourse || isFlashSaleActive);

        if (showDiscount) {
          courseJson['original_price'] = originalPrice;
          courseJson['price'] = discountPrice;
        } else {
          courseJson['original_price'] = null;
          courseJson['price'] = originalPrice;
        }

        courseJson['duration_minutes'] = courseJson['total_duration'];
        courseJson['lecture_count'] = courseJson['total_lessons'];
        // Set badge
        final storedBadge = (courseJson['badge'] as String?)?.trim();
        if (storedBadge != null && storedBadge.isNotEmpty) {
          // If flash sale badge but sale not active, skip it
          if (isFlashSaleCourse && !isFlashSaleActive) {
            courseJson['badge'] = null;
          } else {
            courseJson['badge'] = storedBadge;
          }
        } else if (courseJson['is_featured'] == true) {
          courseJson['badge'] = 'premium';
        } else if (isFlashSaleActive) {
          courseJson['badge'] = 'hot';
        }
        return CourseModel.fromJson(courseJson);
      }).take(filter.pageSize).toList();

      return CourseSearchRemoteResult(
        courses: courses,
        totalCount: totalCount,
      );
    } catch (e) {
      throw ServerException('Failed to search courses: $e');
    }
  }

  String _getSortColumn(CourseSortOption sortBy) {
    switch (sortBy) {
      case CourseSortOption.relevance:
      case CourseSortOption.mostReviewed:
        return 'rating_count';
      case CourseSortOption.newest:
        return 'created_at';
      case CourseSortOption.highestRated:
        return 'rating';
      case CourseSortOption.priceLowToHigh:
      case CourseSortOption.priceHighToLow:
        return 'price';
    }
  }

  bool _isSortAscending(CourseSortOption sortBy) {
    switch (sortBy) {
      case CourseSortOption.priceLowToHigh:
        return true;
      default:
        return false;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name_ar, name_en, icon_name, courses_count')
          .eq('is_active', true)
          .order('sort_order');

      return (response as List).map((json) {
        // Map to expected field names
        json['name'] = json['name_ar'] ?? json['name_en'];
        json['course_count'] = json['courses_count'] ?? 0;
        return CategoryModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw ServerException('Failed to get categories: $e');
    }
  }

  @override
  Future<List<String>> getPopularSearches() async {
    try {
      final response = await _supabase
          .from('popular_searches')
          .select('query')
          .order('search_count', ascending: false)
          .limit(10);

      return (response as List).map((json) => json['query'] as String).toList();
    } catch (e) {
      // Return empty list if table doesn't exist
      return [];
    }
  }
}
