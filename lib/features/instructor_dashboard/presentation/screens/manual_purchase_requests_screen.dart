import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/animations/animations.dart';
import '../../../../core/theme/app_colors.dart';

class ManualPurchaseRequestsScreen extends StatefulWidget {
  const ManualPurchaseRequestsScreen({super.key});

  @override
  State<ManualPurchaseRequestsScreen> createState() =>
      _ManualPurchaseRequestsScreenState();
}

class _ManualPurchaseRequestsScreenState
    extends State<ManualPurchaseRequestsScreen> {
  final _client = Supabase.instance.client;
  var _isLoading = true;
  var _actionOrderId = '';
  String? _error;
  List<_ManualPurchaseRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client
          .from('parent_enrollments')
          .select('''
            id, user_id, total, subtotal, discount, payment_status, created_at,
            profiles:user_id (name, email, phone),
            enrollments (
              id, course_id, status, price,
              courses:course_id (title_ar, title_en, thumbnail_url)
            )
          ''')
          .eq('payment_status', 'pending_manual_payment')
          .order('created_at', ascending: false);

      final requests = (response as List)
          .map((item) =>
              _ManualPurchaseRequest.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(String orderId, int days) async {
    await _runAction(
      orderId,
      () => _client.rpc(
        'approve_manual_purchase_request',
        params: {
          'p_parent_enrollment_id': orderId,
          'p_access_days': days,
        },
      ),
    );
  }

  Future<void> _cancel(String orderId) async {
    await _runAction(
      orderId,
      () => _client.rpc(
        'cancel_manual_purchase_request',
        params: {'p_parent_enrollment_id': orderId},
      ),
    );
  }

  Future<void> _runAction(
    String orderId,
    Future<dynamic> Function() action,
  ) async {
    setState(() => _actionOrderId = orderId);
    try {
      await action();
      if (!mounted) return;
      AnimatedSnackbar.showSuccess(
        context: context,
        message: context.locale.languageCode == 'ar'
            ? 'تم تحديث الطلب'
            : 'Request updated',
      );
      await _loadRequests();
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackbar.showError(context: context, message: e.toString());
    } finally {
      if (mounted) setState(() => _actionOrderId = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadRequests,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: _requests.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 120),
                Icon(
                  Icons.inbox_rounded,
                  size: 54,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic
                      ? 'لا توجد طلبات شراء معلقة'
                      : 'No pending purchase requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = _requests[index];
                return _RequestCard(
                  request: request,
                  isDark: isDark,
                  isBusy: _actionOrderId == request.id,
                  onApprove: (days) => _approve(request.id, days),
                  onCancel: () => _cancel(request.id),
                );
              },
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isDark,
    required this.isBusy,
    required this.onApprove,
    required this.onCancel,
  });

  final _ManualPurchaseRequest request;
  final bool isDark;
  final bool isBusy;
  final ValueChanged<int> onApprove;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.studentName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ),
              Text(
                '${request.total.toStringAsFixed(0)} EGP',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${isArabic ? 'رقم العملية' : 'Operation'}: ${request.shortId}',
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          if (request.phone.isNotEmpty || request.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [request.phone, request.email]
                  .where((e) => e.isNotEmpty)
                  .join(' • '),
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...request.courses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic ? course.titleAr : course.titleEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${course.price.toStringAsFixed(0)} EGP'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isBusy)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in const [30, 60, 90])
                  ElevatedButton(
                    onPressed: () => onApprove(days),
                    child: Text(
                      isArabic ? 'تسليم $days يوم' : 'Deliver $days days',
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(isArabic ? 'إلغاء الطلب' : 'Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ManualPurchaseRequest {
  final String id;
  final double total;
  final String studentName;
  final String email;
  final String phone;
  final List<_RequestCourse> courses;

  const _ManualPurchaseRequest({
    required this.id,
    required this.total,
    required this.studentName,
    required this.email,
    required this.phone,
    required this.courses,
  });

  String get shortId =>
      id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();

  factory _ManualPurchaseRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final enrollments = (json['enrollments'] as List<dynamic>? ?? [])
        .map((item) => _RequestCourse.fromJson(item as Map<String, dynamic>))
        .toList();

    return _ManualPurchaseRequest(
      id: json['id'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      studentName: profile?['name'] as String? ?? 'Student',
      email: profile?['email'] as String? ?? '',
      phone: profile?['phone'] as String? ?? '',
      courses: enrollments,
    );
  }
}

class _RequestCourse {
  final String titleAr;
  final String titleEn;
  final double price;

  const _RequestCourse({
    required this.titleAr,
    required this.titleEn,
    required this.price,
  });

  factory _RequestCourse.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>?;
    final titleAr = course?['title_ar'] as String? ?? '';
    final titleEn = course?['title_en'] as String? ?? titleAr;

    return _RequestCourse(
      titleAr: titleAr,
      titleEn: titleEn.isEmpty ? titleAr : titleEn,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
