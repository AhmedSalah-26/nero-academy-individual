import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/admin_coupons_data_source.dart';
import '../../data/models/admin_coupon_model.dart';

part 'admin_coupons_state.dart';

/// Admin Coupons Cubit - Manages coupon operations for admin dashboard
class AdminCouponsCubit extends Cubit<AdminCouponsState> {
  final AdminCouponsDataSource _dataSource;

  AdminCouponsCubit(this._dataSource) : super(const AdminCouponsState());

  /// Load coupons with optional filters
  Future<void> loadCoupons({
    String? status,
    String? scope,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminCouponsStatus.loading,
        coupons: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: AdminCouponsStatus.loading));
    }

    try {
      final coupons = await _dataSource.getAllCoupons(
        status: status,
        scope: scope,
        search: search,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminCouponsStatus.success,
        coupons: coupons,
        currentStatus: status,
        currentScope: scope,
        searchQuery: search,
        currentPage: 1,
        hasMore: coupons.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminCouponsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more coupons (pagination)
  Future<void> loadMoreCoupons() async {
    if (!state.hasMore || state.status == AdminCouponsStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: AdminCouponsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final coupons = await _dataSource.getAllCoupons(
        status: state.currentStatus,
        scope: state.currentScope,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        status: AdminCouponsStatus.success,
        coupons: [...state.coupons, ...coupons],
        currentPage: nextPage,
        hasMore: coupons.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminCouponsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Create new coupon
  Future<bool> createCoupon(CreateCouponDto dto) async {
    emit(state.copyWith(actionStatus: AdminCouponsStatus.creating));
    try {
      // Check if code already exists
      final exists = await _dataSource.checkCouponCodeExists(dto.code);
      if (exists) {
        emit(state.copyWith(
          actionStatus: AdminCouponsStatus.error,
          errorMessage: 'Coupon code already exists',
        ));
        return false;
      }

      await _dataSource.createCoupon(dto);
      // Refresh the list
      await loadCoupons(
        status: state.currentStatus,
        scope: state.currentScope,
        search: state.searchQuery,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: AdminCouponsStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Update existing coupon
  Future<bool> updateCoupon(String id, CreateCouponDto dto) async {
    emit(state.copyWith(actionStatus: AdminCouponsStatus.updating));
    try {
      // Check if code already exists (excluding current coupon)
      final exists =
          await _dataSource.checkCouponCodeExists(dto.code, excludeId: id);
      if (exists) {
        emit(state.copyWith(
          actionStatus: AdminCouponsStatus.error,
          errorMessage: 'Coupon code already exists',
        ));
        return false;
      }

      await _dataSource.updateCoupon(id, dto);
      // Refresh the list
      await loadCoupons(
        status: state.currentStatus,
        scope: state.currentScope,
        search: state.searchQuery,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: AdminCouponsStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Toggle coupon active status
  Future<void> toggleCouponStatus(AdminCouponModel coupon) async {
    emit(state.copyWith(actionStatus: AdminCouponsStatus.updating));
    try {
      await _dataSource.toggleCouponStatus(coupon.id, coupon.isActive);
      // Update local state
      final updatedCoupons = state.coupons.map((c) {
        if (c.id == coupon.id) {
          return c.copyWith(isActive: !c.isActive);
        }
        return c;
      }).toList();
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.success,
        coupons: updatedCoupons,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Toggle coupon suspension
  Future<void> toggleCouponSuspension(AdminCouponModel coupon) async {
    emit(state.copyWith(actionStatus: AdminCouponsStatus.updating));
    try {
      await _dataSource.toggleCouponSuspension(coupon.id, coupon.isSuspended);
      // Update local state
      final updatedCoupons = state.coupons.map((c) {
        if (c.id == coupon.id) {
          return c.copyWith(isSuspended: !c.isSuspended);
        }
        return c;
      }).toList();
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.success,
        coupons: updatedCoupons,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete coupon
  Future<bool> deleteCoupon(String id) async {
    emit(state.copyWith(actionStatus: AdminCouponsStatus.deleting));
    try {
      await _dataSource.deleteCoupon(id);
      // Remove from local state
      final updatedCoupons = state.coupons.where((c) => c.id != id).toList();
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.success,
        coupons: updatedCoupons,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCouponsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Load coupon usages
  Future<List<CouponUsageModel>> loadCouponUsages(String couponId) async {
    try {
      return await _dataSource.getCouponUsages(couponId);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
      return [];
    }
  }

  /// Change status filter
  void changeStatusFilter(String? status) {
    if (status != state.currentStatus) {
      loadCoupons(
        status: status,
        scope: state.currentScope,
        search: state.searchQuery,
        refresh: true,
      );
    }
  }

  /// Change scope filter
  void changeScopeFilter(String? scope) {
    if (scope != state.currentScope) {
      loadCoupons(
        status: state.currentStatus,
        scope: scope,
        search: state.searchQuery,
        refresh: true,
      );
    }
  }

  /// Search coupons
  void search(String query) {
    loadCoupons(
      status: state.currentStatus,
      scope: state.currentScope,
      search: query.isEmpty ? null : query,
      refresh: true,
    );
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
