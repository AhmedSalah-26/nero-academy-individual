import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_course_model.dart';

class CourseDetailsStatsSection extends StatelessWidget {
  final AdminCourseModel course;
  final bool isDark;
  final bool isArabic;

  const CourseDetailsStatsSection({
    super.key,
    required this.course,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'الإحصائيات' : 'Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.people_rounded,
                    course.enrolledCount.toString(),
                    isArabic ? 'طالب' : 'Students',
                    AppColors.primary,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.star_rounded,
                    course.rating.toStringAsFixed(1),
                    '(${course.ratingCount})',
                    AppColors.warning,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.attach_money_rounded,
                    course.totalRevenue.toStringAsFixed(0),
                    isArabic ? 'الإيرادات' : 'Revenue',
                    AppColors.success,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
