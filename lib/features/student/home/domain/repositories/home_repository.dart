import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/home/domain/entities/banner_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/category_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';

/// Home Repository Contract - Abstract Interface
abstract class HomeRepository {
  /// Get active banners for carousel
  Future<Either<Failure, List<BannerEntity>>> getBanners();

  /// Get all active categories
  Future<Either<Failure, List<CategoryEntity>>> getCategories();

  /// Get featured courses (is_featured = true)
  Future<Either<Failure, List<CourseEntity>>> getFeaturedCourses(
      {int limit = 10});

  /// Get popular courses (sorted by enrolled_count)
  Future<Either<Failure, List<CourseEntity>>> getPopularCourses(
      {int limit = 10});

  /// Get new courses (sorted by published_at)
  Future<Either<Failure, List<CourseEntity>>> getNewCourses({int limit = 10});

  /// Get flash sale courses (is_flash_sale = true with active dates)
  Future<Either<Failure, List<CourseEntity>>> getFlashSaleCourses(
      {int limit = 10});

  /// Get courses by category
  Future<Either<Failure, List<CourseEntity>>> getCoursesByCategory(
      String categoryId,
      {int limit = 10});
}
