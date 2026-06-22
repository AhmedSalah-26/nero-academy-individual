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
  static const _allStatus = 'all';
  static const _pendingStatus = 'pending_manual_payment';
  static const _paidStatus = 'paid';
  static const _cancelledStatus = 'cancelled';
  static const _manualStatuses = [
    _pendingStatus,
    _paidStatus,
    _cancelledStatus
  ];

  final _client = Supabase.instance.client;
  var _isLoading = true;
  var _actionOrderId = '';
  var _selectedStatus = _pendingStatus;
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
            id, user_id, total, subtotal, discount, payment_method,
            payment_status, created_at, paid_at, updated_at,
            profiles:user_id (name, email, phone),
            enrollments (
              id, course_id, status, price, access_expires_at,
              courses:course_id (title_ar, title_en, thumbnail_url)
            )
          ''')
          .eq('payment_method', 'manual')
          .inFilter('payment_status', _manualStatuses)
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

  List<_ManualPurchaseRequest> get _visibleRequests {
    if (_selectedStatus == _allStatus) return _requests;
    return _requests
        .where((request) => request.paymentStatus == _selectedStatus)
        .toList();
  }

  int _count(String status) {
    if (status == _allStatus) return _requests.length;
    return _requests.where((request) => request.paymentStatus == status).length;
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
    } catch (_) {
      if (!mounted) return;
      AnimatedSnackbar.showError(
        context: context,
        message: context.locale.languageCode == 'ar'
            ? 'تعذر تحديث الطلب. حاول مرة أخرى.'
            : 'Could not update the request. Please try again.',
      );
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
      return _RequestsErrorState(
        isDark: isDark,
        isArabic: isArabic,
        onRetry: _loadRequests,
      );
    }

    final visibleRequests = _visibleRequests;

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusFilters(
            selectedStatus: _selectedStatus,
            countFor: _count,
            isDark: isDark,
            onChanged: (status) => setState(() => _selectedStatus = status),
          ),
          const SizedBox(height: 14),
          if (visibleRequests.isEmpty)
            _RequestsEmptyState(
              status: _selectedStatus,
              isDark: isDark,
              isArabic: isArabic,
            )
          else
            ...visibleRequests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(
                  request: request,
                  isDark: isDark,
                  isBusy: _actionOrderId == request.id,
                  onApprove: (days) => _approve(request.id, days),
                  onCancel: () => _cancel(request.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.selectedStatus,
    required this.countFor,
    required this.isDark,
    required this.onChanged,
  });

  final String selectedStatus;
  final int Function(String status) countFor;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final filters = [
      _StatusFilterData(
        status: _ManualPurchaseRequestsScreenState._pendingStatus,
        label: isArabic ? 'قيد المراجعة' : 'Pending',
        color: AppColors.warning,
      ),
      _StatusFilterData(
        status: _ManualPurchaseRequestsScreenState._paidStatus,
        label: isArabic ? 'مقبول' : 'Approved',
        color: AppColors.success,
      ),
      _StatusFilterData(
        status: _ManualPurchaseRequestsScreenState._cancelledStatus,
        label: isArabic ? 'ملغي' : 'Cancelled',
        color: AppColors.error,
      ),
      _StatusFilterData(
        status: _ManualPurchaseRequestsScreenState._allStatus,
        label: isArabic ? 'الكل' : 'All',
        color: AppColors.primary,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            _StatusFilterChip(
              label: '${filter.label} (${countFor(filter.status)})',
              color: filter.color,
              isSelected: selectedStatus == filter.status,
              onTap: () => onChanged(filter.status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.white : color,
          ),
        ),
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
    final dateFormat =
        DateFormat('dd MMM yyyy - hh:mm a', isArabic ? 'ar' : 'en');

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(request.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RequestStatusBadge(status: request.paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.confirmation_number_rounded,
            text:
                '${isArabic ? 'رقم العملية' : 'Operation'}: ${request.shortId}',
            isDark: isDark,
          ),
          if (request.phone.isNotEmpty || request.email.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: [request.phone, request.email]
                  .where((value) => value.isNotEmpty)
                  .join(' • '),
              isDark: isDark,
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
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                  ),
                  Text(
                    '${course.price.toStringAsFixed(0)} EGP',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _StatusHint(request: request, isDark: isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                isArabic ? 'الإجمالي' : 'Total',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${request.total.toStringAsFixed(0)} EGP',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (request.canAct) ...[
            const SizedBox(height: 14),
            if (isBusy)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final days in const [30, 60, 90])
                    ElevatedButton.icon(
                      onPressed: () => onApprove(days),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isArabic ? 'قبول $days يوم' : 'Approve $days days',
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(isArabic ? 'إلغاء الطلب' : 'Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusHint extends StatelessWidget {
  const _StatusHint({
    required this.request,
    required this.isDark,
  });

  final _ManualPurchaseRequest request;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final text = switch (request.paymentStatus) {
      _ManualPurchaseRequestsScreenState._paidStatus => isArabic
          ? 'تم قبول الطلب وتفعيل الوصول للكورسات.'
          : 'Request approved and course access is active.',
      _ManualPurchaseRequestsScreenState._cancelledStatus => isArabic
          ? 'تم إلغاء الطلب ولن تظهر أزرار القبول لهذا الطلب.'
          : 'Request was cancelled, so approval actions are hidden.',
      _ => isArabic
          ? 'راجع إثبات الدفع، ثم اختر مدة التفعيل المناسبة.'
          : 'Review the payment proof, then choose the access duration.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.grey50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.4,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final color = _statusColor(status);
    final label = _statusLabel(status, isArabic);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RequestsEmptyState extends StatelessWidget {
  const _RequestsEmptyState({
    required this.status,
    required this.isDark,
    required this.isArabic,
  });

  final String status;
  final bool isDark;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 12),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 54,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            isArabic
                ? 'لا توجد ${_statusLabel(status, true)}'
                : 'No ${_statusLabel(status, false).toLowerCase()} requests',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsErrorState extends StatelessWidget {
  const _RequestsErrorState({
    required this.isDark,
    required this.isArabic,
    required this.onRetry,
  });

  final bool isDark;
  final bool isArabic;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
            Text(
              isArabic
                  ? 'تعذر تحميل طلبات الشراء'
                  : 'Could not load purchase requests',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterData {
  final String status;
  final String label;
  final Color color;

  const _StatusFilterData({
    required this.status,
    required this.label,
    required this.color,
  });
}

class _ManualPurchaseRequest {
  final String id;
  final double total;
  final String paymentStatus;
  final DateTime createdAt;
  final String studentName;
  final String email;
  final String phone;
  final List<_RequestCourse> courses;

  const _ManualPurchaseRequest({
    required this.id,
    required this.total,
    required this.paymentStatus,
    required this.createdAt,
    required this.studentName,
    required this.email,
    required this.phone,
    required this.courses,
  });

  bool get canAct =>
      paymentStatus == _ManualPurchaseRequestsScreenState._pendingStatus;

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
      paymentStatus: json['payment_status'] as String? ??
          _ManualPurchaseRequestsScreenState._pendingStatus,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
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

String _statusLabel(String status, bool isArabic) {
  switch (status) {
    case _ManualPurchaseRequestsScreenState._allStatus:
      return isArabic ? 'كل الطلبات' : 'All';
    case _ManualPurchaseRequestsScreenState._paidStatus:
      return isArabic ? 'طلبات مقبولة' : 'Approved';
    case _ManualPurchaseRequestsScreenState._cancelledStatus:
      return isArabic ? 'طلبات ملغية' : 'Cancelled';
    case _ManualPurchaseRequestsScreenState._pendingStatus:
    default:
      return isArabic ? 'طلبات قيد المراجعة' : 'Pending';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case _ManualPurchaseRequestsScreenState._paidStatus:
      return AppColors.success;
    case _ManualPurchaseRequestsScreenState._cancelledStatus:
      return AppColors.error;
    case _ManualPurchaseRequestsScreenState._pendingStatus:
    default:
      return AppColors.warning;
  }
}
