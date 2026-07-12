import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/shared_widgets/responsive_dialog.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_coupon_model.dart';
import '../../cubit/admin_coupons_cubit.dart';
import 'coupon_list_item.dart';

/// Admin Coupons Content
class AdminCouponsContent extends StatefulWidget {
  const AdminCouponsContent({super.key});

  @override
  State<AdminCouponsContent> createState() => _AdminCouponsContentState();
}

class _AdminCouponsContentState extends State<AdminCouponsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCouponsCubit>().loadCoupons(refresh: true);
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

    return BlocConsumer<AdminCouponsCubit, AdminCouponsState>(
      listener: (context, state) {
        if (state.actionStatus == AdminCouponsStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<AdminCouponsCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic),
            Expanded(child: _buildCouponsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminCouponsState state,
    bool isArabic,
  ) {
    final tabs = [
      const DashboardTabItem(
        label: 'All',
        labelAr: 'الكل',
        icon: Icons.list_rounded,
      ),
      const DashboardTabItem(
        label: 'Active',
        labelAr: 'نشط',
        icon: Icons.check_circle_rounded,
      ),
      const DashboardTabItem(
        label: 'Inactive',
        labelAr: 'غير نشط',
        icon: Icons.pause_circle_rounded,
      ),
      const DashboardTabItem(
        label: 'Expired',
        labelAr: 'منتهي',
        icon: Icons.timer_off_rounded,
      ),
    ];

    final statusFilters = ['all', 'active', 'inactive', 'expired'];
    final currentIndex = state.currentStatus == null
        ? 0
        : statusFilters.indexOf(state.currentStatus!);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DashboardTabs(
                  tabs: tabs,
                  selectedIndex: currentIndex >= 0 ? currentIndex : 0,
                  onTabSelected: (index) {
                    final status = index == 0 ? null : statusFilters[index];
                    context
                        .read<AdminCouponsCubit>()
                        .changeStatusFilter(status);
                  },
                ),
              ),
              const SizedBox(width: 16),
              _buildAddButton(context, isArabic),
            ],
          ),
          const SizedBox(height: 16),
          DashboardSearchBar(
            hintText: 'Search by code or name...',
            hintTextAr: 'بحث بالكود أو الاسم...',
            onSearch: (query) {
              context.read<AdminCouponsCubit>().search(query);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isArabic) {
    return ElevatedButton.icon(
      onPressed: () => _showCouponEditor(context, null),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(isArabic ? 'إضافة كوبون' : 'Add Coupon'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCouponsList(
    BuildContext context,
    AdminCouponsState state,
    bool isArabic,
  ) {
    if (state.status == AdminCouponsStatus.loading && state.coupons.isEmpty) {
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
              isArabic ? 'لا يوجد كوبونات' : 'No coupons found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCouponEditor(context, null),
              icon: const Icon(Icons.add_rounded),
              label: Text(isArabic ? 'إضافة كوبون جديد' : 'Add New Coupon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminCouponsCubit>().loadCoupons(
            status: state.currentStatus,
            scope: state.currentScope,
            refresh: true,
          ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.coupons.length +
            (state.status == AdminCouponsStatus.loadingMore ? 1 : 0),
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
          final isInstructorCoupon = coupon.instructorId != null;

          return CouponListItem(
            coupon: coupon,
            readOnly: isInstructorCoupon, // Read-only for instructor coupons
            onEdit: isInstructorCoupon
                ? null
                : () => _showCouponEditor(context, coupon),
            onToggleStatus: () =>
                context.read<AdminCouponsCubit>().toggleCouponStatus(coupon),
            onToggleSuspension: () => context
                .read<AdminCouponsCubit>()
                .toggleCouponSuspension(coupon),
            onDelete: isInstructorCoupon
                ? null
                : () => _confirmDelete(context, coupon, isArabic),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 48, height: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 100),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 150),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCouponEditor(BuildContext context, AdminCouponModel? coupon) {
    AppRouter.goToAdminCouponEditor(
      context,
      coupon: coupon,
      onSave: (dto) async {
        bool success;
        if (coupon == null) {
          success = await context.read<AdminCouponsCubit>().createCoupon(dto);
        } else {
          success = await context
              .read<AdminCouponsCubit>()
              .updateCoupon(coupon.id, dto);
        }
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? (coupon == null
                        ? 'تم إنشاء الكوبون بنجاح'
                        : 'تم تحديث الكوبون بنجاح')
                    : (coupon == null
                        ? 'Coupon created successfully'
                        : 'Coupon updated successfully'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _confirmDelete(
      BuildContext context, AdminCouponModel coupon, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => ResponsiveAlertDialog(
        title: isArabic ? 'حذف الكوبون' : 'Delete Coupon',
        content: isArabic
            ? 'هل أنت متأكد من حذف الكوبون "${coupon.code}"؟'
            : 'Are you sure you want to delete coupon "${coupon.code}"?',
        confirmText: isArabic ? 'حذف' : 'Delete',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(dialogContext);
          final success =
              await context.read<AdminCouponsCubit>().deleteCoupon(coupon.id);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? 'تم حذف الكوبون بنجاح'
                      : 'Coupon deleted successfully',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _showUsageDialog(BuildContext context, AdminCouponModel coupon) {
    AppRouter.goToCouponUsage(
      context,
      couponId: coupon.id,
      coupon: coupon,
    );
  }
}
