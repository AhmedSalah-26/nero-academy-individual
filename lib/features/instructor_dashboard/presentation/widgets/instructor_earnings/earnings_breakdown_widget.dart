import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_earnings_cubit.dart';

/// Earnings Breakdown by Course — NEW SCHEMA
class EarningsBreakdownWidget extends StatelessWidget {
  final InstructorEarningsState state;
  final bool isArabic;
  final bool isDark;

  const EarningsBreakdownWidget({
    super.key,
    required this.state,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Group earnings by course
    final courseEarnings = <String, double>{};
    final courseTitles = <String, String>{};
    for (final earning in state.earnings) {
      final key = earning.courseId ?? 'unknown';
      courseEarnings[key] = (courseEarnings[key] ?? 0) + earning.netAmount;
      courseTitles[key] = earning.courseName;
    }

    // Sort by earnings
    final sortedCourses = courseEarnings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCourses.isEmpty) return const SizedBox.shrink();

    final totalEarnings =
        state.earnings.fold<double>(0, (sum, e) => sum + e.netAmount);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'توزيع الأرباح حسب الكورس' : 'Earnings by Course',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedCourses.take(5).map((entry) {
            final percent =
                totalEarnings > 0 ? (entry.value / totalEarnings * 100) : 0.0;
            final colors = [
              AppColors.primary,
              AppColors.success,
              AppColors.info,
              AppColors.warning,
              AppColors.error,
            ];
            final colorIndex = sortedCourses.indexOf(entry) % colors.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          courseTitles[entry.key] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors[colorIndex],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percent / 100,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors[colorIndex],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
