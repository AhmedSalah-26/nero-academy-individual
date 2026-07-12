import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/banner_model.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';

part 'instructor_banners_state.dart';

/// Instructor Banners Cubit - Manages banner operations for instructor dashboard
class InstructorBannersCubit extends Cubit<InstructorBannersState> {
  final InstructorRepository _repository;

  InstructorBannersCubit(this._repository)
      : super(const InstructorBannersState());

  /// Load banners with optional filters
  Future<void> loadBanners({
    BannerType? type,
    bool? isActive,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: InstructorBannersStatus.loading,
        banners: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: InstructorBannersStatus.loading));
    }

    try {
      final banners = await _repository.getBanners(
        type: type,
        isActive: isActive,
      );
      emit(state.copyWith(
        status: InstructorBannersStatus.success,
        banners: banners,
        currentType: () => type,
        isActiveFilter: isActive,
        currentPage: 1,
        hasMore: banners.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InstructorBannersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Create new banner
  Future<bool> createBanner(BannerCreateDto dto) async {
    emit(state.copyWith(actionStatus: InstructorBannersStatus.creating));
    try {
      await _repository.createBanner(dto);
      // Refresh the list
      await loadBanners(
        type: state.currentType,
        isActive: state.isActiveFilter,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: InstructorBannersStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: InstructorBannersStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Update existing banner
  Future<bool> updateBanner(String id, BannerUpdateDto dto) async {
    emit(state.copyWith(actionStatus: InstructorBannersStatus.updating));
    try {
      await _repository.updateBanner(id, dto);
      // Refresh the list
      await loadBanners(
        type: state.currentType,
        isActive: state.isActiveFilter,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: InstructorBannersStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: InstructorBannersStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Toggle banner active status
  Future<void> toggleBannerStatus(BannerModel banner) async {
    emit(state.copyWith(actionStatus: InstructorBannersStatus.updating));
    try {
      await _repository.toggleBannerStatus(banner.id);
      // Re-fetch since it's cleaner and updates local state correctly
      await loadBanners(
        type: state.currentType,
        isActive: state.isActiveFilter,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: InstructorBannersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: InstructorBannersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete banner
  Future<bool> deleteBanner(String id) async {
    emit(state.copyWith(actionStatus: InstructorBannersStatus.deleting));
    try {
      await _repository.deleteBanner(id);
      // Remove from local state
      final updatedBanners = state.banners.where((b) => b.id != id).toList();
      emit(state.copyWith(
        actionStatus: InstructorBannersStatus.success,
        banners: updatedBanners,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: InstructorBannersStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
