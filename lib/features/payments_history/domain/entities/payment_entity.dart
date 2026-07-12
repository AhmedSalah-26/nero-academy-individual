import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String userId;
  final double total;
  final double subtotal;
  final double discount;
  final String? couponCode;
  final double couponDiscount;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final DateTime? paidAt;
  final DateTime createdAt;
  final List<PaymentCourseEntity> courses;

  const PaymentEntity({
    required this.id,
    required this.userId,
    required this.total,
    required this.subtotal,
    required this.discount,
    this.couponCode,
    required this.couponDiscount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    this.paidAt,
    required this.createdAt,
    this.courses = const [],
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isPending =>
      paymentStatus == 'pending' || paymentStatus == 'pending_manual_payment';
  bool get isFailed => paymentStatus == 'failed';
  bool get isRefunded => paymentStatus == 'refunded';
  bool get isCancelled => paymentStatus == 'cancelled';
  bool get isFree =>
      total <= 0 || paymentMethod == 'free' || courses.every((c) => c.isFree);

  String get statusAr {
    switch (paymentStatus) {
      case 'paid':
        return 'مدفوع';
      case 'pending':
      case 'pending_manual_payment':
        return 'قيد المراجعة';
      case 'failed':
      case 'cancelled':
        return 'ملغي';
      case 'refunded':
        return 'مسترد';
      default:
        return paymentStatus;
    }
  }

  String get statusEn {
    switch (paymentStatus) {
      case 'paid':
        return 'Paid';
      case 'pending':
      case 'pending_manual_payment':
        return 'Pending';
      case 'failed':
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus;
    }
  }

  String get methodAr {
    if (isFree) return 'مجاني';

    switch (paymentMethod) {
      case 'card':
        return 'بطاقة ائتمان';
      case 'wallet':
        return 'محفظة إلكترونية';
      case 'manual':
        return 'دفع يدوي';
      case 'free':
        return 'مجاني';
      case 'cash':
        return 'نقدي';
      default:
        return paymentMethod;
    }
  }

  String get methodEn {
    if (isFree) return 'Free';

    switch (paymentMethod) {
      case 'card':
        return 'Credit Card';
      case 'wallet':
        return 'Mobile Wallet';
      case 'manual':
        return 'Manual Payment';
      case 'free':
        return 'Free';
      case 'cash':
        return 'Cash';
      default:
        return paymentMethod;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        total,
        subtotal,
        discount,
        couponCode,
        couponDiscount,
        paymentMethod,
        paymentStatus,
        transactionId,
        paidAt,
        createdAt,
        courses,
      ];
}

class PaymentCourseEntity extends Equatable {
  final String courseId;
  final String title;
  final String? thumbnailUrl;
  final double price;

  const PaymentCourseEntity({
    required this.courseId,
    required this.title,
    this.thumbnailUrl,
    required this.price,
  });

  bool get isFree => price <= 0;

  @override
  List<Object?> get props => [courseId, title, thumbnailUrl, price];
}
