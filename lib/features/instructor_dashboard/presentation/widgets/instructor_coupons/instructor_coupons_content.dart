import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/shared_widgets/responsive_dialog.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/routing/app_router.dart';
import '../../cubit/instructor_coupons_cubit.dart';

/// Instructor Coupons Content
class InstructorCouponsContent extends StatefulWidget {
  const InstructorCouponsContent({super.key});

  @override
  State<InstructorCouponsContent> createState() =>
      _InstructorCouponsContentState();
}

class _InstructorCouponsContentState extends State<InstructorCouponsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InstructorCouponsCubit>().loadCoupons(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InstructorCouponsCubit>().loadMoreCoupons();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<InstructorCouponsCubit, InstructorCouponsState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic, isDark),
            Expanded(child: _buildCouponsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, InstructorCouponsState state,
      bool isArabic, bool isDark) {
    final tabIndex = state.filter == CouponStatusFilter.all
        ? 0
        : state.filter == CouponStatusFilter.active
            ? 1
            : 2;

    final statusOptions = [
      {'value': 'all', 'label': 'All', 'labelAr': 'الكل'},
      {'value': 'active', 'label': 'Active', 'labelAr': 'نشط'},
      {'value': 'expired', 'label': 'Expired', 'labelAr': 'منتهي'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: DropdownButton<int>(
                value: tabIndex,
                underline: const SizedBox(),
                isExpanded: true,
                items: statusOptions.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(
                      isArabic
                          ? entry.value['labelAr'] as String
                          : entry.value['label'] as String,
                    ),
                  );
                }).toList(),
                onChanged: (index) {
                  if (index != null) {
                    final filter = index == 0
                        ? CouponStatusFilter.all
                        : index == 1
                            ? CouponStatusFilter.active
                            : CouponStatusFilter.expired;
                    context.read<InstructorCouponsCubit>().setFilter(filter);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          SolidActionButton(
            icon: Icons.add,
            label: isArabic ? 'كوبون جديد' : 'New Coupon',
            color: AppColors.primary,
            onPressed: () => _showCouponDialog(context, isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsList(
      BuildContext context, InstructorCouponsState state, bool isArabic) {
    if (state.isLoading && state.coupons.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: const LoadingSkeleton(width: double.infinity, height: 70),
        ),
      );
    }

    final coupons = state.filteredCoupons;

    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'لا توجد كوبونات' : 'No coupons found',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<InstructorCouponsCubit>().loadCoupons(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: coupons.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == coupons.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _CouponListItem(
            coupon: coupons[index],
            isArabic: isArabic,
            onEdit: () =>
                _showCouponDialog(context, isArabic, coupon: coupons[index]),
            onToggle: () async {
              final coupon = coupons[index];
              final success = await context
                  .read<InstructorCouponsCubit>()
                  .toggleCouponStatus(coupon.id, !coupon.isActive);
              if (mounted) {
                _showSnackBar(
                  success
                      ? (isArabic ? 'تم تحديث الحالة' : 'Status updated')
                      : (isArabic ? 'فشل التحديث' : 'Update failed'),
                  isError: !success,
                );
              }
            },
            onDelete: () => _confirmDelete(context, coupons[index], isArabic),
            onCopyCode: () {
              Clipboard.setData(ClipboardData(text: coupons[index].code));
              _showSnackBar(isArabic ? 'تم نسخ الكود' : 'Code copied');
            },
          );
        },
      ),
    );
  }

  void _showCouponDialog(BuildContext context, bool isArabic,
      {InstructorCouponModel? coupon}) {
    // Navigate to full screen instead of dialog
    AppRouter.goToCouponEditor(
      context,
      coupon: coupon,
      onSave: (data) async {
        final cubit = context.read<InstructorCouponsCubit>();
        bool success;
        if (coupon != null) {
          success = await cubit.updateCoupon(
            couponId: coupon.id,
            code: data['code'],
            nameAr: data['name_ar'],
            nameEn: data['name_en'],
            discountType: data['discount_type'],
            discountValue: data['discount_value'],
            usageLimit: data['usage_limit'],
            endDate: data['end_date'],
            scope: data['scope'],
            courseIds: (data['course_ids'] as List?)?.cast<String>(),
          );
        } else {
          success = await cubit.createCoupon(
            code: data['code'],
            nameAr: data['name_ar'],
            nameEn: data['name_en'],
            discountType: data['discount_type'],
            discountValue: data['discount_value'],
            usageLimit: data['usage_limit'],
            endDate: data['end_date'],
            scope: data['scope'],
            courseIds: (data['course_ids'] as List?)?.cast<String>(),
          );
        }
        if (mounted) {
          _showSnackBar(
            success
                ? (coupon != null
                    ? (isArabic ? 'تم تحديث الكوبون' : 'Coupon updated')
                    : (isArabic ? 'تم إنشاء الكوبون' : 'Coupon created'))
                : (isArabic ? 'حدث خطأ' : 'An error occurred'),
            isError: !success,
          );
        }
        return success;
      },
    );
  }

  void _confirmDelete(
      BuildContext context, InstructorCouponModel coupon, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveAlertDialog(
        title: isArabic ? 'حذف الكوبون' : 'Delete Coupon',
        content: isArabic
            ? 'هل أنت متأكد من حذف هذا الكوبون؟'
            : 'Are you sure you want to delete this coupon?',
        confirmText: isArabic ? 'حذف' : 'Delete',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          final success = await context
              .read<InstructorCouponsCubit>()
              .deleteCoupon(coupon.id);
          if (mounted) {
            _showSnackBar(
              success
                  ? (isArabic ? 'تم حذف الكوبون' : 'Coupon deleted')
                  : (isArabic ? 'فشل الحذف' : 'Delete failed'),
              isError: !success,
            );
          }
        },
      ),
    );
  }
}

