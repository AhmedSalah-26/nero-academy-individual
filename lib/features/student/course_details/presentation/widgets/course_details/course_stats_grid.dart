import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';

/// Course Stats Grid - Shows lessons, duration, quizzes, certificate
class CourseStatsGrid extends StatelessWidget {
  final CourseDetailsEntity course;

  const CourseStatsGrid({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.play_circle_outline_rounded,
              value: course.totalLessons.toString(),
              label: 'course_details.lessons'.tr(),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.schedule_rounded,
              value: _formatHours(course.totalDuration),
              label: 'course_details.hours'.tr(),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.quiz_outlined,
              value: course.totalQuizzes.toString(),
              label: 'course_details.quizzes'.tr(),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.workspace_premium_outlined,
              value: course.hasCertificate ? '✓' : '—',
              label: 'course_details.certificate'.tr(),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final accent = theme.colorScheme.tertiary;
        final borderColor = Color.alphaBlend(
          accent.withValues(alpha: isDark ? 0.32 : 0.18),
          theme.cardColor,
        );

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.13 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: accent,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatHours(int minutes) {
    final hours = minutes / 60;
    return hours.toStringAsFixed(1);
  }
}
