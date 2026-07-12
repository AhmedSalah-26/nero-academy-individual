// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../cubit/admin_analytics_cubit.dart';

/// Admin Analytics Content
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeSelector(context, state, isArabic, isDark),
              const SizedBox(height: 24),
              _buildSummaryCards(state, isArabic, isDark),
              const SizedBox(height: 24),
              _buildChartsSection(state, isArabic, isDark),
              const SizedBox(height: 24),
              _buildTopCoursesSection(state, isArabic, isDark),
              const SizedBox(height: 24),
              _buildTopInstructorsSection(state, isArabic, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector(BuildContext context,
      AdminAnalyticsState state, bool isArabic, bool isDark) {
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
          Icon(Icons.date_range,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          Text(
            isArabic ? 'الفترة:' : 'Period:',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          TextButton(
            onPressed: () => _selectDateRange(context, state, isArabic),
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
      BuildContext context, String label, int days, AdminAnalyticsState state) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final isSelected = state.endDate.difference(state.startDate).inDays == days;

    return OutlinedButton(
      onPressed: () {
        context.read<AdminAnalyticsCubit>().setDateRange(start, end);
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
      BuildContext context, AdminAnalyticsState state, bool isArabic) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.startDate,
        end: state.endDate,
      ),
    );

    if (picked != null && mounted) {
      context
          .read<AdminAnalyticsCubit>()
          .setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildSummaryCards(
      AdminAnalyticsState state, bool isArabic, bool isDark) {
    if (state.isLoading) {
      return const Row(
        children: [
          Expanded(
            child: LoadingSkeleton(width: double.infinity, height: 100),
          ),
          SizedBox(width: 16),
          Expanded(
            child: LoadingSkeleton(width: double.infinity, height: 100),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.attach_money,
            title: isArabic ? 'إجمالي الإيرادات' : 'Total Revenue',
            value:
                '${state.totalRevenue.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.school,
            title: isArabic ? 'إجمالي التسجيلات' : 'Total Enrollments',
            value: state.totalEnrollments.toString(),
            color: AppColors.primary,
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
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(
      AdminAnalyticsState state, bool isArabic, bool isDark) {
    if (state.isLoading) {
      return const Column(
        children: [
          LoadingSkeleton(width: double.infinity, height: 300),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 300),
        ],
      );
    }

    return Column(
      children: [
        DashboardChart(
          title: isArabic ? 'الإيرادات' : 'Revenue',
          type: DashboardChartType.area,
          data: state.revenueData
              .map((d) => ChartDataPoint(
                    label: d.label,
                    value: d.value,
                    date: d.date,
                  ))
              .toList(),
          primaryColor: AppColors.success,
        ),
        const SizedBox(height: 16),
        DashboardChart(
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
        ),
      ],
    );
  }

  Widget _buildTopCoursesSection(
      AdminAnalyticsState state, bool isArabic, bool isDark) {
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
            isArabic ? 'أفضل الكورسات' : 'Top Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            ...List.generate(
                5,
                (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child:
                          LoadingSkeleton(width: double.infinity, height: 60),
                    ))
          else if (state.topCourses.isEmpty)
            Center(
              child: Text(
                isArabic ? 'لا توجد بيانات' : 'No data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...state.topCourses.asMap().entries.map((entry) {
              final index = entry.key;
              final course = entry.value;
              return _buildTopCourseItem(index + 1, course, isArabic, isDark);
            }),
        ],
      ),
    );
  }

  Widget _buildTopCourseItem(
      int rank, TopCourseModel course, bool isArabic, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? AppColors.warning : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? course.titleAr : course.titleEn,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  course.instructorName,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${course.enrollmentsCount} ${isArabic ? 'طالب' : 'students'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${course.revenue.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopInstructorsSection(
      AdminAnalyticsState state, bool isArabic, bool isDark) {
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
            isArabic ? 'أفضل المدرسين' : 'Top Instructors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            ...List.generate(
                5,
                (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child:
                          LoadingSkeleton(width: double.infinity, height: 60),
                    ))
          else if (state.topInstructors.isEmpty)
            Center(
              child: Text(
                isArabic ? 'لا توجد بيانات' : 'No data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...state.topInstructors.asMap().entries.map((entry) {
              final index = entry.key;
              final instructor = entry.value;
              return _buildTopInstructorItem(
                  index + 1, instructor, isArabic, isDark);
            }),
        ],
      ),
    );
  }

  Widget _buildTopInstructorItem(
      int rank, TopInstructorModel instructor, bool isArabic, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? AppColors.warning : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundImage: instructor.avatarUrl != null
                ? NetworkImage(instructor.avatarUrl!)
                : null,
            child:
                instructor.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  '${instructor.coursesCount} ${isArabic ? 'كورس' : 'courses'} • ${instructor.studentsCount} ${isArabic ? 'طالب' : 'students'}',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.warning),
                  const SizedBox(width: 2),
                  Text(
                    instructor.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                '${instructor.totalRevenue.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
