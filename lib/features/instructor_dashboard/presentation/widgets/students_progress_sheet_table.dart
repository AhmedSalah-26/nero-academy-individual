import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import 'students_progress_sheet_models.dart';
import 'students_progress_sheet_widgets.dart';

class StudentsProgressTable extends StatelessWidget {
  final List<StudentRow> filteredRows;
  final bool isDark;
  final bool isArabic;
  final String? sortColumn;
  final bool sortAscending;
  final Function(String) onSort;
  final Function(String) onCopy;

  const StudentsProgressTable({
    super.key,
    required this.filteredRows,
    required this.isDark,
    required this.isArabic,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onCopy,
  });

  Color _progressColor(double v) {
    if (v >= 80) return AppColors.success;
    if (v >= 50) return AppColors.info;
    if (v >= 25) return AppColors.warning;
    return AppColors.error;
  }

  Color _scoreColor(double v) {
    if (v >= 70) return AppColors.success;
    if (v >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatWatch(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  int? _getSortIndex() {
    const cols = ['name', 'courses', 'courses', 'progress', 'lessons', 'watch', 'quizzes', '', 'score', 'last', ''];
    final idx = cols.indexOf(sortColumn ?? '');
    return idx >= 0 ? idx : null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final cardColor = isDark ? AppColors.cardDark : AppColors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final headerBg = isDark ? AppColors.surfaceDark : const Color(0xFFF8F9FA);
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final mainColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(headerBg),
            dataRowColor: WidgetStateProperty.resolveWith((states) => cardColor),
            border: TableBorder.all(color: borderColor, borderRadius: BorderRadius.circular(12)),
            sortColumnIndex: _getSortIndex(),
            sortAscending: sortAscending,
            columns: [
              DataColumn(
                label: HeaderCell(isArabic ? 'الطالب' : 'Student', color: mainColor),
                onSort: (_, __) => onSort('name'),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'الكورسات' : 'Courses', color: mainColor, icon: Icons.school_outlined),
                numeric: true,
                onSort: (_, __) => onSort('courses'),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'مكتملة' : 'Done', color: mainColor, icon: Icons.check_circle_outline),
                numeric: true,
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'التقدم%' : 'Progress%', color: mainColor, icon: Icons.bar_chart),
                numeric: true,
                onSort: (_, __) => onSort('progress'),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'الدروس' : 'Lessons', color: mainColor, icon: Icons.menu_book_outlined),
                numeric: true,
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'وقت المشاهدة' : 'Watch Time', color: mainColor, icon: Icons.timer_outlined),
                onSort: (_, __) => onSort('watch'),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'الاختبارات' : 'Quizzes', color: mainColor, icon: Icons.quiz_outlined),
                numeric: true,
                onSort: (_, __) => onSort('quizzes'),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'ناجح/راسب' : 'P/F', color: mainColor),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'متوسط الاختبار' : 'Avg Score', color: mainColor),
                numeric: true,
                onSort: (_, __) => onSort('score'),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'آخر نشاط' : 'Last Activity', color: mainColor, icon: Icons.history_outlined),
                onSort: (_, __) => onSort('last'),
              ),
              DataColumn(
                label: HeaderCell(isArabic ? 'تاريخ الانضمام' : 'Joined', color: mainColor, icon: Icons.calendar_today_outlined),
              ),
            ],
            rows: filteredRows.map((r) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            backgroundImage: r.avatarUrl != null ? NetworkImage(r.avatarUrl!) : null,
                            child: r.avatarUrl == null
                                ? Text(
                                    r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mainColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (r.email != null)
                                  Text(r.email!, style: TextStyle(fontSize: 10, color: mutedColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => onCopy(r.email ?? r.name),
                  ),
                  DataCell(NumberCell(value: '${r.coursesCount}', color: AppColors.info)),
                  DataCell(NumberCell(value: '${r.completedCourses}', color: AppColors.success)),
                  DataCell(ProgressCell(progress: r.avgProgress, color: _progressColor(r.avgProgress))),
                  DataCell(NumberCell(value: '${r.completedLessons}/${r.totalLessons}', color: mutedColor, fontSize: 11)),
                  DataCell(Text(_formatWatch(r.watchSeconds), style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
                  DataCell(NumberCell(value: '${r.quizCount}', color: AppColors.warning)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${r.passedQuizzes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                        Text(' / ', style: TextStyle(color: mutedColor, fontSize: 12)),
                        Text('${r.failedQuizzes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                      ],
                    ),
                  ),
                  DataCell(r.quizCount == 0 ? Text('-', style: TextStyle(color: mutedColor)) : NumberCell(value: '${r.avgQuizScore.toStringAsFixed(0)}%', color: _scoreColor(r.avgQuizScore))),
                  DataCell(Text(r.lastActivity != null ? dateFormat.format(r.lastActivity!) : '-', style: TextStyle(fontSize: 11, color: mutedColor))),
                  DataCell(Text(r.joinedAt != null ? dateFormat.format(r.joinedAt!) : '-', style: TextStyle(fontSize: 11, color: mutedColor))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
