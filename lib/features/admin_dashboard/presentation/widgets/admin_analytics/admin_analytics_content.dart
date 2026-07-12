import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../cubit/admin_analytics_cubit.dart';

/// Platform and per-instructor analytics for the admin dashboard.
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state, isArabic, isDark),
                const SizedBox(height: 20),
                _buildPlatformSummary(state, isArabic),
                const SizedBox(height: 20),
                _buildPlatformChart(state, isArabic),
                const SizedBox(height: 24),
                _buildInstructorAnalytics(context, state, isArabic, isDark),
                const SizedBox(height: 24),
                _buildTopCoursesSection(state, isArabic, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تحليلات المنصة والمدرسين' : 'Platform Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'اختر فترة زمنية ثم اضغط على أي مدرس لعرض أدائه داخل نفس الفترة.'
                    : 'Choose a date range, then select an instructor to inspect their activity.',
                style: TextStyle(
                  height: 1.5,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          );

          final dateFilter = _buildDateFilter(context, state, isArabic, isDark);

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 16),
                dateFilter,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 20),
              dateFilter,
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateFilter(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    final rangeText =
        '${DateFormat('dd/MM/yyyy').format(state.startDate)} - ${DateFormat('dd/MM/yyyy').format(state.endDate)}';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _selectDateRange(context, state),
          icon: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(rangeText),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.textMainDark : AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        _buildQuickDateButton(context, isArabic ? '7 أيام' : '7 Days', 7),
        _buildQuickDateButton(context, isArabic ? '30 يوم' : '30 Days', 30),
        _buildQuickDateButton(context, isArabic ? '90 يوم' : '90 Days', 90),
      ],
    );
  }

  Widget _buildQuickDateButton(BuildContext context, String label, int days) {
    return TextButton(
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

  Widget _buildPlatformSummary(AdminAnalyticsState state, bool isArabic) {
    final stats = state.platformStats;
    final isLoading = state.isLoading;

    return StatsGrid(
      isLoading: isLoading,
      loadingCount: 6,
      stats: [
        StatsCardData(
          title: isArabic ? 'طلاب المنصة' : 'Students',
          value: stats.totalStudents.toString(),
          icon: Icons.school_rounded,
          color: AppColors.primary,
        ),
        StatsCardData(
          title: isArabic ? 'مدرسو المنصة' : 'Instructors',
          value: stats.totalInstructors.toString(),
          icon: Icons.person_rounded,
          color: AppColors.info,
        ),
        StatsCardData(
          title: isArabic ? 'كورسات المنصة' : 'Courses',
          value: stats.totalCourses.toString(),
          icon: Icons.play_lesson_rounded,
          color: AppColors.success,
        ),
        StatsCardData(
          title: isArabic ? 'كل التسجيلات' : 'All Enrollments',
          value: stats.totalEnrollments.toString(),
          icon: Icons.assignment_turned_in_rounded,
          color: AppColors.warning,
        ),
        StatsCardData(
          title: isArabic ? 'تسجيلات الفترة' : 'Range Enrollments',
          value: state.totalEnrollments.toString(),
          icon: Icons.filter_alt_rounded,
          color: AppColors.error,
        ),
        StatsCardData(
          title: isArabic ? 'تسجيلات اليوم' : "Today's Enrollments",
          value: stats.todayEnrollments.toString(),
          icon: Icons.today_rounded,
          color: AppColors.primary,
          changePercentage: stats.enrollmentChange.toDouble(),
        ),
      ],
    );
  }

  Widget _buildPlatformChart(AdminAnalyticsState state, bool isArabic) {
    return DashboardChart(
      title: isArabic
          ? 'تسجيلات المنصة حسب الفترة'
          : 'Platform enrollments by date',
      type: DashboardChartType.bar,
      data: state.enrollmentsData
          .map((d) => ChartDataPoint(
                label: d.label,
                value: d.value,
                date: d.date,
              ))
          .toList(),
      isLoading: state.isLoading,
      height: 280,
      primaryColor: AppColors.primary,
      showTotal: true,
    );
  }

  Widget _buildInstructorAnalytics(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    final selectedInstructor = _selectedInstructor(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final list = _buildInstructorList(context, state, isArabic, isDark);
        final details = _buildInstructorDetails(
          state,
          selectedInstructor,
          isArabic,
          isDark,
        );

        if (!isWide) {
          return Column(
            children: [
              list,
              const SizedBox(height: 16),
              details,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 360, child: list),
            const SizedBox(width: 16),
            Expanded(child: details),
          ],
        );
      },
    );
  }

  TopInstructorModel? _selectedInstructor(AdminAnalyticsState state) {
    if (state.topInstructors.isEmpty) return null;
    final selectedId = state.selectedInstructorId;
    return state.topInstructors.firstWhere(
      (instructor) => instructor.id == selectedId,
      orElse: () => state.topInstructors.first,
    );
  }

  Widget _buildInstructorList(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    return _buildSectionShell(
      title: isArabic ? 'قائمة المدرسين' : 'Instructors',
      subtitle: isArabic
          ? 'اضغط على مدرس لعرض إحصائياته'
          : 'Select an instructor to view analytics',
      isDark: isDark,
      child: state.isLoading
          ? Column(
              children: List.generate(
                5,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LoadingSkeleton(width: double.infinity, height: 64),
                ),
              ),
            )
          : state.topInstructors.isEmpty
              ? _buildEmptyState(
                  icon: Icons.person_off_rounded,
                  title: isArabic ? 'لا يوجد مدرسون' : 'No instructors',
                  isDark: isDark,
                )
              : Column(
                  children: state.topInstructors.map((instructor) {
                    final selected =
                        instructor.id == state.selectedInstructorId;
                    return _buildInstructorTile(
                      context,
                      instructor,
                      selected,
                      isArabic,
                      isDark,
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildInstructorTile(
    BuildContext context,
    TopInstructorModel instructor,
    bool selected,
    bool isArabic,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          context.read<AdminAnalyticsCubit>().selectInstructor(instructor.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.11)
                : isDark
                    ? AppColors.surfaceDark
                    : AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: instructor.avatarUrl == null
                    ? null
                    : NetworkImage(instructor.avatarUrl!),
                child: instructor.avatarUrl == null
                    ? const Icon(Icons.person_rounded, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor.name.isEmpty
                          ? (isArabic ? 'مدرس بدون اسم' : 'Unnamed instructor')
                          : instructor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${instructor.coursesCount} ${isArabic ? 'كورس' : 'courses'} • ${instructor.studentsCount} ${isArabic ? 'طالب' : 'students'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Icon(
                selected ? Icons.check_circle_rounded : Icons.chevron_right,
                color: selected
                    ? AppColors.primary
                    : isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorDetails(
    AdminAnalyticsState state,
    TopInstructorModel? instructor,
    bool isArabic,
    bool isDark,
  ) {
    if (instructor == null) {
      return _buildSectionShell(
        title: isArabic ? 'تحليلات المدرس' : 'Instructor analytics',
        isDark: isDark,
        child: _buildEmptyState(
          icon: Icons.insights_rounded,
          title: isArabic ? 'اختر مدرس لعرض البيانات' : 'Select an instructor',
          isDark: isDark,
        ),
      );
    }

    return Column(
      children: [
        _buildSectionShell(
          title: instructor.name.isEmpty
              ? (isArabic ? 'تحليلات المدرس' : 'Instructor analytics')
              : instructor.name,
          subtitle: isArabic
              ? 'الإحصائيات المعروضة حسب فلتر التاريخ الحالي'
              : 'Numbers reflect the selected date range',
          isDark: isDark,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricCard(
                icon: Icons.play_lesson_rounded,
                label: isArabic ? 'الكورسات' : 'Courses',
                value: instructor.coursesCount.toString(),
                color: AppColors.info,
                isDark: isDark,
              ),
              _buildMetricCard(
                icon: Icons.groups_rounded,
                label: isArabic ? 'كل الطلاب' : 'All students',
                value: instructor.studentsCount.toString(),
                color: AppColors.success,
                isDark: isDark,
              ),
              _buildMetricCard(
                icon: Icons.date_range_rounded,
                label: isArabic ? 'تسجيلات الفترة' : 'Range enrollments',
                value: state.instructorEnrollmentsTotal.toString(),
                color: AppColors.primary,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashboardChart(
          title: isArabic
              ? 'تسجيلات المدرس حسب الفترة'
              : 'Instructor enrollments by date',
          type: DashboardChartType.bar,
          data: state.instructorEnrollmentsData
              .map((d) => ChartDataPoint(
                    label: d.label,
                    value: d.value,
                    date: d.date,
                  ))
              .toList(),
          isLoading: state.isLoading,
          height: 240,
          primaryColor: AppColors.info,
          showTotal: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildTopCoursesSection(
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    return _buildSectionShell(
      title: isArabic ? 'الكورسات حسب التسجيلات' : 'Courses by enrollments',
      subtitle: isArabic
          ? 'أكثر الكورسات نشاطا على مستوى المنصة'
          : 'Most active platform courses',
      isDark: isDark,
      child: state.isLoading
          ? Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LoadingSkeleton(width: double.infinity, height: 58),
                ),
              ),
            )
          : state.topCourses.isEmpty
              ? _buildEmptyState(
                  icon: Icons.play_lesson_outlined,
                  title: isArabic ? 'لا توجد بيانات كورسات' : 'No course data',
                  isDark: isDark,
                )
              : Column(
                  children: state.topCourses.asMap().entries.map((entry) {
                    return _buildCourseRow(
                      rank: entry.key + 1,
                      course: entry.value,
                      isArabic: isArabic,
                      isDark: isDark,
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildCourseRow({
    required int rank,
    required TopCourseModel course,
    required bool isArabic,
    required bool isDark,
  }) {
    final title = isArabic ? course.titleAr : course.titleEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty
                      ? (isArabic ? 'كورس بدون اسم' : 'Untitled')
                      : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course.instructorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 12),
          Text(
            '${course.enrollmentsCount} ${isArabic ? 'تسجيل' : 'enrollments'}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionShell({
    required String title,
    required Widget child,
    required bool isDark,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
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
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 44,
            color: isDark ? AppColors.textMutedDark : AppColors.grey300,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
