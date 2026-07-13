import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_earning_model.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_balance_model.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_payout_model.dart';

/// Instructor Earnings Data Source — reads from instructor_earnings
/// Tables used: instructor_earnings, withdraw_requests (history only)
class InstructorEarningsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorEarningsDS';

  InstructorEarningsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ─────────────────────────────────────────────────────
  // WALLET SUMMARY
  // ─────────────────────────────────────────────────────

  /// Get wallet summary — computed live from instructor_earnings
  Future<WalletSummaryModel> getWalletSummary() async {
    AppLogger.d('[$_tag] getWalletSummary: userId=$_userId');
    try {
      final response = await _client
          .from('instructor_earnings')
          .select('net_amount, status')
          .eq('teacher_id', _userId);

      final rows = response as List;
      double totalEarnings = 0;
      double available = 0;

      for (final row in rows) {
        final amount = (row['net_amount'] as num?)?.toDouble() ?? 0;
        totalEarnings += amount;
        if (row['status'] == 'available' || row['status'] == 'paid') {
          available += amount;
        }
      }

      AppLogger.success(
          '[$_tag] getWalletSummary: totalEarnings=$totalEarnings, available=$available');

      return WalletSummaryModel(
        teacherId: _userId,
        availableBalance: available,
        pendingBalance: 0,
        totalEarnings: totalEarnings,
        totalWithdrawn: 0,
        updatedAt: DateTime.now(),
      );
    } catch (e, s) {
      AppLogger.e('[$_tag] getWalletSummary error', e, s);
      return WalletSummaryModel.empty;
    }
  }

  // ─────────────────────────────────────────────────────
  // EARNINGS TRANSACTIONS
  // ─────────────────────────────────────────────────────

  /// Get earnings from instructor_earnings (real data source)
  Future<List<EarningsTransactionModel>> getTransactions({
    String? courseId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d(
        '[$_tag] getTransactions: courseId=$courseId, status=$status, page=$page');
    try {
      var query = _client
          .from('instructor_earnings')
          .select(
              'id, teacher_id, course_id, net_amount, gross_amount, coupon_discount, platform_fee, status, created_at, courses(title_ar, title_en)')
          .eq('teacher_id', _userId);

      if (courseId != null) query = query.eq('course_id', courseId);
      if (status != null) query = query.eq('status', status);
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final transactions = (response as List).map((e) {
        final courseData = e['courses'] as Map<String, dynamic>?;
        final courseName = courseData?['title_ar'] as String? ??
            courseData?['title_en'] as String? ??
            '';
        return EarningsTransactionModel(
          id: e['id'] as String,
          userId: e['teacher_id'] as String,
          courseId: e['course_id'] as String?,
          courseName: courseName,
          amount: (e['gross_amount'] as num?)?.toDouble() ?? 0,
          commission: (e['platform_fee'] as num?)?.toDouble() ?? 0,
          couponDiscount: (e['coupon_discount'] as num?)?.toDouble() ?? 0,
          status: EarningStatus.fromString(e['status'] as String?),
          sourceType: EarningSourceType.courseSale,
          createdAt: DateTime.parse(e['created_at'] as String),
        );
      }).toList();

      AppLogger.success(
          '[$_tag] getTransactions: ${transactions.length} transactions');
      return transactions;
    } catch (e, s) {
      AppLogger.e('[$_tag] getTransactions error', e, s);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────
  // WITHDRAW REQUESTS
  // ─────────────────────────────────────────────────────

  /// Get withdraw request history
  Future<List<WithdrawRequestModel>> getWithdrawHistory({
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getWithdrawHistory: page=$page');
    try {
      final response = await _client
          .from('withdraw_requests')
          .select()
          .eq('user_id', _userId)
          .order('requested_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getWithdrawHistory: ${(response as List).length} requests');
      return response.map((e) => WithdrawRequestModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getWithdrawHistory error', e, s);
      rethrow;
    }
  }

  /// Submit a withdraw request
  /// Calls RPC: submit_withdraw_request
  /// Flow:
  ///   IF available_balance >= amount
  ///     - Deduct from available_balance
  ///     - Add to pending_balance
  ///     - Create withdraw_request status=pending
  Future<Map<String, dynamic>> submitWithdrawRequest({
    required double amount,
    required String method,
    required Map<String, String> accountDetails,
  }) async {
    AppLogger.d(
        '[$_tag] submitWithdrawRequest: amount=$amount, method=$method');
    try {
      final response = await _client.rpc('submit_withdraw_request', params: {
        'p_user_id': _userId,
        'p_amount': amount,
        'p_method': method,
        'p_account_details': accountDetails,
      });

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        AppLogger.success(
            '[$_tag] submitWithdrawRequest success: ${result['request_id']}');
        return result;
      } else {
        final error = result['error'] ?? 'Unknown error';
        AppLogger.e('[$_tag] submitWithdrawRequest failed: $error');
        throw Exception(error);
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] submitWithdrawRequest error', e, s);
      rethrow;
    }
  }
}
