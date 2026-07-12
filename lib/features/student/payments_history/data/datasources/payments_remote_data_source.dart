import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/features/student/payments_history/data/models/payment_model.dart';

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
            ),
            manual_purchase_request_items(
              course_id,
              price,
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
        final courses = _extractCourses(item as Map<String, dynamic>);

        payments.add(PaymentModel.fromJson({
          ...item,
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
            ),
            manual_purchase_request_items(
              course_id,
              price,
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

      final courses = _extractCourses(response);

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

  List<PaymentCourseModel> _extractCourses(Map<String, dynamic> paymentJson) {
    final courseById = <String, PaymentCourseModel>{};

    void addCourseFrom(dynamic row, {bool preferRowPrice = false}) {
      if (row is! Map<String, dynamic>) return;

      final course = row['courses'];
      if (course is! Map<String, dynamic>) return;

      final courseId = (course['id'] ?? row['course_id']) as String?;
      if (courseId == null || courseId.isEmpty) return;

      final rowPrice = (row['price'] as num?)?.toDouble();
      final coursePrice = (course['price'] as num?)?.toDouble() ?? 0.0;

      courseById[courseId] = PaymentCourseModel(
        courseId: courseId,
        title: course['title_ar'] as String? ??
            course['title_en'] as String? ??
            '',
        thumbnailUrl: course['thumbnail_url'] as String?,
        price: preferRowPrice ? (rowPrice ?? coursePrice) : coursePrice,
      );
    }

    for (final enrollment
        in paymentJson['enrollments'] as List<dynamic>? ?? const []) {
      addCourseFrom(enrollment);
    }

    for (final item
        in paymentJson['manual_purchase_request_items'] as List<dynamic>? ??
            const []) {
      addCourseFrom(item, preferRowPrice: true);
    }

    return courseById.values.toList();
  }
}
