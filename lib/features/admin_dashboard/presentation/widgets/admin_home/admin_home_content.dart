import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/admin_dashboard_cubit.dart';

/// Admin Dashboard home with statistics and charts.
class AdminHomeContent extends StatelessWidget {
  final Function(int)? onNavigate;

  const AdminHomeContent({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<AdminDashboardCubit>().refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(state, isArabic),
                const SizedBox(height: 24),
                _buildChartsRow(state, isArabic),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(AdminDashboardState state, bool isArabic) {
    final stats = state.stats;
    final isLoading = state.statsStatus == DashboardStatus.loading;

    final statsData = [
      StatsCardData(
        title: isArabic ? 'إجمالي الطلاب' : 'Total Students',
        value: stats.totalStudents.toString(),
        icon: Icons.school_rounded,
        color: AppColors.primary,
        onTap: onNavigate != null ? () => onNavigate!(1) : null,
      ),
      StatsCardData(
        title: isArabic ? 'إجمالي المدرسين' : 'Total Instructors',
        value: stats.totalInstructors.toString(),
        icon: Icons.person_rounded,
        color: AppColors.info,
        onTap: onNavigate != null ? () => onNavigate!(1) : null,
      ),
      StatsCardData(
        title: isArabic ? 'إجمالي الكورسات' : 'Total Courses',
        value: stats.totalCourses.toString(),
        icon: Icons.play_lesson_rounded,
        color: AppColors.success,
        onTap: onNavigate != null ? () => onNavigate!(2) : null,
      ),
      StatsCardData(
        title: isArabic ? 'إجمالي التسجيلات' : 'Total Enrollments',
        value: stats.totalEnrollments.toString(),
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.warning,
      ),
      StatsCardData(
        title: isArabic ? 'تسجيلات اليوم' : "Today's Enrollments",
        value: stats.todayEnrollments.toString(),
        icon: Icons.today_rounded,
        color: AppColors.error,
        changePercentage: stats.enrollmentChange.toDouble(),
      ),
      StatsCardData(
        title: isArabic ? 'إيرادات الشهر' : 'Monthly Revenue',
        value:
            '${stats.monthlyRevenue.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
        icon: Icons.attach_money_rounded,
        color: AppColors.success,
        changePercentage: stats.revenueChange,
        onTap: onNavigate != null ? () => onNavigate!(6) : null,
      ),
    ];

    return StatsGrid(
      stats: statsData,
      isLoading: isLoading,
    );
  }

  Widget _buildChartsRow(AdminDashboardState state, bool isArabic) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRevenueChart(state, isArabic),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildEnrollmentsChart(state, isArabic),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildRevenueChart(state, isArabic),
            const SizedBox(height: 24),
            _buildEnrollmentsChart(state, isArabic),
          ],
        );
      },
    );
  }

  Widget _buildRevenueChart(AdminDashboardState state, bool isArabic) {
    final isLoading = state.revenueChartStatus == DashboardStatus.loading;
    final data = state.revenueChartData
        .map((e) => ChartDataPoint(label: e.label, value: e.value))
        .toList();

    return DashboardChart(
      title: isArabic ? 'اتجاه الإيرادات' : 'Revenue Trend',
      type: DashboardChartType.area,
      data: data,
      isLoading: isLoading,
      height: 280,
    );
  }

  Widget _buildEnrollmentsChart(AdminDashboardState state, bool isArabic) {
    final isLoading = state.enrollmentsChartStatus == DashboardStatus.loading;
    final data = state.enrollmentsChartData
        .map((e) => ChartDataPoint(label: e.label, value: e.value))
        .toList();

    return DashboardChart(
      title: isArabic ? 'التسجيلات الشهرية' : 'Monthly Enrollments',
      type: DashboardChartType.bar,
      data: data,
      isLoading: isLoading,
      height: 280,
      primaryColor: AppColors.info,
    );
  }
}
