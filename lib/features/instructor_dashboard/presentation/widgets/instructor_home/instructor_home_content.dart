import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/instructor_dashboard_cubit.dart';
import 'widgets/instructor_home_mobile_layout.dart';

/// Instructor Home Content
class InstructorHomeContent extends StatelessWidget {
  final Function(int)? onNavigate;

  const InstructorHomeContent({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return BlocBuilder<InstructorDashboardCubit, InstructorDashboardState>(
      builder: (context, state) {
        if (isMobile) {
          return InstructorHomeMobileLayout(
            state: state,
            isArabic: isArabic,
            onNavigate: onNavigate,
            onRefresh: () => context.read<InstructorDashboardCubit>().refresh(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<InstructorDashboardCubit>().refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(context, state, isArabic),
                const SizedBox(height: 24),
                _buildDateRangeSelector(context, state, isArabic),
                const SizedBox(height: 24),
                _buildChartsSection(context, state, isArabic),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    InstructorDashboardState state,
    bool isArabic,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.date_range,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          Text(
            isArabic ? 'الفترة:' : 'Period:',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          TextButton(
            onPressed: () => _selectDateRange(context, state),
            child: Text(
              '${DateFormat('dd/MM/yyyy').format(state.startDate)} - ${DateFormat('dd/MM/yyyy').format(state.endDate)}',
            ),
          ),
          _buildQuickDateButton(
            context,
            isArabic ? '7 أيام' : '7 Days',
            7,
            state,
          ),
          _buildQuickDateButton(
            context,
            isArabic ? '30 يوم' : '30 Days',
            30,
            state,
          ),
          _buildQuickDateButton(
            context,
            isArabic ? '90 يوم' : '90 Days',
            90,
            state,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(
    BuildContext context,
    String label,
    int days,
    InstructorDashboardState state,
  ) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final isSelected = state.endDate.difference(state.startDate).inDays == days;

    return OutlinedButton(
      onPressed: () {
        context.read<InstructorDashboardCubit>().setDateRange(start, end);
      },
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : null,
        ),
      ),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    InstructorDashboardState state,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.startDate,
        end: state.endDate,
      ),
    );

    if (picked != null && context.mounted) {
      context
          .read<InstructorDashboardCubit>()
          .setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildStatsGrid(
    BuildContext context,
    InstructorDashboardState state,
    bool isArabic,
  ) {
    if (state.isLoading) {
      return const StatsGrid(
        isLoading: true,
        stats: [],
      );
    }

    final stats = state.stats;
    return StatsGrid(
      stats: [
        StatsCardData(
          title: isArabic ? 'إجمالي الكورسات' : 'Total Courses',
          value: stats.totalCourses.toString(),
          icon: Icons.school_rounded,
          color: AppColors.primary,
          onTap: onNavigate != null ? () => onNavigate!(1) : null,
        ),
        StatsCardData(
          title: isArabic ? 'إجمالي الطلاب' : 'Total Students',
          value: stats.totalStudents.toString(),
          icon: Icons.people_rounded,
          color: AppColors.info,
          onTap: onNavigate != null ? () => onNavigate!(2) : null,
        ),
        StatsCardData(
          title: isArabic ? 'إجمالي الأرباح' : 'Total Earnings',
          value:
              '${stats.totalEarnings.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
          icon: Icons.attach_money_rounded,
          color: AppColors.success,
          onTap: onNavigate != null ? () => onNavigate!(6) : null, // Earnings = 6
        ),
        StatsCardData(
          title: isArabic ? 'متوسط التقييم' : 'Average Rating',
          value: stats.averageRating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          color: AppColors.warning,
          onTap: onNavigate != null ? () => onNavigate!(10) : null, // Reviews = 10
        ),
        StatsCardData(
          title: isArabic ? 'الرصيد المتاح' : 'Available Balance',
          value:
              '${stats.availableBalance.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.warning,
          onTap: onNavigate != null ? () => onNavigate!(6) : null, // Earnings = 6
        ),
        StatsCardData(
          title: isArabic ? 'أسئلة بدون إجابة' : 'Unanswered Q&A',
          value: stats.unansweredQuestions.toString(),
          icon: Icons.question_answer_rounded,
          color: AppColors.error,
          onTap: onNavigate != null ? () => onNavigate!(9) : null, // Q&A = 9
        ),
      ],
    );
  }

  Widget _buildChartsSection(
    BuildContext context,
    InstructorDashboardState state,
    bool isArabic,
  ) {
    if (state.isLoading) {
      return const Column(
        children: [
          LoadingSkeleton(width: double.infinity, height: 250),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 250),
        ],
      );
    }

    final days = state.endDate.difference(state.startDate).inDays;
    final periodText = isArabic ? 'آخر $days يوم' : 'Last $days Days';

    return Column(
      children: [
        DashboardChart(
          title: isArabic ? 'الأرباح ($periodText)' : 'Earnings ($periodText)',
          type: DashboardChartType.area,
          data: state.revenueChart
              .map((e) => ChartDataPoint(label: e.label, value: e.value))
              .toList(),
          primaryColor: AppColors.success,
        ),
        const SizedBox(height: 16),
        DashboardChart(
          title: isArabic
              ? 'التسجيلات ($periodText)'
              : 'Enrollments ($periodText)',
          type: DashboardChartType.bar,
          data: state.enrollmentsChart
              .map((e) => ChartDataPoint(label: e.label, value: e.value))
              .toList(),
          primaryColor: AppColors.primary,
        ),
      ],
    );
  }
}
