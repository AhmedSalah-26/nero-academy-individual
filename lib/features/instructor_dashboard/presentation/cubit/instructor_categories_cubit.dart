import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/category_model.dart';

part 'instructor_categories_state.dart';

/// Instructor Categories Cubit - Manage categories from the Instructor Dashboard
class InstructorCategoriesCubit extends Cubit<InstructorCategoriesState> {
  final InstructorRepository _repository;

  InstructorCategoriesCubit(this._repository)
      : super(const InstructorCategoriesState());

  /// Load categories
  Future<void> loadCategories({bool? isActive, bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(status: InstructorCategoriesStatus.loading));
    } else if (state.status != InstructorCategoriesStatus.initial) {
      return;
    } else {
      emit(state.copyWith(status: InstructorCategoriesStatus.loading));
    }

    try {
      final categories =
          await _repository.getAdminCategories(isActive: isActive);
      emit(state.copyWith(
        status: InstructorCategoriesStatus.success,
        categories: categories,
        isActiveFilter: isActive,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InstructorCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Create category
  Future<void> createCategory(CategoryCreateDto dto) async {
    emit(state.copyWith(actionStatus: InstructorCategoriesStatus.loading));
    try {
      await _repository.createCategory(dto);
      await loadCategories(isActive: state.isActiveFilter, refresh: true);
      emit(state.copyWith(actionStatus: InstructorCategoriesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: InstructorCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Update category
  Future<void> updateCategory(String id, CategoryUpdateDto dto) async {
    emit(state.copyWith(actionStatus: InstructorCategoriesStatus.loading));
    try {
      await _repository.updateCategory(id, dto);
      await loadCategories(isActive: state.isActiveFilter, refresh: true);
      emit(state.copyWith(actionStatus: InstructorCategoriesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: InstructorCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Toggle category status
  Future<void> toggleCategoryStatus(String id) async {
    emit(state.copyWith(actionStatus: InstructorCategoriesStatus.loading));
    try {
      await _repository.toggleCategoryStatus(id);
      await loadCategories(isActive: state.isActiveFilter, refresh: true);
      emit(state.copyWith(actionStatus: InstructorCategoriesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: InstructorCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Change active filter
  void changeActiveFilter(bool? isActive) {
    loadCategories(isActive: isActive, refresh: true);
  }
}
