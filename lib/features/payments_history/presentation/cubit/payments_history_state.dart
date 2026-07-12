part of 'payments_history_cubit.dart';

abstract class PaymentsHistoryState extends Equatable {
  const PaymentsHistoryState();

  @override
  List<Object?> get props => [];
}

class PaymentsHistoryInitial extends PaymentsHistoryState {}

class PaymentsHistoryLoading extends PaymentsHistoryState {}

class PaymentsHistoryLoaded extends PaymentsHistoryState {
  final List<PaymentEntity> payments;
  final String? selectedStatus;

  const PaymentsHistoryLoaded(
    this.payments, {
    this.selectedStatus,
  });

  List<PaymentEntity> get filteredPayments {
    if (selectedStatus == null || selectedStatus == 'all') {
      return payments;
    }
    if (selectedStatus == 'pending_manual_payment') {
      return payments.where((p) => p.isPending).toList();
    }
    return payments.where((p) => p.paymentStatus == selectedStatus).toList();
  }

  @override
  List<Object?> get props => [payments, selectedStatus];
}

enum PaymentsHistoryErrorType {
  unauthorized,
  server,
}

class PaymentsHistoryError extends PaymentsHistoryState {
  final String message;
  final PaymentsHistoryErrorType type;

  const PaymentsHistoryError(
    this.message, {
    this.type = PaymentsHistoryErrorType.server,
  });

  @override
  List<Object?> get props => [message, type];
}
