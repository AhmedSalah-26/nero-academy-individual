import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/admin_payouts_data_source.dart';
import '../../data/models/admin_payout_model.dart';

part 'admin_payouts_state.dart';

/// Admin Payouts Cubit - Manages payout operations for admin dashboard
class AdminPayoutsCubit extends Cubit<AdminPayoutsState> {
  final AdminPayoutsDataSource _dataSource;

  AdminPayoutsCubit(this._dataSource) : super(const AdminPayoutsState());

  String get _currentAdminId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  /// Load payouts with optional filters
  Future<void> loadPayouts({
    PayoutStatusType? status,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminPayoutsStatus.loading,
        payouts: [],
        currentPage: 1,
        hasMore: true,
        clearStatus: status == null,
      ));
    } else {
      emit(state.copyWith(status: AdminPayoutsStatus.loading));
    }

    try {
      final payouts = await _dataSource.getAllPayouts(
        status: status,
        search: search,
        fromDate: fromDate,
        toDate: toDate,
        page: 1,
      );

      final stats = await _dataSource.getPayoutStats();

      emit(state.copyWith(
        status: AdminPayoutsStatus.success,
        payouts: payouts,
        stats: stats,
        currentStatus: status,
        searchQuery: search,
        fromDate: fromDate,
        toDate: toDate,
        currentPage: 1,
        hasMore: payouts.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminPayoutsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more payouts (pagination)
  Future<void> loadMorePayouts() async {
    if (!state.hasMore || state.status == AdminPayoutsStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: AdminPayoutsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final payouts = await _dataSource.getAllPayouts(
        status: state.currentStatus,
        search: state.searchQuery,
        fromDate: state.fromDate,
        toDate: state.toDate,
        page: nextPage,
      );

      emit(state.copyWith(
        status: AdminPayoutsStatus.success,
        payouts: [...state.payouts, ...payouts],
        currentPage: nextPage,
        hasMore: payouts.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminPayoutsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Get payout by ID
  Future<AdminPayoutModel?> getPayoutById(String id) async {
    try {
      final payout = await _dataSource.getPayoutById(id);
      emit(state.copyWith(selectedPayout: payout));
      return payout;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return null;
    }
  }

  /// Review payout (pending → under_review)
  Future<bool> reviewPayout(AdminPayoutModel payout) async {
    if (!payout.canTransitionTo(PayoutStatusType.underReview)) {
      emit(state.copyWith(
        actionStatus: AdminPayoutsStatus.error,
        errorMessage: 'لا يمكن مراجعة هذا الطلب',
      ));
      return false;
    }

    emit(state.copyWith(actionStatus: AdminPayoutsStatus.processing));
    try {
      final updatedPayout =
          await _dataSource.reviewPayout(payout.id, _currentAdminId);
      await _updatePayoutInList(updatedPayout);
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminPayoutsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Complete payout (under_review → completed)
  Future<bool> completePayout(AdminPayoutModel payout, {String? notes}) async {
    if (!payout.canTransitionTo(PayoutStatusType.completed)) {
      emit(state.copyWith(
        actionStatus: AdminPayoutsStatus.error,
        errorMessage: 'لا يمكن إتمام هذا الطلب',
      ));
      return false;
    }

    emit(state.copyWith(actionStatus: AdminPayoutsStatus.processing));
    try {
      final updatedPayout = await _dataSource.completePayout(
        payout.id,
        _currentAdminId,
        notes: notes,
      );
      await _updatePayoutInList(updatedPayout);
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminPayoutsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Reject payout (pending/under_review → rejected)
  Future<bool> rejectPayout(
    AdminPayoutModel payout, {
    required String reason,
  }) async {
    if (!payout.canTransitionTo(PayoutStatusType.rejected)) {
      emit(state.copyWith(
        actionStatus: AdminPayoutsStatus.error,
        errorMessage: 'لا يمكن رفض هذا الطلب',
      ));
      return false;
    }

    emit(state.copyWith(actionStatus: AdminPayoutsStatus.processing));
    try {
      final updatedPayout = await _dataSource.rejectPayout(
        payout.id,
        _currentAdminId,
        reason: reason,
      );
      await _updatePayoutInList(updatedPayout);
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminPayoutsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Helper to update payout in list and refresh stats
  Future<void> _updatePayoutInList(AdminPayoutModel updatedPayout) async {
    final updatedPayouts = state.payouts.map((p) {
      return p.id == updatedPayout.id ? updatedPayout : p;
    }).toList();

    final stats = await _dataSource.getPayoutStats();

    emit(state.copyWith(
      actionStatus: AdminPayoutsStatus.success,
      payouts: updatedPayouts,
      stats: stats,
      selectedPayout: updatedPayout,
    ));
  }

  /// Change status filter
  void changeStatusFilter(PayoutStatusType? status) {
    if (status != state.currentStatus) {
      loadPayouts(
        status: status,
        search: state.searchQuery,
        fromDate: state.fromDate,
        toDate: state.toDate,
        refresh: true,
      );
    }
  }

  /// Search payouts
  void search(String query) {
    loadPayouts(
      status: state.currentStatus,
      search: query.isEmpty ? null : query,
      fromDate: state.fromDate,
      toDate: state.toDate,
      refresh: true,
    );
  }

  /// Set date range filter
  void setDateRange(DateTime? from, DateTime? to) {
    loadPayouts(
      status: state.currentStatus,
      search: state.searchQuery,
      fromDate: from,
      toDate: to,
      refresh: true,
    );
  }

  /// Refresh stats only
  Future<void> refreshStats() async {
    try {
      final stats = await _dataSource.getPayoutStats();
      emit(state.copyWith(stats: stats));
    } catch (e) {
      // Silently fail
    }
  }

  /// Get pending count (for badge)
  Future<int> getPendingCount() async {
    try {
      return await _dataSource.getPendingPayoutsCount();
    } catch (e) {
      return state.pendingCount;
    }
  }

  /// Clear selected payout
  void clearSelectedPayout() {
    emit(state.copyWith(clearSelectedPayout: true));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
