/// Payment result entity
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? responseCode;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.responseCode,
  });

  factory PaymentResult.success({
    required String transactionId,
    String? message,
    String? responseCode,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      message: message,
      responseCode: responseCode,
    );
  }

  factory PaymentResult.failure({String? message, String? responseCode}) {
    return PaymentResult(
      success: false,
      message: message,
      responseCode: responseCode,
    );
  }

  factory PaymentResult.cancelled() {
    return const PaymentResult(
      success: false,
      message: 'Payment cancelled by user',
    );
  }
}
