import 'package:equatable/equatable.dart';
import 'cart_item_entity.dart';
import 'payment_method_entity.dart';

/// Order Status Enum
enum OrderStatus {
  pending,
  processing,
  completed,
  failed,
  refunded;

  static OrderStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      case 'failed':
        return OrderStatus.failed;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Order Entity - Pure Dart Object
class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final List<CartItemEntity> items;
  final double subtotal;
  final double discountAmount;
  final double total;
  final String currency;
  final String? couponCode;
  final PaymentMethodType paymentMethod;
  final OrderStatus status;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    this.items = const [],
    this.subtotal = 0,
    this.discountAmount = 0,
    this.total = 0,
    this.currency = 'EGP',
    this.couponCode,
    this.paymentMethod = PaymentMethodType.card,
    this.status = OrderStatus.pending,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
  });

  /// Check if order is successful
  bool get isSuccessful => status == OrderStatus.completed;

  /// Get items count
  int get itemsCount => items.length;

  /// Copy with method
  OrderEntity copyWith({
    String? id,
    String? userId,
    List<CartItemEntity>? items,
    double? subtotal,
    double? discountAmount,
    double? total,
    String? currency,
    String? couponCode,
    PaymentMethodType? paymentMethod,
    OrderStatus? status,
    String? transactionId,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      couponCode: couponCode ?? this.couponCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        total,
        status,
        transactionId,
        createdAt,
      ];
}
