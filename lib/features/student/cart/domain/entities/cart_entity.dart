import 'package:equatable/equatable.dart';
import 'cart_item_entity.dart';
import 'coupon_entity.dart';

/// Cart Entity - Pure Dart Object
class CartEntity extends Equatable {
  final String id;
  final String userId;
  final List<CartItemEntity> items;
  final CouponEntity? appliedCoupon;
  final DateTime? updatedAt;

  const CartEntity({
    required this.id,
    required this.userId,
    this.items = const [],
    this.appliedCoupon,
    this.updatedAt,
  });

  /// Get items count
  int get itemsCount => items.length;

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Calculate subtotal (sum of all item prices)
  double get subtotal => items.fold(0, (sum, item) => sum + item.currentPrice);

  /// Calculate discount amount
  double get discountAmount {
    if (appliedCoupon == null) return 0;
    return appliedCoupon!.calculateDiscount(subtotal);
  }

  /// Calculate total (subtotal - discount)
  double get total {
    final result = subtotal - discountAmount;
    return result < 0 ? 0 : result;
  }

  /// Get currency (from first item or default)
  String get currency => items.isNotEmpty ? items.first.currency : 'EGP';

  /// Check if a course is in cart
  bool containsCourse(String courseId) =>
      items.any((item) => item.courseId == courseId);

  @override
  List<Object?> get props => [id, userId, items, appliedCoupon, updatedAt];
}
