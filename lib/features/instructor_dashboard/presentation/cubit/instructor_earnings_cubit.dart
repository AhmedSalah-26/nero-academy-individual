import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_earning_model.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_payout_model.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_balance_model.dart';

part 'instructor_earnings_state.dart';

/// Instructor Earnings Cubit — NEW SCHEMA
class InstructorEarningsCubit extends Cubit<InstructorEarningsState> {
  final InstructorRepository _repository;
  static const _tag = 'InstructorEarningsCubit';

  InstructorEarningsCubit(this._repository) : super(InstructorEarningsState());

  // ─────────────────────────────────────────────────────
  // WALLET SUMMARY
  // ─────────────────────────────────────────────────────

  /// Load wallet summary from instructor_balance table
  Future<void> loadWalletSummary() async {
    try {
      final summary = await _repository.getWalletSummary();
      emit(state.copyWith(walletSummary: summary));
      AppLogger.success(
          '[$_tag] loadWalletSummary: available=${summary.availableBalance}, '
          'pending=${summary.pendingBalance}, '
          'totalEarnings=${summary.totalEarnings}, '
          'withdrawn=${summary.totalWithdrawn}');
    } catch (e, s) {
      AppLogger.e('[$_tag] loadWalletSummary: Error', e, s);
    }
  }

  // ─────────────────────────────────────────────────────
  // EARNINGS TRANSACTIONS
  // ─────────────────────────────────────────────────────

  /// Load earnings transactions
  Future<void> loadEarnings({
    String? courseId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    AppLogger.d(
        '[$_tag] loadEarnings: courseId=$courseId, status=$status, refresh=$refresh');

    if (refresh) {
      emit(state.copyWith(
          status: InstructorEarningsStatus.loading,
          earnings: [],
          currentPage: 1,
          hasMore: true));
    } else {
      emit(state.copyWith(status: InstructorEarningsStatus.loading));
    }

    try {
      final earnings = await _repository.getTransactions(
        courseId: courseId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        page: 1,
      );

      AppLogger.success(
          '[$_tag] loadEarnings: ${earnings.length} transactions');

      emit(state.copyWith(
        status: InstructorEarningsStatus.success,
        earnings: earnings,
        currentCourseId: courseId,
        currentPage: 1,
        hasMore: earnings.length >= 20,
      ));

      // Refresh wallet summary
      await loadWalletSummary();
    } catch (e, s) {
      AppLogger.e('[$_tag] loadEarnings: Error', e, s);
      emit(state.copyWith(
          status: InstructorEarningsStatus.error, errorMessage: e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────
  // WITHDRAW REQUESTS
  // ─────────────────────────────────────────────────────

  /// Load withdraw request history
  Future<void> loadWithdrawHistory({bool refresh = false}) async {
    AppLogger.d('[$_tag] loadWithdrawHistory: refresh=$refresh');

    if (refresh) {
      emit(state.copyWith(
          withdrawStatus: InstructorEarningsStatus.loading,
          withdrawRequests: []));
    } else {
      emit(state.copyWith(withdrawStatus: InstructorEarningsStatus.loading));
    }

    try {
      final requests = await _repository.getWithdrawHistory();
      AppLogger.success(
          '[$_tag] loadWithdrawHistory: ${requests.length} requests');
      emit(state.copyWith(
          withdrawStatus: InstructorEarningsStatus.success,
          withdrawRequests: requests));
      // Refresh wallet summary
      await loadWalletSummary();
    } catch (e, s) {
      AppLogger.e('[$_tag] loadWithdrawHistory: Error', e, s);
      emit(state.copyWith(
          withdrawStatus: InstructorEarningsStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Submit a withdraw request
  Future<void> submitWithdrawRequest({
    required double amount,
    required String method,
    required Map<String, String> accountDetails,
  }) async {
    AppLogger.d(
        '[$_tag] submitWithdrawRequest: amount=$amount, method=$method');
    emit(state.copyWith(actionStatus: InstructorEarningsStatus.loading));
    try {
      await _repository.submitWithdrawRequest(
        amount: amount,
        method: method,
        accountDetails: accountDetails,
      );
      AppLogger.success('[$_tag] submitWithdrawRequest: Success');
      // Refresh all data
      await loadEarnings(courseId: state.currentCourseId, refresh: true);
      await loadWithdrawHistory(refresh: true);
      emit(state.copyWith(actionStatus: InstructorEarningsStatus.success));
    } catch (e, s) {
      AppLogger.e('[$_tag] submitWithdrawRequest: Error', e, s);
      emit(state.copyWith(
          actionStatus: InstructorEarningsStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Filter by course
  void filterByCourse(String? courseId) {
    AppLogger.d('[$_tag] filterByCourse: courseId=$courseId');
    loadEarnings(courseId: courseId, refresh: true);
  }
}
