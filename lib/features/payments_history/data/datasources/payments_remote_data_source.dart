import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';

abstract class PaymentsRemoteDataSource {
  Future<List<PaymentModel>> getUserPayments(String userId);
  Future<PaymentModel?> getPaymentById(String paymentId);
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  final SupabaseClient supabase;

  PaymentsRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<PaymentModel>> getUserPayments(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const FormatException('Invalid user id');
    }

    try {
      // Get parent enrollments with courses
      final response = await supabase
          .from('parent_enrollments')
          .select('''
            *,
            enrollments!parent_enrollment_id(
              course_id,
              courses!inner(
                id,
                title_ar,
                title_en,
                thumbnail_url,
                price
              )
            )
          ''')
          .eq('user_id', normalizedUserId)
          .order('created_at', ascending: false);

      final List<PaymentModel> payments = [];

      for (final item in response as List<dynamic>) {
        final enrollments = item['enrollments'] as List<dynamic>?;
        final courses = <PaymentCourseModel>[];

        if (enrollments != null) {
          for (final enrollment in enrollments) {
            final course = enrollment['courses'];
            if (course != null) {
              courses.add(PaymentCourseModel(
                courseId: course['id'] as String,
                title: course['title_ar'] as String? ??
                    course['title_en'] as String? ??
                    '',
                thumbnailUrl: course['thumbnail_url'] as String?,
                price: (course['price'] as num).toDouble(),
              ));
            }
          }
        }

        payments.add(PaymentModel.fromJson({
          ...item as Map<String, dynamic>,
          'courses': courses
              .map((c) => {
                    'course_id': c.courseId,
                    'title': c.title,
                    'thumbnail_url': c.thumbnailUrl,
                    'price': c.price,
                  })
              .toList(),
        }));
      }

      return payments;
    } catch (e) {
      throw Exception('Unable to load payments.');
    }
  }

  @override
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final normalizedPaymentId = paymentId.trim();
    if (normalizedPaymentId.isEmpty) {
      throw const FormatException('Invalid payment id');
    }

    try {
      final response = await supabase.from('parent_enrollments').select('''
            *,
            enrollments!parent_enrollment_id(
              course_id,
              courses!inner(
                id,
                title_ar,
                title_en,
                thumbnail_url,
                price
              )
            )
          ''').eq('id', normalizedPaymentId).maybeSingle();

      if (response == null) return null;

      final enrollments = response['enrollments'] as List<dynamic>?;
      final courses = <PaymentCourseModel>[];

      if (enrollments != null) {
        for (final enrollment in enrollments) {
          final course = enrollment['courses'];
          if (course != null) {
            courses.add(PaymentCourseModel(
              courseId: course['id'] as String,
              title: course['title_ar'] as String? ??
                  course['title_en'] as String? ??
                  '',
              thumbnailUrl: course['thumbnail_url'] as String?,
              price: (course['price'] as num).toDouble(),
            ));
          }
        }
      }

      return PaymentModel.fromJson({
        ...response,
        'courses': courses
            .map((c) => {
                  'course_id': c.courseId,
                  'title': c.title,
                  'thumbnail_url': c.thumbnailUrl,
                  'price': c.price,
                })
            .toList(),
      });
    } catch (e) {
      throw Exception('Unable to load payment details.');
    }
  }
}
