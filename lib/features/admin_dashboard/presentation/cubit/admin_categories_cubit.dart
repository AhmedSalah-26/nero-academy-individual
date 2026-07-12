import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/models/category_model.dart';

part 'admin_categories_state.dart';

/// Admin Categories Cubit
class AdminCategoriesCubit extends Cubit<AdminCategoriesState> {
  final AdminRepository _repository;

  AdminCategoriesCubit(this._repository) : super(const AdminCategoriesState());

  /// Load categories
  Future<void> loadCategories({bool? isActive, bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(status: AdminCategoriesStatus.loading));
    } else if (state.status != AdminCategoriesStatus.initial) {
      return;
    } else {
      emit(state.copyWith(status: AdminCategoriesStatus.loading));
    }

    try {
      final categories = await _repository.getCategories(isActive: isActive);
      emit(state.copyWith(
        status: AdminCategoriesStatus.success,
        categories: categories,
        isActiveFilter: isActive,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Create category
  Future<void> createCategory(CategoryCreateDto dto) async {
    emit(state.copyWith(actionStatus: AdminCategoriesStatus.loading));
    try {
      await _repository.createCategory(dto);
      await loadCategories(isActive: state.isActiveFilter, refresh: true);
      emit(state.copyWith(actionStatus: AdminCategoriesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Update category
  Future<void> updateCategory(String id, CategoryUpdateDto dto) async {
    emit(state.copyWith(actionStatus: AdminCategoriesStatus.loading));
    try {
      await _repository.updateCategory(id, dto);
      await loadCategories(isActive: state.isActiveFilter, refresh: true);
      emit(state.copyWith(actionStatus: AdminCategoriesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Toggle category status
  Future<void> toggleCategoryStatus(String id) async {
    emit(state.copyWith(actionStatus: AdminCategoriesStatus.loading));
    try {
      await _repository.toggleCategoryStatus(id);
      await loadCategories(isActive: state.isActiveFilter, refresh: true);
      emit(state.copyWith(actionStatus: AdminCategoriesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCategoriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Change active filter
  void changeActiveFilter(bool? isActive) {
    loadCategories(isActive: isActive, refresh: true);
  }
}
