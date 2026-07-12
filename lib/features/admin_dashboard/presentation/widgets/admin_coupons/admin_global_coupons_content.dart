// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_coupon_model.dart';
import '../../cubit/admin_coupons_cubit.dart';
import 'coupon_list_item.dart';

/// Admin Global Coupons Content
class AdminGlobalCouponsContent extends StatefulWidget {
  const AdminGlobalCouponsContent({super.key});

  @override
  State<AdminGlobalCouponsContent> createState() =>
      _AdminGlobalCouponsContentState();
}

class _AdminGlobalCouponsContentState extends State<AdminGlobalCouponsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCouponsCubit>().loadCoupons(scope: 'all', refresh: true);
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
      context.read<AdminCouponsCubit>().loadMoreCoupons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AdminCouponsCubit, AdminCouponsState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, isArabic),
            Expanded(child: _buildCouponsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isArabic ? 'الكوبونات العامة' : 'Global Coupons',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, isArabic),
            icon: const Icon(Icons.add, size: 18),
            label: Text(isArabic ? 'إضافة كوبون' : 'Add Coupon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsList(
      BuildContext context, AdminCouponsState state, bool isArabic) {
    final isLoading = state.status == AdminCouponsStatus.loading;
    final isLoadingMore = state.status == AdminCouponsStatus.loadingMore;

    if (isLoading && state.coupons.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد كوبونات' : 'No coupons found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context
          .read<AdminCouponsCubit>()
          .loadCoupons(scope: 'all', refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.coupons.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.coupons.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final coupon = state.coupons[index];
          return CouponListItem(
            coupon: coupon,
            onEdit: () => _showEditDialog(context, coupon, isArabic),
            onDelete: () => _showDeleteConfirm(context, coupon.id, isArabic),
            onToggleStatus: () =>
                context.read<AdminCouponsCubit>().toggleCouponStatus(coupon),
            onToggleSuspension: () => context
                .read<AdminCouponsCubit>()
                .toggleCouponSuspension(coupon),
            onViewUsage: () => _showUsageDialog(context, coupon),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: const LoadingSkeleton(width: double.infinity, height: 100),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, bool isArabic) {
    AppRouter.goToAdminCouponEditor(
      context,
      onSave: (dto) async {
        final success =
            await context.read<AdminCouponsCubit>().createCoupon(dto);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم إنشاء الكوبون بنجاح'
                    : 'Coupon created successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _showEditDialog(
      BuildContext context, AdminCouponModel coupon, bool isArabic) {
    AppRouter.goToAdminCouponEditor(
      context,
      coupon: coupon,
      onSave: (dto) async {
        final success = await context
            .read<AdminCouponsCubit>()
            .updateCoupon(coupon.id, dto);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم تحديث الكوبون بنجاح'
                    : 'Coupon updated successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _showDeleteConfirm(
      BuildContext context, String couponId, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardConfirmDialog(
        title: isArabic ? 'حذف الكوبون' : 'Delete Coupon',
        message: isArabic
            ? 'هل أنت متأكد من حذف هذا الكوبون؟'
            : 'Are you sure you want to delete this coupon?',
        confirmText: isArabic ? 'حذف' : 'Delete',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        isDestructive: true,
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<AdminCouponsCubit>().deleteCoupon(couponId);
      }
    });
  }

  void _showUsageDialog(BuildContext context, AdminCouponModel coupon) {
    AppRouter.goToCouponUsage(
      context,
      couponId: coupon.id,
      coupon: coupon,
    );
  }
}