/// Simple Coupon List Item - Similar to Student Details buttons style
class _CouponListItem extends StatelessWidget {
  final InstructorCouponModel coupon;
  final bool isArabic;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onCopyCode;

  const _CouponListItem({
    required this.coupon,
    required this.isArabic,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Code badge with copy - styled like action buttons
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopyCode,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      coupon.code,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? coupon.nameAr : (coupon.nameEn ?? coupon.nameAr),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Discount
                    Text(
                      coupon.discountType == 'percentage'
                          ? '${coupon.discountValue.toStringAsFixed(0)}%'
                          : '${coupon.discountValue.toStringAsFixed(0)} EGP',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Usage
                    Text(
                      coupon.usageLimit != null
                          ? '${coupon.usageCount}/${coupon.usageLimit}'
                          : '${coupon.usageCount}x',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    if (coupon.endDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM').format(coupon.endDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: coupon.isExpired
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          _buildStatusBadge(),
          const SizedBox(width: 8),

          // Action buttons - similar to student details style
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionBtn(
                icon: Icons.edit_outlined,
                color: AppColors.info,
                onTap: onEdit,
              ),
              const SizedBox(width: 4),
              _buildActionBtn(
                icon: coupon.isActive ? Icons.pause : Icons.play_arrow,
                color: coupon.isActive ? AppColors.warning : AppColors.success,
                onTap: onToggle,
              ),
              const SizedBox(width: 4),
              _buildActionBtn(
                icon: Icons.delete_outline,
                color: AppColors.error,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;

    if (!coupon.isActive) {
      color = Colors.grey;
      label = isArabic ? 'متوقف' : 'Off';
    } else if (coupon.isExpired) {
      color = AppColors.error;
      label = isArabic ? 'منتهي' : 'Exp';
    } else if (coupon.isMaxUsesReached) {
      color = AppColors.warning;
      label = isArabic ? 'مستنفد' : 'Full';
    } else {
      color = AppColors.success;
      label = isArabic ? 'نشط' : 'On';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
