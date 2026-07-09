// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/loading_state.dart';
import '../widgets/instructor_quizzes/download_helper.dart';
import '../widgets/students_progress_sheet_models.dart';
import '../widgets/students_progress_sheet_widgets.dart';
import '../widgets/students_progress_sheet_table.dart';
import '../widgets/students_progress_sheet_attempts.dart';
import '../widgets/students_progress_sheet_lessons.dart';

class StudentsProgressSheetScreen extends StatefulWidget {
  final String? courseId;
  final String? courseTitle;

  const StudentsProgressSheetScreen({
    super.key,
    this.courseId,
    this.courseTitle,
  });

  @override
  State<StudentsProgressSheetScreen> createState() =>
      _StudentsProgressSheetScreenState();
}

class _StudentsProgressSheetScreenState
    extends State<StudentsProgressSheetScreen> {
  bool _isLoading = true;
  String? _error;
  List<StudentRow> _rows = [];
  List<StudentRow> _filtered = [];
  String _searchQuery = '';
  String? _sortColumn;
  bool _sortAscending = true;
  final _dateFormat = DateFormat('yyyy/MM/dd');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Not logged in');

      var query = client.from('enrollments').select('''
        id, enrolled_at, last_accessed_at, completed_at, progress_percentage, status, user_id,
        profiles!enrollments_user_id_fkey(id, name, email, phone, avatar_url, created_at, is_active),
        courses!inner(id, title_ar, title_en, total_lessons, instructor_id)
      ''').eq('courses.instructor_id', currentUserId);

      if (widget.courseId != null) {
        query = query.eq('course_id', widget.courseId!);
      }

      final data = await query.order('enrolled_at', ascending: false);
      final studentIds = <String>{};
      for (final item in data as List) {
        final profile = item['profiles'] as Map?;
        if (profile != null) studentIds.add(profile['id'] as String? ?? '');
      }

      Map<String, List<Map<String, dynamic>>> quizByStudent = {};
      if (studentIds.isNotEmpty) {
        final quizData = await client
            .from('quiz_attempts')
            .select('user_id, score, passed, quizzes!inner(courses!inner(instructor_id))')
            .eq('quizzes.courses.instructor_id', currentUserId)
            .inFilter('user_id', studentIds.toList());
        for (final q in quizData as List) {
          final uid = q['user_id'] as String? ?? '';
          quizByStudent.putIfAbsent(uid, () => []).add(q as Map<String, dynamic>);
        }
      }

      final Map<String, StudentRowBuilder> builders = {};
      for (final item in data as List) {
        final profile = item['profiles'] as Map<String, dynamic>? ?? {};
        final course = item['courses'] as Map<String, dynamic>? ?? {};
        final uid = profile['id'] as String? ?? '';
        if (uid.isEmpty) continue;
        builders.putIfAbsent(uid, () => StudentRowBuilder(uid, profile));
        builders[uid]!.addEnrollment(item, course);
      }

      final rows = builders.values.map((b) => b.build(quizByStudent[b.uid] ?? [])).toList();

      if (mounted) {
        setState(() {
          _rows = rows;
          _filtered = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_rows)
          : _rows.where((r) => r.name.toLowerCase().contains(q) || (r.email?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  void _sort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _filtered.sort((a, b) {
        int cmp;
        switch (column) {
          case 'name': cmp = a.name.compareTo(b.name); break;
          case 'courses': cmp = a.coursesCount.compareTo(b.coursesCount); break;
          case 'progress': cmp = a.avgProgress.compareTo(b.avgProgress); break;
          case 'lessons': cmp = a.completedLessons.compareTo(b.completedLessons); break;
          case 'watch': cmp = a.watchSeconds.compareTo(b.watchSeconds); break;
          case 'quizzes': cmp = a.quizCount.compareTo(b.quizCount); break;
          case 'score': cmp = a.avgQuizScore.compareTo(b.avgQuizScore); break;
          case 'last': cmp = (a.lastActivity ?? DateTime(2000)).compareTo(b.lastActivity ?? DateTime(2000)); break;
          default: cmp = 0;
        }
        return _sortAscending ? cmp : -cmp;
      });
    });
  }

  void _exportCsv(bool isArabic) {
    final buffer = StringBuffer()..write('\uFEFF');
    buffer.writeln(isArabic
        ? 'م,الاسم,البريد,الهاتف,الكورسات,الكورسات المكتملة,التقدم %,الدروس المكتملة,إجمالي الدروس,وقت المشاهدة,الاختبارات,ناجح,راسب,متوسط الدرجات,آخر نشاط,تاريخ الانضمام'
        : '#,Name,Email,Phone,Courses,Completed Courses,Progress %,Completed Lessons,Total Lessons,Watch Time,Quizzes,Passed,Failed,Avg Score,Last Activity,Joined');

    for (int i = 0; i < _filtered.length; i++) {
      final r = _filtered[i];
      final watchStr = '${r.watchSeconds ~/ 3600}h ${(r.watchSeconds % 3600) ~/ 60}m';
      buffer.writeln(
        '${i + 1},"${r.name}","${r.email ?? '-'}","${r.phone ?? '-'}",'
        '${r.coursesCount},${r.completedCourses},${r.avgProgress.toStringAsFixed(1)},'
        '${r.completedLessons},${r.totalLessons},"$watchStr",${r.quizCount},${r.passedQuizzes},'
        '${r.failedQuizzes},${r.avgQuizScore.toStringAsFixed(1)},'
        '"${r.lastActivity != null ? _dateFormat.format(r.lastActivity!) : '-'}","${r.joinedAt != null ? _dateFormat.format(r.joinedAt!) : '-'}"',
      );
    }
    _saveAndShare(buffer.toString(), 'students_progress_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv', isArabic);
  }

  Future<void> _saveAndShare(String content, String fileName, bool isArabic) async {
    try {
      if (kIsWeb) {
        downloadFile(content, fileName);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'تم التصدير بنجاح' : 'Exported successfully'),
        ));
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(content, flush: true);
        final xFile = XFile(file.path, mimeType: 'text/csv');
        await Share.shareXFiles(
          [xFile],
          text: isArabic ? 'تقرير تقدم الطلاب' : 'Students Progress Report',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArabic ? 'جدول تقدم الطلاب' : 'Students Progress Sheet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (widget.courseTitle != null) Text(widget.courseTitle!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _filtered.isNotEmpty)
            IconButton(onPressed: () => _exportCsv(isArabic), icon: const Icon(Icons.table_chart_outlined), tooltip: isArabic ? 'تصدير CSV' : 'Export CSV'),
          IconButton(onPressed: _isLoading ? null : _loadData, icon: const Icon(Icons.refresh), tooltip: isArabic ? 'تحديث' : 'Refresh'),
        ],
      ),
      body: _isLoading
          ? const AppLoadingState()
          : _error != null
              ? _buildError(isArabic)
              : Column(
                  children: [
                    _buildSearchAndStats(isDark, isArabic),
                    Expanded(
                      child: _filtered.isEmpty
                          ? _buildEmpty(isArabic)
                          : StudentsProgressTable(
                              filteredRows: _filtered,
                              isDark: isDark,
                              isArabic: isArabic,
                              sortColumn: _sortColumn,
                              sortAscending: _sortAscending,
                              onSort: _sort,
                              onCopy: (val) {
                                Clipboard.setData(ClipboardData(text: val));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied: $val'), duration: const Duration(seconds: 1)));
                              },
                              onQuizAttemptsTap: (student) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => StudentAttemptsDialog(
                                    studentId: student.uid,
                                    studentName: student.name,
                                    studentEmail: student.email,
                                    studentPhone: student.phone,
                                  ),
                                );
                              },
                              onLessonProgressTap: (student) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => StudentLessonsProgressDialog(
                                    studentId: student.uid,
                                    studentName: student.name,
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError(bool isArabic) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
      const SizedBox(height: 16),
      Text(_error ?? '', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadData, child: Text(isArabic ? 'إعادة المحاولة' : 'Retry')),
    ]));
  }

  Widget _buildEmpty(bool isArabic) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people_outlined, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text(isArabic ? 'لا يوجد طلاب' : 'No students found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
    ]));
  }

  Widget _buildSearchAndStats(bool isDark, bool isArabic) {
    final avgProgress = _rows.isEmpty ? 0.0 : _rows.map((r) => r.avgProgress).reduce((a, b) => a + b) / _rows.length;
    final totalQuizzes = _rows.fold<int>(0, (sum, r) => sum + r.quizCount);

    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SheetStatChip(icon: Icons.people, value: '${_rows.length}', label: isArabic ? 'طالب' : 'Students', color: AppColors.info),
            const SizedBox(width: 12),
            SheetStatChip(icon: Icons.trending_up, value: '${avgProgress.toStringAsFixed(0)}%', label: isArabic ? 'متوسط التقدم' : 'Avg Progress', color: AppColors.success),
            const SizedBox(width: 12),
            SheetStatChip(icon: Icons.quiz, value: '$totalQuizzes', label: isArabic ? 'محاولة اختبار' : 'Quiz Attempts', color: AppColors.warning),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: isArabic ? 'بحث باسم الطالب أو الإيميل...' : 'Search by name or email...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              filled: true,
              fillColor: isDark ? AppColors.backgroundDark : AppColors.grey50,
            ),
            onChanged: (v) { _searchQuery = v; _applyFilter(); },
          ),
        ),
      ]),
    );
  }
}
