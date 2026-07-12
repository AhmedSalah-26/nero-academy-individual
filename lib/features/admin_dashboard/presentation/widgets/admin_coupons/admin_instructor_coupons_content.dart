import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../data/models/admin_coupon_model.dart';
import '../../cubit/admin_coupons_cubit.dart';
import 'coupon_list_item.dart';

/// Admin Instructor Coupons Content
class AdminInstructorCouponsContent extends StatefulWidget {
  const AdminInstructorCouponsContent({super.key});

  @override
  State<AdminInstructorCouponsContent> createState() =>
      _AdminInstructorCouponsContentState();
}

class _AdminInstructorCouponsContentState
    extends State<AdminInstructorCouponsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context
        .read<AdminCouponsCubit>()
        .loadCoupons(scope: 'instructors', refresh: true);
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
              isArabic ? 'كوبونات المدرسين' : 'Instructor Coupons',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            isArabic ? '(للعرض فقط)' : '(View Only)',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
            Icon(Icons.confirmation_number_outlined,
                size: 64, color: Colors.grey[400]),
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
          .loadCoupons(scope: 'instructors', refresh: true),
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
            readOnly: true, // Read-only mode for instructor coupons
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

  void _showUsageDialog(BuildContext context, AdminCouponModel coupon) {
    AppRouter.goToCouponUsage(
      context,
      couponId: coupon.id,
      coupon: coupon,
    );
  }
}
