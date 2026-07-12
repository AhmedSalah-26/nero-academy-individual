import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PaymentConfirmationStatus {
  paid,
  failed,
  pending,
}

/// Service to handle enrollment payment status reads.
class EnrollmentPaymentService {
  final SupabaseClient supabase;

  EnrollmentPaymentService({required this.supabase});

  /// Paymob confirmation is handled by the Edge Function webhook using the
  /// service role. The mobile client must not call the confirmation RPC.
  Future<PaymentConfirmationStatus> confirmPayment({
    required String parentEnrollmentId,
    required String transactionId,
    Duration timeout = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    debugPrint(
      '[EnrollmentPayment] Payment success reported for '
      '$parentEnrollmentId; server webhook will confirm '
      'transaction $transactionId',
    );

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final status = await getPaymentStatus(parentEnrollmentId);

      if (status == 'paid') {
        return PaymentConfirmationStatus.paid;
      }

      if (status == 'failed' || status == 'refunded') {
        return PaymentConfirmationStatus.failed;
      }

      await Future<void>.delayed(pollInterval);
    }

    return PaymentConfirmationStatus.pending;
  }

  /// Get parent enrollment details.
  Future<Map<String, dynamic>?> getParentEnrollment(
    String parentEnrollmentId,
  ) async {
    try {
      final response = await supabase
          .from('parent_enrollments')
          .select('*')
          .eq('id', parentEnrollmentId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get parent enrollment: $e');
    }
  }

  Future<String?> getPaymentStatus(String parentEnrollmentId) async {
    try {
      final response = await supabase
          .from('parent_enrollments')
          .select('payment_status')
          .eq('id', parentEnrollmentId)
          .maybeSingle();

      return response?['payment_status'] as String?;
    } catch (e) {
      throw Exception('Failed to get payment status: $e');
    }
  }

  /// Payment failure status is also owned by the backend/webhook path.
  Future<void> markPaymentFailed({
    required String parentEnrollmentId,
    String? errorMessage,
  }) async {
    debugPrint(
      '[EnrollmentPayment] Payment failure reported for '
      '$parentEnrollmentId; backend remains the source of truth. '
      'Error: ${errorMessage ?? 'none'}',
    );
  }
}
