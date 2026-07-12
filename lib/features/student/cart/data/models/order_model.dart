import 'package:lms_platform/features/student/cart/domain/entities/order_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/payment_method_entity.dart';
import 'cart_item_model.dart';

/// Order Model - Data Model with JSON serialization
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    super.items,
    super.subtotal,
    super.discountAmount,
    super.total,
    super.currency,
    super.couponCode,
    super.paymentMethod,
    super.status,
    super.transactionId,
    required super.createdAt,
    super.completedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse order items
    List<CartItemModel> items = [];
    if (json['order_items'] != null) {
      items = (json['order_items'] as List)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0,
      discountAmount: (json['discount'] as num?)?.toDouble() ??
          (json['discount_amount'] as num?)?.toDouble() ??
          0,
      total: (json['total'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0,
      currency: json['currency'] as String? ?? 'EGP',
      couponCode: json['coupon_code'] as String?,
      paymentMethod:
          PaymentMethodType.fromString(json['payment_method'] as String?),
      status: OrderStatus.fromString(
          json['payment_status'] as String? ?? json['status'] as String?),
      transactionId: json['payment_transaction_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      completedAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subtotal': subtotal,
      'discount': discountAmount,
      'total': total,
      'coupon_code': couponCode,
      'payment_method': paymentMethod.name,
      'payment_status': status.name,
      'payment_transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'paid_at': completedAt?.toIso8601String(),
    };
  }
}
