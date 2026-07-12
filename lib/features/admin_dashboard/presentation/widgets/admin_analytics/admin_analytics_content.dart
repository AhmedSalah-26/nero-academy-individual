import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../cubit/admin_analytics_cubit.dart';

/// Operational analytics for students, instructors, and courses.
class AdminAnalyticsContent extends StatefulWidget {
  const AdminAnalyticsContent({super.key});

  @override
  State<AdminAnalyticsContent> createState() => _AdminAnalyticsContentState();
}

class _AdminAnalyticsContentState extends State<AdminAnalyticsContent> {
  @override
  void initState() {
    super.initState();
    context.read<AdminAnalyticsCubit>().loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminAnalyticsCubit, AdminAnalyticsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<AdminAnalyticsCubit>().loadAnalytics(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeSelector(context, state, isArabic, isDark),
                const SizedBox(height: 24),
                _buildSummaryCards(state, isArabic, isDark),
                const SizedBox(height: 24),
                _buildEnrollmentsChart(state, isArabic),
                const SizedBox(height: 24),
                _buildTopCoursesSection(state, isArabic, isDark),
                const SizedBox(height: 24),
                _buildTopInstructorsSection(state, isArabic, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
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
          Text(isArabic ? 'الفترة:' : 'Period:'),
          TextButton(
            onPressed: () => _selectDateRange(context, state),
            child: Text(
              '${DateFormat('dd/MM/yyyy').format(state.startDate)} - ${DateFormat('dd/MM/yyyy').format(state.endDate)}',
            ),
          ),
          _buildQuickDateButton(context, isArabic ? '7 أيام' : '7 Days', 7),
          _buildQuickDateButton(context, isArabic ? '30 يوم' : '30 Days', 30),
          _buildQuickDateButton(context, isArabic ? '90 يوم' : '90 Days', 90),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(BuildContext context, String label, int days) {
    return OutlinedButton(
      onPressed: () {
        final end = DateTime.now();
        final start = end.subtract(Duration(days: days));
        context.read<AdminAnalyticsCubit>().setDateRange(start, end);
      },
      child: Text(label),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    AdminAnalyticsState state,
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
      context.read<AdminAnalyticsCubit>().setDateRange(
            picked.start,
            picked.end,
          );
    }
  }

  Widget _buildSummaryCards(
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    if (state.isLoading) {
      return const LoadingSkeleton(width: double.infinity, height: 100);
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.assignment_turned_in_rounded,
            title: isArabic ? 'إجمالي التسجيلات' : 'Total Enrollments',
            value: state.totalEnrollments.toString(),
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.school_rounded,
            title: isArabic ? 'كورسات نشطة' : 'Tracked Courses',
            value: state.topCourses.length.toString(),
            color: AppColors.info,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsChart(AdminAnalyticsState state, bool isArabic) {
    if (state.isLoading) {
      return const LoadingSkeleton(width: double.infinity, height: 300);
    }

    return DashboardChart(
      title: isArabic ? 'التسجيلات' : 'Enrollments',
      type: DashboardChartType.bar,
      data: state.enrollmentsData
          .map((d) => ChartDataPoint(
                label: d.label,
                value: d.value,
                date: d.date,
              ))
          .toList(),
      primaryColor: AppColors.primary,
    );
  }

  Widget _buildTopCoursesSection(
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    return _buildListSection(
      title: isArabic ? 'الكورسات حسب التسجيلات' : 'Courses by Enrollments',
      isDark: isDark,
      isLoading: state.isLoading,
      isEmpty: state.topCourses.isEmpty,
      emptyText: isArabic ? 'لا توجد بيانات' : 'No data available',
      children: state.topCourses.asMap().entries.map((entry) {
        return _buildTopCourseItem(
          entry.key + 1,
          entry.value,
          isArabic,
          isDark,
        );
      }).toList(),
    );
  }

  Widget _buildTopInstructorsSection(
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    return _buildListSection(
      title: isArabic ? 'المدرسون حسب النشاط' : 'Instructors by Activity',
      isDark: isDark,
      isLoading: state.isLoading,
      isEmpty: state.topInstructors.isEmpty,
      emptyText: isArabic ? 'لا توجد بيانات' : 'No data available',
      children: state.topInstructors.asMap().entries.map((entry) {
        return _buildTopInstructorItem(
          entry.key + 1,
          entry.value,
          isArabic,
          isDark,
        );
      }).toList(),
    );
  }

  Widget _buildListSection({
    required String title,
    required bool isDark,
    required bool isLoading,
    required bool isEmpty,
    required String emptyText,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            ...List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LoadingSkeleton(width: double.infinity, height: 60),
              ),
            )
          else if (isEmpty)
            Center(child: Text(emptyText))
          else
            ...children,
        ],
      ),
    );
  }

  Widget _buildTopCourseItem(
    int rank,
    TopCourseModel course,
    bool isArabic,
    bool isDark,
  ) {
    return _buildRankedRow(
      rank: rank,
      title: isArabic ? course.titleAr : course.titleEn,
      subtitle: course.instructorName,
      trailing: '${course.enrollmentsCount} ${isArabic ? 'طالب' : 'students'}',
      isDark: isDark,
    );
  }

  Widget _buildTopInstructorItem(
    int rank,
    TopInstructorModel instructor,
    bool isArabic,
    bool isDark,
  ) {
    return _buildRankedRow(
      rank: rank,
      title: instructor.name,
      subtitle: '${instructor.coursesCount} ${isArabic ? 'كورسات' : 'courses'}',
      trailing: '${instructor.studentsCount} ${isArabic ? 'طالب' : 'students'}',
      isDark: isDark,
    );
  }

  Widget _buildRankedRow({
    required int rank,
    required String title,
    required String subtitle,
    required String trailing,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '#$rank',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
