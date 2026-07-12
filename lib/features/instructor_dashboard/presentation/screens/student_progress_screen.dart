import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

/// Student Progress Screen - Full page for viewing detailed student progress
class StudentProgressScreen extends StatelessWidget {
  final String studentName;
  final List<StudentCourseProgress> progressList;

  const StudentProgressScreen({
    super.key,
    required this.studentName,
    required this.progressList,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Calculate overall stats
    final totalLessons = progressList.fold<int>(
      0,
      (sum, course) => sum + course.lessons.length,
    );
    final completedLessons = progressList.fold<int>(
      0,
      (sum, course) => sum + course.lessons.where((l) => l.isCompleted).length,
    );
    final avgProgress = progressList.isEmpty
        ? 0.0
        : progressList.fold<double>(
              0,
              (sum, course) => sum + course.overallProgress,
            ) /
            progressList.length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'تقدم الطالب' : 'Student Progress'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Student Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic ? 'تقدم تفصيلي' : 'Detailed Progress',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getProgressColor(avgProgress)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getProgressColor(avgProgress)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${avgProgress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(avgProgress),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.school_outlined,
                        label: isArabic ? 'الكورسات' : 'Courses',
                        value: '${progressList.length}',
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle_outline,
                        label: isArabic ? 'مكتمل' : 'Completed',
                        value: '$completedLessons',
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.pending_outlined,
                        label: isArabic ? 'متبقي' : 'Remaining',
                        value: '${totalLessons - completedLessons}',
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Course Progress List
          Expanded(
            child: progressList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isArabic
                              ? 'لا توجد بيانات تقدم'
                              : 'No progress data found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: progressList.length,
                    itemBuilder: (context, index) {
                      final courseProgress = progressList[index];
                      return _buildCourseProgressCard(
                        context,
                        courseProgress,
                        isDark,
                        isArabic,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildCourseProgressCard(
    BuildContext context,
    StudentCourseProgress courseProgress,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getProgressColor(courseProgress.overallProgress)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${courseProgress.overallProgress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(courseProgress.overallProgress),
                ),
              ),
            ),
          ),
          title: Text(
            isArabic
                ? courseProgress.courseTitleAr
                : courseProgress.courseTitleEn,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: courseProgress.overallProgress / 100,
                  minHeight: 8,
                  backgroundColor:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation(
                    _getProgressColor(courseProgress.overallProgress),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${courseProgress.lessons.where((l) => l.isCompleted).length}/${courseProgress.lessons.length} ${isArabic ? 'درس' : 'lessons'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (courseProgress.lessons.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isArabic ? 'لا توجد دروس' : 'No lessons',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...courseProgress.lessons.map(
                (lesson) => _buildLessonRow(lesson, isDark, isArabic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonRow(
    StudentLessonProgress lesson,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lesson.isCompleted
            ? AppColors.success.withValues(alpha: 0.05)
            : (isDark ? AppColors.backgroundDark : AppColors.grey50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lesson.isCompleted
              ? AppColors.success.withValues(alpha: 0.2)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Icon(
            lesson.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 22,
            color: lesson.isCompleted ? AppColors.success : Colors.grey,
          ),
          const SizedBox(width: 12),
          Icon(
            _getLessonIcon(lesson.type),
            size: 20,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic ? lesson.titleAr : lesson.titleEn,
              style: TextStyle(
                fontSize: 14,
                color: lesson.isCompleted
                    ? (isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)
                    : (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
                decoration:
                    lesson.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (lesson.watchTimeSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(lesson.watchTimeSeconds),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'article':
        return Icons.article_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${remainingSeconds}s';
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return AppColors.success;
    if (progress >= 50) return AppColors.info;
    if (progress >= 25) return AppColors.warning;
    return AppColors.error;
  }
}
