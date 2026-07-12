import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:lms_platform/features/admin_dashboard/presentation/cubit/admin_analytics_cubit.dart';

/// Platform and per-instructor analytics for the admin dashboard.
class AdminAnalyticsContent extends StatefulWidget {
  const AdminAnalyticsContent({super.key});

  @override
  State<AdminAnalyticsContent> createState() => _AdminAnalyticsContentState();
}

class _AdminAnalyticsContentState extends State<AdminAnalyticsContent> {
  String _instructorSearch = '';
  _AnalyticsView _selectedView = _AnalyticsView.overview;

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
                _buildTopBar(context, state, isArabic, isDark),
                const SizedBox(height: 18),
                _buildViewSwitcher(isArabic, isDark),
                const SizedBox(height: 18),
                _buildSelectedView(context, state, isArabic, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedView(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    switch (_selectedView) {
      case _AnalyticsView.overview:
        return _buildPlatformWorkspace(state, isArabic, isDark);
      case _AnalyticsView.instructors:
        return _buildInstructorWorkspace(context, state, isArabic, isDark);
      case _AnalyticsView.courses:
        return _buildTopCoursesSection(state, isArabic, isDark);
    }
  }

  Widget _buildViewSwitcher(bool isArabic, bool isDark) {
    final items = [
      (
        view: _AnalyticsView.overview,
        icon: Icons.dashboard_rounded,
        label: isArabic ? 'نظرة عامة' : 'Overview',
      ),
      (
        view: _AnalyticsView.instructors,
        icon: Icons.people_alt_rounded,
        label: isArabic ? 'المدرسين' : 'Instructors',
      ),
      (
        view: _AnalyticsView.courses,
        icon: Icons.play_lesson_rounded,
        label: isArabic ? 'الكورسات' : 'Courses',
      ),
    ];

    return _surface(
      isDark: isDark,
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canFit = constraints.maxWidth >= 430;
          final buttons = items.map((item) {
            final selected = item.view == _selectedView;
            final button = _segmentButton(
              icon: item.icon,
              label: item.label,
              selected: selected,
              isDark: isDark,
              onTap: () => setState(() => _selectedView = item.view),
            );

            if (canFit) {
              return Expanded(child: button);
            }

            return SizedBox(width: 154, child: button);
          }).toList();

          if (canFit) {
            return Row(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  buttons[i],
                ],
              ],
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  buttons[i],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _segmentButton({
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : isDark
                  ? AppColors.surfaceDark
                  : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? AppColors.white
                  : isDark
                      ? AppColors.textMutedDark
                      : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.white
                      : isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    return _surface(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تحليلات المنصة' : 'Platform analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? 'تحكم سريع في الفترة، ثم راجع أداء المنصة وكل مدرس.'
                    : 'Filter the period, then review platform and instructor activity.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          );
          final filters = _buildDateFilter(context, state, isArabic, isDark);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                filters,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: 18),
              filters,
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
        _quickRangeButton(context, isArabic ? '7 أيام' : '7 Days', 7),
        _quickRangeButton(context, isArabic ? '30 يوم' : '30 Days', 30),
        _quickRangeButton(context, isArabic ? '90 يوم' : '90 Days', 90),
      ],
    );
  }

  Widget _quickRangeButton(BuildContext context, String label, int days) {
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

  Widget _buildPlatformWorkspace(
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    final stats = state.platformStats;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1020;
        final chart = DashboardChart(
          title: isArabic
              ? 'تسجيلات المنصة خلال الفترة'
              : 'Platform enrollments in range',
          type: DashboardChartType.bar,
          data: state.enrollmentsData
              .map((d) => ChartDataPoint(
                    label: d.label,
                    value: d.value,
                    date: d.date,
                  ))
              .toList(),
          isLoading: state.isLoading,
          height: 278,
          primaryColor: AppColors.primary,
          showTotal: true,
        );

        final summary = _surface(
          isDark: isDark,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                isArabic ? 'ملخص المنصة' : 'Platform summary',
                isDark,
                subtitle: isArabic
                    ? 'أهم الأرقام العامة والتسجيلات حسب الفترة'
                    : 'Core totals and selected-range activity',
              ),
              const SizedBox(height: 18),
              _buildMainKpi(
                icon: Icons.filter_alt_rounded,
                label: isArabic ? 'تسجيلات الفترة' : 'Range enrollments',
                value: state.totalEnrollments.toString(),
                color: AppColors.primary,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildKpiGrid(
                isDark: isDark,
                items: [
                  _KpiItem(
                    icon: Icons.school_rounded,
                    label: isArabic ? 'الطلاب' : 'Students',
                    value: stats.totalStudents.toString(),
                    color: AppColors.info,
                  ),
                  _KpiItem(
                    icon: Icons.person_rounded,
                    label: isArabic ? 'المدرسون' : 'Instructors',
                    value: stats.totalInstructors.toString(),
                    color: AppColors.success,
                  ),
                  _KpiItem(
                    icon: Icons.play_lesson_rounded,
                    label: isArabic ? 'الكورسات' : 'Courses',
                    value: stats.totalCourses.toString(),
                    color: AppColors.warning,
                  ),
                  _KpiItem(
                    icon: Icons.today_rounded,
                    label: isArabic ? 'اليوم' : 'Today',
                    value: stats.todayEnrollments.toString(),
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        );

        if (!wide) {
          return Column(
            children: [
              summary,
              const SizedBox(height: 16),
              chart,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: chart),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: summary),
          ],
        );
      },
    );
  }

  Widget _buildInstructorWorkspace(
    BuildContext context,
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    final selectedInstructor = _selectedInstructor(state);

    return _surface(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            isArabic ? 'تحليلات المدرسين' : 'Instructor analytics',
            isDark,
            subtitle: isArabic
                ? 'ابحث واختر مدرس لمراجعة نشاطه داخل الفترة المحددة'
                : 'Search and select an instructor to inspect the selected period',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final list = _buildInstructorList(
                context,
                state,
                isArabic,
                isDark,
                maxHeight: wide ? 520 : 360,
              );
              final details = _buildInstructorDetails(
                state,
                selectedInstructor,
                isArabic,
                isDark,
              );

              if (!wide) {
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
                  const SizedBox(width: 18),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ],
      ),
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
    bool isDark, {
    required double maxHeight,
  }) {
    final filtered = state.topInstructors.where((instructor) {
      final query = _instructorSearch.trim().toLowerCase();
      if (query.isEmpty) return true;
      return instructor.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        TextField(
          onChanged: (value) => setState(() => _instructorSearch = value),
          decoration: InputDecoration(
            hintText: isArabic ? 'بحث باسم المدرس' : 'Search instructors',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: state.isLoading
              ? ListView.separated(
                  shrinkWrap: true,
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) =>
                      const LoadingSkeleton(width: double.infinity, height: 68),
                )
              : filtered.isEmpty
                  ? _emptyState(
                      icon: Icons.person_off_rounded,
                      title: isArabic ? 'لا يوجد مدرسون' : 'No instructors',
                      isDark: isDark,
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final instructor = filtered[index];
                        return _instructorTile(
                          context,
                          instructor,
                          instructor.id == state.selectedInstructorId,
                          isArabic,
                          isDark,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _instructorTile(
    BuildContext context,
    TopInstructorModel instructor,
    bool selected,
    bool isArabic,
    bool isDark,
  ) {
    final name = instructor.name.isEmpty
        ? (isArabic ? 'مدرس بدون اسم' : 'Unnamed')
        : instructor.name;

    return InkWell(
      onTap: () {
        context.read<AdminAnalyticsCubit>().selectInstructor(instructor.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.1)
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
              backgroundColor: AppColors.primary.withValues(alpha: 0.13),
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _miniBadge(
                        '${instructor.coursesCount} ${isArabic ? 'كورس' : 'courses'}',
                        AppColors.info,
                        isDark,
                      ),
                      _miniBadge(
                        '${instructor.studentsCount} ${isArabic ? 'طالب' : 'students'}',
                        AppColors.success,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.keyboard_arrow_right_rounded,
              color: selected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
            ),
          ],
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
      return _emptyState(
        icon: Icons.insights_rounded,
        title: isArabic ? 'اختر مدرس لعرض البيانات' : 'Select an instructor',
        isDark: isDark,
      );
    }

    final name = instructor.name.isEmpty
        ? (isArabic ? 'مدرس بدون اسم' : 'Unnamed instructor')
        : instructor.name;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.13),
                backgroundImage: instructor.avatarUrl == null
                    ? null
                    : NetworkImage(instructor.avatarUrl!),
                child: instructor.avatarUrl == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'بيانات الفترة المحددة فقط للتسجيلات'
                          : 'Range filter applies to enrollments',
                      style: TextStyle(
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
        ),
        const SizedBox(height: 14),
        _buildKpiGrid(
          isDark: isDark,
          items: [
            _KpiItem(
              icon: Icons.play_lesson_rounded,
              label: isArabic ? 'الكورسات' : 'Courses',
              value: instructor.coursesCount.toString(),
              color: AppColors.info,
            ),
            _KpiItem(
              icon: Icons.groups_rounded,
              label: isArabic ? 'كل الطلاب' : 'All students',
              value: instructor.studentsCount.toString(),
              color: AppColors.success,
            ),
            _KpiItem(
              icon: Icons.date_range_rounded,
              label: isArabic ? 'تسجيلات الفترة' : 'Range enrollments',
              value: state.instructorEnrollmentsTotal.toString(),
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 14),
        DashboardChart(
          title: isArabic
              ? 'تسجيلات المدرس خلال الفترة'
              : 'Instructor enrollments in range',
          type: DashboardChartType.bar,
          data: state.instructorEnrollmentsData
              .map((d) => ChartDataPoint(
                    label: d.label,
                    value: d.value,
                    date: d.date,
                  ))
              .toList(),
          isLoading: state.isLoading,
          height: 245,
          primaryColor: AppColors.info,
          showTotal: true,
        ),
      ],
    );
  }

  Widget _buildTopCoursesSection(
    AdminAnalyticsState state,
    bool isArabic,
    bool isDark,
  ) {
    return _surface(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            isArabic ? 'الكورسات حسب التسجيلات' : 'Courses by enrollments',
            isDark,
            subtitle: isArabic
                ? 'أكثر الكورسات نشاطا على مستوى المنصة'
                : 'Most active platform courses',
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LoadingSkeleton(width: double.infinity, height: 58),
                ),
              ),
            )
          else if (state.topCourses.isEmpty)
            _emptyState(
              icon: Icons.play_lesson_outlined,
              title: isArabic ? 'لا توجد بيانات كورسات' : 'No course data',
              isDark: isDark,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 920;
                final itemWidth = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: state.topCourses.asMap().entries.map((entry) {
                    return SizedBox(
                      width: itemWidth,
                      child: _courseRow(
                        rank: entry.key + 1,
                        course: entry.value,
                        isArabic: isArabic,
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _courseRow({
    required int rank,
    required TopCourseModel course,
    required bool isArabic,
    required bool isDark,
  }) {
    final title = isArabic ? course.titleAr : course.titleEn;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w800,
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
          _miniBadge(
            '${course.enrollmentsCount} ${isArabic ? 'تسجيل' : 'enrollments'}',
            AppColors.primary,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _surface({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, bool isDark, {String? subtitle}) {
    return Column(
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
      ],
    );
  }

  Widget _buildMainKpi({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
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

  Widget _buildKpiGrid({
    required bool isDark,
    required List<_KpiItem> items,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: _compactKpi(item, isDark),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _compactKpi(_KpiItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  item.label,
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
        ],
      ),
    );
  }

  Widget _miniBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textMainDark : color,
        ),
      ),
    );
  }

  Widget _emptyState({
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

class _KpiItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

enum _AnalyticsView { overview, instructors, courses }
