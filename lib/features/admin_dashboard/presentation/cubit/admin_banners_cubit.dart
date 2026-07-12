import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/admin_banners_data_source.dart';
import '../../data/models/admin_banner_model.dart';

part 'admin_banners_state.dart';

/// Admin Banners Cubit - Manages banner operations for admin dashboard
class AdminBannersCubit extends Cubit<AdminBannersState> {
  final AdminBannersDataSource _dataSource;

  AdminBannersCubit(this._dataSource) : super(const AdminBannersState());

  /// Load banners with optional filters
  Future<void> loadBanners({
    String? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminBannersStatus.loading,
        banners: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: AdminBannersStatus.loading));
    }

    try {
      final banners = await _dataSource.getAllBanners(
        status: status,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminBannersStatus.success,
        banners: banners,
        currentStatus: () => status,
        currentPage: 1,
        hasMore: banners.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminBannersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more banners (pagination)
  Future<void> loadMoreBanners() async {
    if (!state.hasMore || state.status == AdminBannersStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: AdminBannersStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final banners = await _dataSource.getAllBanners(
        status: state.currentStatus,
        page: nextPage,
      );
      emit(state.copyWith(
        status: AdminBannersStatus.success,
        banners: [...state.banners, ...banners],
        currentPage: nextPage,
        hasMore: banners.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminBannersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Create new banner
  Future<bool> createBanner(CreateBannerDto dto) async {
    emit(state.copyWith(actionStatus: AdminBannersStatus.creating));
    try {
      await _dataSource.createBanner(dto);
      // Refresh the list
      await loadBanners(
        status: state.currentStatus,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: AdminBannersStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminBannersStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Update existing banner
  Future<bool> updateBanner(String id, CreateBannerDto dto) async {
    emit(state.copyWith(actionStatus: AdminBannersStatus.updating));
    try {
      await _dataSource.updateBanner(id, dto);
      // Refresh the list
      await loadBanners(
        status: state.currentStatus,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: AdminBannersStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminBannersStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Toggle banner active status
  Future<void> toggleBannerStatus(AdminBannerModel banner) async {
    emit(state.copyWith(actionStatus: AdminBannersStatus.updating));
    try {
      await _dataSource.toggleBannerStatus(banner.id, banner.isActive);
      // Update local state
      final updatedBanners = state.banners.map((b) {
        if (b.id == banner.id) {
          return b.copyWith(isActive: !b.isActive);
        }
        return b;
      }).toList();
      emit(state.copyWith(
        actionStatus: AdminBannersStatus.success,
        banners: updatedBanners,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminBannersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete banner
  Future<bool> deleteBanner(String id) async {
    emit(state.copyWith(actionStatus: AdminBannersStatus.deleting));
    try {
      await _dataSource.deleteBanner(id);
      // Remove from local state
      final updatedBanners = state.banners.where((b) => b.id != id).toList();
      emit(state.copyWith(
        actionStatus: AdminBannersStatus.success,
        banners: updatedBanners,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminBannersStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Reorder banners
  Future<void> reorderBanners(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    // Adjust newIndex for ReorderableListView behavior
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    emit(state.copyWith(actionStatus: AdminBannersStatus.reordering));
    try {
      // Update local state first for immediate feedback
      final banners = List<AdminBannerModel>.from(state.banners);
      final banner = banners.removeAt(oldIndex);
      banners.insert(newIndex, banner);

      // Update sort orders
      final updatedBanners = banners.asMap().entries.map((entry) {
        return entry.value.copyWith(sortOrder: entry.key);
      }).toList();

      emit(state.copyWith(banners: updatedBanners));

      // Persist to backend
      final bannerIds = updatedBanners.map((b) => b.id).toList();
      await _dataSource.reorderBanners(bannerIds);

      emit(state.copyWith(actionStatus: AdminBannersStatus.success));
    } catch (e) {
      // Revert on error
      await loadBanners(
        status: state.currentStatus,
        refresh: true,
      );
      emit(state.copyWith(
        actionStatus: AdminBannersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Change status filter
  void changeStatusFilter(String? status) {
    if (status != state.currentStatus) {
      loadBanners(
        status: status,
        refresh: true,
      );
    }
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
