import 'package:lms_platform/features/student/payments_history/domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.userId,
    required super.total,
    required super.subtotal,
    required super.discount,
    super.couponCode,
    required super.couponDiscount,
    required super.paymentMethod,
    required super.paymentStatus,
    super.transactionId,
    super.paidAt,
    required super.createdAt,
    super.courses,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      total: (json['total'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['coupon_code'] as String?,
      couponDiscount: (json['coupon_discount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'card',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      transactionId: json['payment_transaction_id'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      courses: (json['courses'] as List<dynamic>?)
              ?.map(
                  (c) => PaymentCourseModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total': total,
      'subtotal': subtotal,
      'discount': discount,
      'coupon_code': couponCode,
      'coupon_discount': couponDiscount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_transaction_id': transactionId,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PaymentCourseModel extends PaymentCourseEntity {
  const PaymentCourseModel({
    required super.courseId,
    required super.title,
    super.thumbnailUrl,
    required super.price,
  });

  factory PaymentCourseModel.fromJson(Map<String, dynamic> json) {
    return PaymentCourseModel(
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      price: (json['price'] as num).toDouble(),
    );
  }
}
