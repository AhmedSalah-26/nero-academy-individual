import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/student/home/domain/entities/banner_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/category_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';

/// Home State
class HomeState extends Equatable {
  final HomeStatus status;
  final List<BannerEntity> banners;
  final List<CategoryEntity> categories;
  final List<CourseEntity> featuredCourses;
  final List<CourseEntity> popularCourses;
  final List<CourseEntity> newCourses;
  final List<CourseEntity> flashSaleCourses;
  final String? selectedCategoryId;
  final String? errorMessage;
  final bool isRefreshing;

  const HomeState({
    this.status = HomeStatus.initial,
    this.banners = const [],
    this.categories = const [],
    this.featuredCourses = const [],
    this.popularCourses = const [],
    this.newCourses = const [],
    this.flashSaleCourses = const [],
    this.selectedCategoryId,
    this.errorMessage,
    this.isRefreshing = false,
  });

  bool get isLoading => status == HomeStatus.loading;
  bool get isLoaded => status == HomeStatus.loaded;
  bool get isError => status == HomeStatus.error;
  bool get hasFlashSale => flashSaleCourses.isNotEmpty;

  HomeState copyWith({
    HomeStatus? status,
    List<BannerEntity>? banners,
    List<CategoryEntity>? categories,
    List<CourseEntity>? featuredCourses,
    List<CourseEntity>? popularCourses,
    List<CourseEntity>? newCourses,
    List<CourseEntity>? flashSaleCourses,
    String? selectedCategoryId,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      featuredCourses: featuredCourses ?? this.featuredCourses,
      popularCourses: popularCourses ?? this.popularCourses,
      newCourses: newCourses ?? this.newCourses,
      flashSaleCourses: flashSaleCourses ?? this.flashSaleCourses,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        banners,
        categories,
        featuredCourses,
        popularCourses,
        newCourses,
        flashSaleCourses,
        selectedCategoryId,
        errorMessage,
        isRefreshing,
      ];
}

/// Home Status Enum
enum HomeStatus { initial, loading, loaded, error }
