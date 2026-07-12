import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/admin_payout_model.dart';

/// Admin Payouts Data Source — NEW SCHEMA (withdraw_requests table)
class AdminPayoutsDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminPayoutsDS';

  AdminPayoutsDataSource(this._client);

  /// Get all payouts (from withdraw_requests) with filtering
  Future<List<AdminPayoutModel>> getAllPayouts({
    PayoutStatusType? status,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAllPayouts: status=$status, search=$search');
    try {
      var query = _client.from('withdraw_requests').select(
            '*, instructor:profiles!withdraw_requests_user_id_profiles_fkey(name, email, avatar_url)',
          );

      if (status != null) {
        query = query.eq('status', status.toJsonValue());
      }

      if (fromDate != null) {
        query = query.gte('requested_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('requested_at', toDate.toIso8601String());
      }

      final response = await query
          .order('requested_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      var payouts = (response as List)
          .map((e) => AdminPayoutModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        payouts = payouts.where((p) {
          return (p.instructorName?.toLowerCase().contains(searchLower) ??
                  false) ||
              (p.instructorEmail?.toLowerCase().contains(searchLower) ??
                  false) ||
              p.id.toLowerCase().contains(searchLower);
        }).toList();
      }

      AppLogger.success('[$_tag] getAllPayouts: ${payouts.length} payouts');
      return payouts;
    } catch (e, s) {
      AppLogger.e('[$_tag] getAllPayouts error', e, s);
      rethrow;
    }
  }

  /// Get payout by ID
  Future<AdminPayoutModel> getPayoutById(String id) async {
    AppLogger.d('[$_tag] getPayoutById: $id');
    try {
      final response = await _client
          .from('withdraw_requests')
          .select(
              '*, instructor:profiles!withdraw_requests_user_id_profiles_fkey(name, email, avatar_url)')
          .eq('id', id)
          .single();
      AppLogger.success('[$_tag] getPayoutById success');
      return AdminPayoutModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] getPayoutById error', e, s);
      rethrow;
    }
  }

  /// Approve withdraw request (pending → approved)
  Future<AdminPayoutModel> approvePayout(String id, String adminId) async {
    AppLogger.d('[$_tag] approvePayout: id=$id');
    try {
      final result = await _client.rpc('admin_approve_withdraw', params: {
        'p_request_id': id,
        'p_admin_id': adminId,
      });

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to approve withdrawal');
      }

      return getPayoutById(id);
    } catch (e, s) {
      AppLogger.e('[$_tag] approvePayout error', e, s);
      rethrow;
    }
  }

  /// Review payout (kept for backward compat — same as approve)
  Future<AdminPayoutModel> reviewPayout(String id, String adminId) async {
    return approvePayout(id, adminId);
  }

  /// Complete payout (approve + mark paid in new schema)
  Future<AdminPayoutModel> completePayout(
    String id,
    String adminId, {
    String? notes,
  }) async {
    AppLogger.d('[$_tag] completePayout: id=$id');
    try {
      // In the new schema, approve = complete
      final result = await _client.rpc('admin_approve_withdraw', params: {
        'p_request_id': id,
        'p_admin_id': adminId,
      });

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to complete withdrawal');
      }

      // Optionally add notes
      if (notes != null && notes.isNotEmpty) {
        await _client
            .from('withdraw_requests')
            .update({'notes': notes}).eq('id', id);
      }

      return getPayoutById(id);
    } catch (e, s) {
      AppLogger.e('[$_tag] completePayout error', e, s);
      rethrow;
    }
  }

  /// Reject payout (pending → rejected)
  Future<AdminPayoutModel> rejectPayout(
    String id,
    String adminId, {
    String? reason,
  }) async {
    AppLogger.d('[$_tag] rejectPayout: id=$id');
    try {
      final result = await _client.rpc('admin_reject_withdraw', params: {
        'p_request_id': id,
        'p_admin_id': adminId,
        'p_notes': reason,
      });

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to reject withdrawal');
      }

      return getPayoutById(id);
    } catch (e, s) {
      AppLogger.e('[$_tag] rejectPayout error', e, s);
      rethrow;
    }
  }

  /// Get payout statistics
  Future<PayoutStatsModel> getPayoutStats() async {
    AppLogger.d('[$_tag] getPayoutStats');
    try {
      final response =
          await _client.from('withdraw_requests').select('status, amount');

      final rows = response as List;

      int pending = 0, approved = 0, paid = 0, rejected = 0;
      double pendingAmt = 0, approvedAmt = 0, paidAmt = 0;

      for (final row in rows) {
        final status = row['status'] as String? ?? '';
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        switch (status) {
          case 'pending':
            pending++;
            pendingAmt += amount;
            break;
          case 'approved':
            approved++;
            approvedAmt += amount;
            break;
          case 'paid':
            paid++;
            paidAmt += amount;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return PayoutStatsModel(
        totalPayouts: rows.length,
        pendingPayouts: pending,
        underReviewPayouts: approved,
        completedPayouts: paid,
        rejectedPayouts: rejected,
        totalPendingAmount: pendingAmt,
        totalUnderReviewAmount: approvedAmt,
        totalCompletedAmount: paidAmt,
      );
    } catch (e, s) {
      AppLogger.e('[$_tag] getPayoutStats error', e, s);
      rethrow;
    }
  }

  /// Get pending payouts count (for badge)
  Future<int> getPendingPayoutsCount() async {
    try {
      final response = await _client
          .from('withdraw_requests')
          .select('id')
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e, s) {
      AppLogger.e('[$_tag] getPendingPayoutsCount error', e, s);
      rethrow;
    }
  }
}
