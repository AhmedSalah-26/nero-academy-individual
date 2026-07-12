import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import 'student_profile_widgets.dart';

/// ─────────────────────────────────────────
/// Overview Tab
/// ─────────────────────────────────────────
class StudentOverviewTab extends StatelessWidget {
  final List<Map<String, dynamic>> enrollments;
  final List<Map<String, dynamic>> quizAttempts;
  final int totalLessons;
  final int completedLessons;
  final int watchSeconds;
  final bool isDark;
  final bool isArabic;

  const StudentOverviewTab({
    super.key,
    required this.enrollments,
    required this.quizAttempts,
    required this.totalLessons,
    required this.completedLessons,
    required this.watchSeconds,
    required this.isDark,
    required this.isArabic,
  });

  String get _watchStr {
    final h = watchSeconds ~/ 3600;
    final m = (watchSeconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final completed = enrollments
        .where((e) =>
            (e['progress_percentage'] as num?)?.toDouble() == 100 ||
            e['completed_at'] != null)
        .length;
    final passed = quizAttempts.where((a) => a['passed'] == true).length;
    final avgScore = quizAttempts.isEmpty
        ? 0.0
        : quizAttempts
                .map((a) => (a['score'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            quizAttempts.length;
    final overall =
        totalLessons == 0 ? 0.0 : completedLessons / totalLessons * 100;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Overall progress
        ProfileCard(
          isDark: isDark,
          borderColor: AppColors.primary.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.trending_up_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        isArabic ? 'التقدم الإجمالي' : 'Overall Progress',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight)),
                  ),
                  Text('${overall.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: profileProgressColor(overall))),
                ],
              ),
              const SizedBox(height: 14),
              ProfileProgressBar(progress: overall),
              const SizedBox(height: 8),
              Text(
                '$completedLessons / $totalLessons ${isArabic ? 'درس' : 'lessons'}',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Stats grid 2x3
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            ProfileStatCard(
                icon: Icons.school_outlined,
                label: isArabic ? 'الكورسات' : 'Courses',
                value: '${enrollments.length}',
                color: AppColors.info,
                isDark: isDark),
            ProfileStatCard(
                icon: Icons.check_circle_outline,
                label: isArabic ? 'مكتملة' : 'Completed',
                value: '$completed',
                color: AppColors.success,
                isDark: isDark),
            ProfileStatCard(
                icon: Icons.timer_outlined,
                label: isArabic ? 'وقت المشاهدة' : 'Watch Time',
                value: _watchStr,
                color: AppColors.primary,
                isDark: isDark),
            ProfileStatCard(
                icon: Icons.quiz_outlined,
                label: isArabic ? 'الاختبارات' : 'Quizzes',
                value: '${quizAttempts.length}',
                color: AppColors.warning,
                isDark: isDark),
            ProfileStatCard(
                icon: Icons.military_tech_outlined,
                label: isArabic ? 'ناجح' : 'Passed',
                value: '$passed',
                color: AppColors.success,
                isDark: isDark),
            ProfileStatCard(
                icon: Icons.analytics_outlined,
                label: isArabic ? 'متوسط الدرجات' : 'Avg Score',
                value: '${avgScore.toStringAsFixed(0)}%',
                color: AppColors.info,
                isDark: isDark),
          ],
        ),
        if (enrollments.isNotEmpty) ...[
          const SizedBox(height: 22),
          ProfileSectionTitle(
              title: isArabic ? 'أحدث الكورسات' : 'Recent Courses',
              isDark: isDark),
          const SizedBox(height: 10),
          ...enrollments.take(3).map((e) => _CourseProgressRow(
              enrollment: e, isDark: isDark, isArabic: isArabic)),
        ],
        if (quizAttempts.isNotEmpty) ...[
          const SizedBox(height: 22),
          ProfileSectionTitle(
              title: isArabic ? 'آخر الاختبارات' : 'Recent Quizzes',
              isDark: isDark),
          const SizedBox(height: 10),
          ...quizAttempts.take(3).map((a) =>
              _QuizRowCompact(attempt: a, isDark: isDark, isArabic: isArabic)),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _CourseProgressRow extends StatelessWidget {
  final Map<String, dynamic> enrollment;
  final bool isDark;
  final bool isArabic;
  const _CourseProgressRow(
      {required this.enrollment, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final course = enrollment['courses'] as Map<String, dynamic>? ?? {};
    final title = isArabic
        ? course['title_ar'] as String? ?? ''
        : course['title_en'] as String? ?? '';
    final progress =
        (enrollment['progress_percentage'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              ProfileProgressBar(progress: progress, height: 6),
            ]),
          ),
          const SizedBox(width: 12),
          Text('${progress.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: profileProgressColor(progress))),
        ],
      ),
    );
  }
}

class _QuizRowCompact extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final bool isDark;
  final bool isArabic;
  const _QuizRowCompact(
      {required this.attempt, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final quiz = attempt['quizzes'] as Map<String, dynamic>? ?? {};
    final title = isArabic
        ? quiz['title_ar'] as String? ?? ''
        : quiz['title_en'] as String? ?? '';
    final score = (attempt['score'] as num?)?.toDouble() ?? 0;
    final passed = attempt['passed'] as bool? ?? false;
    final color = passed ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle : Icons.cancel,
              color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          Text('${score.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// Courses Tab
/// ─────────────────────────────────────────
class StudentCoursesTab extends StatelessWidget {
  final List<Map<String, dynamic>> enrollments;
  final bool isDark;
  final bool isArabic;

  const StudentCoursesTab(
      {super.key,
      required this.enrollments,
      required this.isDark,
      required this.isArabic});

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(isArabic ? 'لم تسجل في أي كورس بعد' : 'No courses enrolled yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: enrollments.length,
      itemBuilder: (_, i) => _CourseDetailCard(
          enrollment: enrollments[i], isDark: isDark, isArabic: isArabic),
    );
  }
}

class _CourseDetailCard extends StatelessWidget {
  final Map<String, dynamic> enrollment;
  final bool isDark;
  final bool isArabic;
  const _CourseDetailCard(
      {required this.enrollment, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final course = enrollment['courses'] as Map<String, dynamic>? ?? {};
    final title = isArabic
        ? course['title_ar'] as String? ?? ''
        : course['title_en'] as String? ?? '';
    final thumbnail = course['thumbnail_url'] as String?;
    final progress =
        (enrollment['progress_percentage'] as num?)?.toDouble() ?? 0;
    final totalL = course['total_lessons'] as int? ?? 0;
    final completedL = (totalL * progress / 100).round();
    final isCompleted = progress >= 100 || enrollment['completed_at'] != null;
    final fmt = DateFormat('yyyy/MM/dd');

    Color statusColor = isCompleted
        ? AppColors.success
        : (progress > 0 ? AppColors.info : AppColors.grey500);
    String statusLabel = isCompleted
        ? (isArabic ? 'مكتمل' : 'Completed')
        : progress > 0
            ? (isArabic ? 'جارى' : 'In Progress')
            : (isArabic ? 'لم يبدأ' : 'Not Started');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: thumbnail != null
                  ? Image.network(thumbnail,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const CourseThumbnailPlaceholder(size: 56))
                  : const CourseThumbnailPlaceholder(size: 56),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3))),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor))),
                ])),
            Text('${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: profileProgressColor(progress))),
          ]),
          const SizedBox(height: 12),
          ProfileProgressBar(progress: progress),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 6, children: [
            ProfileMetaItem(
                icon: Icons.menu_book_outlined,
                label: '$completedL/$totalL ${isArabic ? 'درس' : 'lessons'}',
                isDark: isDark),
            if (enrollment['enrolled_at'] != null)
              ProfileMetaItem(
                  icon: Icons.login_outlined,
                  label: (isArabic ? 'تسجيل: ' : 'Enrolled: ') +
                      fmt.format(
                          DateTime.parse(enrollment['enrolled_at'] as String)),
                  isDark: isDark),
            if (enrollment['last_accessed_at'] != null)
              ProfileMetaItem(
                  icon: Icons.history_outlined,
                  label: (isArabic ? 'آخر دخول: ' : 'Last: ') +
                      fmt.format(DateTime.parse(
                          enrollment['last_accessed_at'] as String)),
                  isDark: isDark),
            if (enrollment['completed_at'] != null)
              ProfileMetaItem(
                  icon: Icons.done_all,
                  label: (isArabic ? 'اكتمل: ' : 'Done: ') +
                      fmt.format(
                          DateTime.parse(enrollment['completed_at'] as String)),
                  isDark: isDark,
                  color: AppColors.success),
          ]),
        ]),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// Quizzes Tab
