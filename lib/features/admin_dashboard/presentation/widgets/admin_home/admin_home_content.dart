import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/admin_dashboard_cubit.dart';

/// Admin Dashboard home with platform-wide operational statistics.
class AdminHomeContent extends StatelessWidget {
  final Function(int)? onNavigate;

  const AdminHomeContent({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                _buildPlatformHeader(context, state, isArabic, isDark),
                const SizedBox(height: 20),
                _buildStatsGrid(state, isArabic),
                const SizedBox(height: 24),
                _buildHomeBody(context, state, isArabic, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlatformHeader(
    BuildContext context,
    AdminDashboardState state,
    bool isArabic,
    bool isDark,
  ) {
    final stats = state.stats;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final title = Text(
            isArabic ? 'نظرة تشغيل المنصة' : 'Platform Operations',
            style: TextStyle(
              fontSize: isCompact ? 22 : 26,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          );

          final subtitle = Text(
            isArabic
                ? 'متابعة الطلاب والمدرسين والكورسات من مكان واحد.'
                : 'Monitor students, instructors, and courses from one place.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeaderAction(
                icon: Icons.people_alt_rounded,
                label: isArabic ? 'المستخدمون' : 'Users',
                onTap: () => onNavigate?.call(1),
              ),
              _buildHeaderAction(
                icon: Icons.play_lesson_rounded,
                label: isArabic ? 'الكورسات' : 'Courses',
                onTap: () => onNavigate?.call(2),
              ),
              _buildHeaderAction(
                icon: Icons.insights_rounded,
                label: isArabic ? 'التحليلات' : 'Analytics',
                onTap: () => onNavigate?.call(3),
              ),
            ],
          );

          final snapshot = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSnapshotPill(
                icon: Icons.school_rounded,
                label: isArabic ? 'طلاب' : 'Students',
                value: stats.totalStudents.toString(),
                color: AppColors.primary,
                isDark: isDark,
              ),
              _buildSnapshotPill(
                icon: Icons.person_rounded,
                label: isArabic ? 'مدرسون' : 'Instructors',
                value: stats.totalInstructors.toString(),
                color: AppColors.info,
                isDark: isDark,
              ),
              _buildSnapshotPill(
                icon: Icons.today_rounded,
                label: isArabic ? 'تسجيلات اليوم' : 'Today',
                value: stats.todayEnrollments.toString(),
                color: AppColors.success,
                isDark: isDark,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 8),
                subtitle,
                const SizedBox(height: 18),
                snapshot,
                const SizedBox(height: 18),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    subtitle,
                    const SizedBox(height: 18),
                    actions,
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Align(
                  alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: snapshot,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSnapshotPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
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
    ];

    return StatsGrid(
      stats: statsData,
      isLoading: isLoading,
      loadingCount: 5,
    );
  }

  Widget _buildHomeBody(
    BuildContext context,
    AdminDashboardState state,
    bool isArabic,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final chart = _buildEnrollmentsChart(state, isArabic);
        final panel = _buildFocusPanel(state, isArabic, isDark);

        if (!isWide) {
          return Column(
            children: [
              chart,
              const SizedBox(height: 16),
              panel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: chart),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: panel),
          ],
        );
      },
    );
  }

  Widget _buildEnrollmentsChart(AdminDashboardState state, bool isArabic) {
    final isLoading = state.enrollmentsChartStatus == DashboardStatus.loading;
    final data = state.enrollmentsChartData
        .map((e) => ChartDataPoint(label: e.label, value: e.value))
        .toList();

    return DashboardChart(
      title: isArabic ? 'تسجيلات الطلاب خلال الشهر' : 'Student Enrollments',
      type: DashboardChartType.bar,
      data: data,
      isLoading: isLoading,
      height: 280,
      primaryColor: AppColors.info,
      showTotal: true,
    );
  }

  Widget _buildFocusPanel(
    AdminDashboardState state,
    bool isArabic,
    bool isDark,
  ) {
    final stats = state.stats;
    final activeUsers = stats.totalStudents + stats.totalInstructors;
    final averageEnrollments = stats.totalCourses == 0
        ? 0
        : (stats.totalEnrollments / stats.totalCourses).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'مؤشرات تشغيلية' : 'Operational Signals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildSignalRow(
            icon: Icons.groups_rounded,
            label: isArabic ? 'مستخدمون نشطون على المنصة' : 'Platform users',
            value: activeUsers.toString(),
            color: AppColors.primary,
            isDark: isDark,
          ),
          _buildSignalRow(
            icon: Icons.auto_graph_rounded,
            label: isArabic
                ? 'متوسط التسجيلات لكل كورس'
                : 'Avg enrollments per course',
            value: averageEnrollments.toString(),
            color: AppColors.success,
            isDark: isDark,
          ),
          _buildSignalRow(
            icon: Icons.insights_rounded,
            label: isArabic ? 'نمو التسجيلات' : 'Enrollment change',
            value: '${stats.enrollmentChange}%',
            color: AppColors.warning,
            isDark: isDark,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => onNavigate?.call(3),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(isArabic ? 'فتح التحليلات' : 'Open analytics'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }
}
