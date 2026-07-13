import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'students_progress_sheet_models.dart' show sanitizeString;

class _CourseData {
  final String courseId;
  final String titleAr;
  final String titleEn;
  final int completedLessons;
  final int totalLessons;
  final double realProgress;
  final List<_LessonData> lessons;

  const _CourseData({
    required this.courseId,
    required this.titleAr,
    required this.titleEn,
    required this.completedLessons,
    required this.totalLessons,
    required this.realProgress,
    required this.lessons,
  });
}

class _LessonData {
  final String titleAr;
  final String titleEn;
  final bool isCompleted;
  final int watchSeconds;
  final DateTime? completedAt;

  const _LessonData({
    required this.titleAr,
    required this.titleEn,
    required this.isCompleted,
    required this.watchSeconds,
    this.completedAt,
  });
}

class StudentLessonsProgressDialog extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentLessonsProgressDialog({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentLessonsProgressDialog> createState() =>
      _StudentLessonsProgressDialogState();
}

class _StudentLessonsProgressDialogState
    extends State<StudentLessonsProgressDialog> {
  bool _isLoading = true;
  String? _error;
  List<_CourseData> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;

      // 1. Fetch enrollments for this student (only courses by this instructor)
      final teacherId = client.auth.currentUser?.id;
      final enrollmentsRes = await client.from('enrollments').select('''
        course_id,
        courses!inner(id, title_ar, title_en, teacher_id)
      ''').eq('user_id', widget.studentId).eq('courses.teacher_id', teacherId!);

      final enrollmentsList =
          (enrollmentsRes as List).cast<Map<String, dynamic>>();
      if (enrollmentsList.isEmpty) {
        if (mounted) {
          setState(() {
            _courses = [];
            _isLoading = false;
          });
        }
        return;
      }

      final courseIds =
          enrollmentsList.map((e) => e['course_id'] as String).toList();

      // 2. Fetch ALL current lessons for those courses (source of truth for total)
      final lessonsRes = await client
          .from('lessons')
          .select('id, title_ar, title_en, course_id, sort_order')
          .inFilter('course_id', courseIds)
          .order('sort_order');

      final allLessons = (lessonsRes as List).cast<Map<String, dynamic>>();

      // 3. Fetch this student's lesson_progress records
      final progressRes = await client.from('lesson_progress').select('''
        lesson_id, is_completed, watch_time, completed_at, course_id
      ''').eq('user_id', widget.studentId).inFilter('course_id', courseIds);

      final progressList = (progressRes as List).cast<Map<String, dynamic>>();
      final progressMap = {
        for (final p in progressList) p['lesson_id'] as String: p
      };

      // 4. Build per-course data and collect updates
      final List<Map<String, dynamic>> progressUpdates = [];

      final courses = enrollmentsList.map((enrollment) {
        final course = enrollment['courses'] as Map<String, dynamic>;
        final courseId = enrollment['course_id'] as String;

        final courseLessons =
            allLessons.where((l) => l['course_id'] == courseId).toList();
        final totalLessons = courseLessons.length;

        final lessonDataList = courseLessons.map((lesson) {
          final lessonId = lesson['id'] as String;
          final prog = progressMap[lessonId];
          return _LessonData(
            titleAr: sanitizeString(lesson['title_ar'] as String? ?? ''),
            titleEn: sanitizeString(lesson['title_en'] as String? ?? ''),
            isCompleted: prog?['is_completed'] as bool? ?? false,
            watchSeconds: prog?['watch_time'] as int? ?? 0,
            completedAt: prog?['completed_at'] != null
                ? DateTime.tryParse(prog!['completed_at'].toString())
                : null,
          );
        }).toList();

        final completedCount =
            lessonDataList.where((l) => l.isCompleted).length;
        final realProgress =
            totalLessons > 0 ? (completedCount / totalLessons) * 100 : 0.0;
        final isCompleted = totalLessons > 0 && completedCount == totalLessons;

        // Queue update for this enrollment
        progressUpdates.add({
          'courseId': courseId,
          'realProgress': realProgress,
          'isCompleted': isCompleted,
        });

        return _CourseData(
          courseId: courseId,
          titleAr: sanitizeString(course['title_ar'] as String? ?? ''),
          titleEn: sanitizeString(course['title_en'] as String? ?? ''),
          completedLessons: completedCount,
          totalLessons: totalLessons,
          realProgress: realProgress,
          lessons: lessonDataList,
        );
      }).toList();

      // 5. Update stored progress_percentage in enrollments (fire-and-forget)
      for (final update in progressUpdates) {
        client
            .from('enrollments')
            .update({
              'progress_percentage':
                  (update['realProgress'] as double).roundToDouble(),
              if (update['isCompleted'] as bool) 'status': 'completed',
              if (update['isCompleted'] as bool)
                'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', widget.studentId)
            .eq('course_id', update['courseId'] as String)
            .then((_) {}, onError: (_) {});
      }

      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          children: [
            _buildHeader(isArabic, isDark),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center))
                      : _courses.isEmpty
                          ? Center(
                              child: Text(isArabic
                                  ? 'لا توجد كورسات'
                                  : 'No courses found'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _courses.length,
                              itemBuilder: (ctx, i) => _buildCourseCard(
                                  _courses[i], isArabic, isDark),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تقدم الدروس' : 'Lessons Progress',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.studentName,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.grey400 : AppColors.grey500),
                ),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(_CourseData course, bool isArabic, bool isDark) {
    final title = isArabic ? course.titleAr : course.titleEn;
    final progress = course.realProgress;
    final color = progress >= 80
        ? AppColors.success
        : progress >= 50
            ? AppColors.info
            : progress >= 25
                ? AppColors.warning
                : AppColors.error;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${course.completedLessons}/${course.totalLessons}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
      children: course.lessons
          .map((l) => _buildLessonTile(l, isArabic, isDark))
          .toList(),
    );
  }

  Widget _buildLessonTile(_LessonData lesson, bool isArabic, bool isDark) {
    final title = isArabic ? lesson.titleAr : lesson.titleEn;
    final watchMin = lesson.watchSeconds ~/ 60;
    final dateFmt = DateFormat('MM/dd');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        children: [
          Icon(
            lesson.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 18,
            color: lesson.isCompleted
                ? AppColors.success
                : (isDark ? AppColors.grey600 : AppColors.grey400),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: lesson.isCompleted
                    ? null
                    : (isDark ? AppColors.grey400 : AppColors.grey500),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lesson.watchSeconds > 0) ...[
            const SizedBox(width: 6),
            Text('${watchMin}m',
                style: const TextStyle(fontSize: 11, color: AppColors.primary)),
          ],
          if (lesson.completedAt != null) ...[
            const SizedBox(width: 6),
            Text(dateFmt.format(lesson.completedAt!),
                style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.grey500 : AppColors.grey400)),
          ],
        ],
      ),
    );
  }
}
