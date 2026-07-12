import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/home/domain/entities/banner_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/category_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/home/domain/usecases/get_banners_usecase.dart';
import 'package:lms_platform/features/student/home/domain/usecases/get_categories_usecase.dart';
import 'package:lms_platform/features/student/home/domain/usecases/get_featured_courses_usecase.dart';
import 'package:lms_platform/features/student/home/domain/usecases/get_flash_sale_courses_usecase.dart';
import 'package:lms_platform/features/student/home/domain/usecases/get_new_courses_usecase.dart';
import 'package:lms_platform/features/student/home/domain/usecases/get_popular_courses_usecase.dart';
import 'home_state.dart';

/// Home Cubit - Manages Home Screen State
class HomeCubit extends Cubit<HomeState> {
  final GetBannersUseCase getBannersUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetFeaturedCoursesUseCase getFeaturedCoursesUseCase;
  final GetPopularCoursesUseCase getPopularCoursesUseCase;
  final GetNewCoursesUseCase getNewCoursesUseCase;
  final GetFlashSaleCoursesUseCase getFlashSaleCoursesUseCase;

  HomeCubit({
    required this.getBannersUseCase,
    required this.getCategoriesUseCase,
    required this.getFeaturedCoursesUseCase,
    required this.getPopularCoursesUseCase,
    required this.getNewCoursesUseCase,
    required this.getFlashSaleCoursesUseCase,
  }) : super(const HomeState());

  /// Load all home data
  Future<void> loadHomeData() async {
    emit(state.copyWith(status: HomeStatus.loading));

    // Load all data in parallel
    final bannersResult = await getBannersUseCase();
    final categoriesResult = await getCategoriesUseCase();
    final featuredResult = await getFeaturedCoursesUseCase(
        const GetFeaturedCoursesParams(limit: 10));
    final popularResult = await getPopularCoursesUseCase(
        const GetPopularCoursesParams(limit: 10));
    final newResult =
        await getNewCoursesUseCase(const GetNewCoursesParams(limit: 10));
    final flashSaleResult = await getFlashSaleCoursesUseCase(
        const GetFlashSaleCoursesParams(limit: 10));

    // Check for any errors
    String? errorMessage;
    bannersResult.fold((f) => errorMessage ??= f.message, (_) {});
    categoriesResult.fold((f) => errorMessage ??= f.message, (_) {});
    featuredResult.fold((f) => errorMessage ??= f.message, (_) {});
    popularResult.fold((f) => errorMessage ??= f.message, (_) {});
    newResult.fold((f) => errorMessage ??= f.message, (_) {});
    flashSaleResult.fold((f) => errorMessage ??= f.message, (_) {});

    emit(state.copyWith(
      status: errorMessage != null ? HomeStatus.error : HomeStatus.loaded,
      banners: bannersResult.fold((_) => <BannerEntity>[], (b) => b),
      categories: categoriesResult.fold((_) => <CategoryEntity>[], (c) => c),
      featuredCourses: featuredResult.fold((_) => <CourseEntity>[], (c) => c),
      popularCourses: popularResult.fold((_) => <CourseEntity>[], (c) => c),
      newCourses: newResult.fold((_) => <CourseEntity>[], (c) => c),
      flashSaleCourses: flashSaleResult.fold((_) => <CourseEntity>[], (c) => c),
      errorMessage: errorMessage,
    ));
  }

  /// Refresh home data
  Future<void> refreshHomeData() async {
    try {
      emit(state.copyWith(isRefreshing: true));
      await loadHomeData();
    } catch (e) {
      AppLogger.e('[HomeCubit] Error refreshing home data', e);
    } finally {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  /// Select category filter
  void selectCategory(String? categoryId) {
    emit(state.copyWith(selectedCategoryId: categoryId));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
