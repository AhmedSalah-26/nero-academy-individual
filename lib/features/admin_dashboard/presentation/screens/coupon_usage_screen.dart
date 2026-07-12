import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_coupon_model.dart';
import '../cubit/admin_coupons_cubit.dart';

/// Coupon Usage Screen - Shows usage statistics
class CouponUsageScreen extends StatefulWidget {
  final AdminCouponModel coupon;

  const CouponUsageScreen({
    super.key,
    required this.coupon,
  });

  @override
  State<CouponUsageScreen> createState() => _CouponUsageScreenState();
}

class _CouponUsageScreenState extends State<CouponUsageScreen> {
  List<CouponUsageModel>? _usages;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsages();
  }

  Future<void> _loadUsages() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usages = await context
          .read<AdminCouponsCubit>()
          .loadCouponUsages(widget.coupon.id);

      if (mounted) {
        setState(() {
          _usages = usages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'إحصائيات الاستخدام' : 'Usage Statistics',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.coupon.code,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsages,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildStats(isArabic, isDark),
              _buildUsagesList(isArabic, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(bool isArabic, bool isDark) {
    final usagePercent = widget.coupon.usageLimit != null
        ? (widget.coupon.usageCount / widget.coupon.usageLimit! * 100)
            .clamp(0, 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? widget.coupon.nameAr
                : (widget.coupon.nameEn ?? widget.coupon.nameAr),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_offer_rounded,
                  label: isArabic ? 'الخصم' : 'Discount',
                  value: widget.coupon.discountDisplay,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_rounded,
                  label: isArabic ? 'الاستخدام' : 'Usage',
                  value: widget.coupon.usageLimit != null
                      ? '${widget.coupon.usageCount}/${widget.coupon.usageLimit}'
                      : '${widget.coupon.usageCount}',
                  color: AppColors.success,
                  isDark: isDark,
                  progress: widget.coupon.usageLimit != null
                      ? usagePercent / 100
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money_rounded,
                  label: isArabic ? 'إجمالي الخصومات' : 'Total Discounts',
                  value: _usages != null
                      ? '\$${_usages!.fold<double>(0, (sum, u) => sum + u.discountAmount).toStringAsFixed(0)}'
                      : '...',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    double? progress,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (progress != null) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsagesList(bool isArabic, bool isDark) {
    if (_isLoading) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => const Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(height: 60),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'حدث خطأ في تحميل البيانات' : 'Error loading data',
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUsages,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_usages == null || _usages!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'لا يوجد استخدامات بعد' : 'No usages yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _usages!.length,
      itemBuilder: (context, index) {
        final usage = _usages![index];
        return _buildUsageItem(usage, isArabic, isDark);
      },
    );
  }

  Widget _buildUsageItem(CouponUsageModel usage, bool isArabic, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (usage.userName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usage.userName ?? usage.userEmail ?? 'Unknown User',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  if (usage.courseTitleAr != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      usage.courseTitleAr!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${usage.usedAt.day}/${usage.usedAt.month}/${usage.usedAt.year} ${usage.usedAt.hour}:${usage.usedAt.minute.toString().padLeft(2, '0')}',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-\$${usage.discountAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