/// ─────────────────────────────────────────
class StudentQuizzesTab extends StatelessWidget {
  final List<Map<String, dynamic>> quizAttempts;
  final bool isDark;
  final bool isArabic;

  const StudentQuizzesTab(
      {super.key,
      required this.quizAttempts,
      required this.isDark,
      required this.isArabic});

  @override
  Widget build(BuildContext context) {
    if (quizAttempts.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(isArabic ? 'لم تحل أي اختبار بعد' : 'No quiz attempts yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ]));
    }
    final total = quizAttempts.length;
    final passed = quizAttempts.where((a) => a['passed'] == true).length;
    final avgScore = quizAttempts
            .map((a) => (a['score'] as num?)?.toDouble() ?? 0)
            .reduce((a, b) => a + b) /
        total;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [
          Expanded(
              child: _QuizStatChip(
                  label: isArabic ? 'إجمالي' : 'Total',
                  value: '$total',
                  color: AppColors.info,
                  icon: Icons.assignment_outlined)),
          const SizedBox(width: 8),
          Expanded(
              child: _QuizStatChip(
                  label: isArabic ? 'ناجح' : 'Passed',
                  value: '$passed',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline)),
          const SizedBox(width: 8),
          Expanded(
              child: _QuizStatChip(
                  label: isArabic ? 'راسب' : 'Failed',
                  value: '${total - passed}',
                  color: AppColors.error,
                  icon: Icons.cancel_outlined)),
          const SizedBox(width: 8),
          Expanded(
              child: _QuizStatChip(
                  label: isArabic ? 'متوسط' : 'Avg',
                  value: '${avgScore.toStringAsFixed(0)}%',
                  color: AppColors.warning,
                  icon: Icons.analytics_outlined)),
        ]),
        const SizedBox(height: 18),
        ...quizAttempts.map((a) =>
            _QuizAttemptCard(attempt: a, isDark: isDark, isArabic: isArabic)),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _QuizStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _QuizStatChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _QuizAttemptCard extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final bool isDark;
  final bool isArabic;
  const _QuizAttemptCard(
      {required this.attempt, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final quiz = attempt['quizzes'] as Map<String, dynamic>? ?? {};
    final course = quiz['courses'] as Map<String, dynamic>? ?? {};
    final title = isArabic
        ? quiz['title_ar'] as String? ?? ''
        : quiz['title_en'] as String? ?? '';
    final courseTitle = isArabic
        ? course['title_ar'] as String? ?? ''
        : course['title_en'] as String? ?? '';
    final score = (attempt['score'] as num?)?.toDouble() ?? 0;
    final passed = attempt['passed'] as bool? ?? false;
    final timeTaken = attempt['time_taken'] as int? ?? 0;
    final completedAt = attempt['completed_at'] != null
        ? DateFormat('yyyy/MM/dd HH:mm')
            .format(DateTime.parse(attempt['completed_at'] as String))
        : null;
    final color = passed ? AppColors.success : AppColors.error;
    final timeStr = timeTaken > 60
        ? '${timeTaken ~/ 60}m ${timeTaken % 60}s'
        : '${timeTaken}s';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                passed ? Icons.military_tech_outlined : Icons.replay_outlined,
                color: color,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (courseTitle.isNotEmpty)
                  Text(courseTitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight)),
                const SizedBox(height: 6),
                Wrap(spacing: 12, children: [
                  if (timeTaken > 0)
                    ProfileMetaItem(
                        icon: Icons.timer_outlined,
                        label: timeStr,
                        isDark: isDark),
                  if (completedAt != null)
                    ProfileMetaItem(
                        icon: Icons.event_outlined,
                        label: completedAt,
                        isDark: isDark),
                ]),
              ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${score.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  passed
                      ? (isArabic ? 'ناجح ✓' : 'Passed ✓')
                      : (isArabic ? 'راسب ✗' : 'Failed ✗'),
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ]),
        ]),
      ),
    );
  }
}
