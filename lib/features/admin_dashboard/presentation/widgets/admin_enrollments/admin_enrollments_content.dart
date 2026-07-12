import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../cubit/admin_enrollments_cubit.dart';
import 'enrollment_list_item.dart';

/// Admin Enrollments Content
class AdminEnrollmentsContent extends StatefulWidget {
  const AdminEnrollmentsContent({super.key});

  @override
  State<AdminEnrollmentsContent> createState() =>
      _AdminEnrollmentsContentState();
}

class _AdminEnrollmentsContentState extends State<AdminEnrollmentsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminEnrollmentsCubit>().loadEnrollments();
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
      context.read<AdminEnrollmentsCubit>().loadMoreEnrollments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminEnrollmentsCubit, AdminEnrollmentsState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic, isDark),
            Expanded(child: _buildEnrollmentsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminEnrollmentsState state,
    bool isArabic,
    bool isDark,
  ) {
    final statusOptions = [
      {'value': 'all', 'label': 'All', 'labelAr': 'الكل'},
      {'value': 'active', 'label': 'Active', 'labelAr': 'نشط'},
      {'value': 'completed', 'label': 'Completed', 'labelAr': 'مكتمل'},
      {'value': 'pending', 'label': 'Pending', 'labelAr': 'معلق'},
      {'value': 'refunded', 'label': 'Refunded', 'labelAr': 'مسترد'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DashboardSearchBar(
              hintText: 'Search by student or course...',
              hintTextAr: 'بحث بالطالب أو الكورس...',
              onSearch: (query) {
                context.read<AdminEnrollmentsCubit>().search(query);
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: DropdownButton<int>(
              value: state.currentStatus.index,
              underline: const SizedBox(),
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
                  context
                      .read<AdminEnrollmentsCubit>()
                      .changeStatus(EnrollmentStatus.values[index]);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsList(
    BuildContext context,
    AdminEnrollmentsState state,
    bool isArabic,
  ) {
    if (state.isLoading && state.enrollments.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.enrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد تسجيلات' : 'No enrollments found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminEnrollmentsCubit>().loadEnrollments(
            status: state.currentStatus,
            refresh: true,
          ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.enrollments.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.enrollments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final enrollment = state.enrollments[index];
          return EnrollmentListItem(
            enrollment: enrollment,
            onRefund: () => _showRefundDialog(context, enrollment.id, isArabic),
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
                    LoadingSkeleton(height: 16, width: 180),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 120),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRefundDialog(
      BuildContext context, String enrollmentId, bool isArabic) {
    final cubit = context.read<AdminEnrollmentsCubit>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardInputDialog(
        title: isArabic ? 'معالجة الاسترداد' : 'Process Refund',
        message:
            isArabic ? 'أدخل سبب الاسترداد' : 'Enter the reason for the refund',
        hintText: isArabic ? 'سبب الاسترداد...' : 'Refund reason...',
        confirmText: isArabic ? 'استرداد' : 'Refund',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        maxLines: 3,
      ),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty) {
        cubit.processRefund(enrollmentId, reason);
      }
    });
  }
}
