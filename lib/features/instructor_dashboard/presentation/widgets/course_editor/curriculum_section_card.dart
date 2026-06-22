import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Section Card Widget with Reorderable Lessons
class SectionCard extends StatefulWidget {
  final SectionData section;
  final int index;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddLesson;
  final Function(int) onEditLesson;
  final Function(int) onDeleteLesson;
  final Function(int, int)? onReorderLessons;

  const SectionCard({
    super.key,
    required this.section,
    required this.index,
    required this.isArabic,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onAddLesson,
    required this.onEditLesson,
    required this.onDeleteLesson,
    this.onReorderLessons,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: widget.isDark ? AppColors.cardDark : AppColors.white,
      child: Column(
        children: [
          // Section Header
          Material(
            color: widget.isDark ? AppColors.surfaceDark : AppColors.grey50,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: widget.index,
                child: const Icon(Icons.drag_handle),
              ),
              title: Text(
                widget.isArabic
                    ? widget.section.titleAr
                    : widget.section.titleEn,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${widget.section.lessons.length} ${widget.isArabic ? 'درس' : 'lessons'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: widget.onEdit,
                    tooltip: widget.isArabic ? 'تعديل' : 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    onPressed: widget.onDelete,
                    tooltip: widget.isArabic ? 'حذف' : 'Delete',
                  ),
                ],
              ),
            ),
          ),
          // Lessons List
          if (widget.section.lessons.isNotEmpty)
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (widget.onReorderLessons != null) {
                  widget.onReorderLessons!(oldIndex, newIndex);
                }
              },
              children: widget.section.lessons.asMap().entries.map((entry) {
                final lessonIndex = entry.key;
                final lesson = entry.value;
                return LessonTile(
                  key: ValueKey(lesson.id ?? 'lesson_$lessonIndex'),
                  lesson: lesson,
                  lessonIndex: lessonIndex,
                  lessonNumber: lessonIndex + 1,
                  totalLessons: widget.section.lessons.length,
                  isArabic: widget.isArabic,
                  isDark: widget.isDark,
                  onEdit: () => widget.onEditLesson(lessonIndex),
                  onDelete: () => widget.onDeleteLesson(lessonIndex),
                );
              }).toList(),
            ),
          // Add Lesson Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: widget.onAddLesson,
              icon: const Icon(Icons.add),
              label: Text(widget.isArabic ? 'إضافة درس' : 'Add Lesson'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lesson Tile with Number and Drag Handle
class LessonTile extends StatelessWidget {
  final LessonData lesson;
  final int lessonIndex;
  final int lessonNumber;
  final int totalLessons;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.lessonIndex,
    required this.lessonNumber,
    required this.totalLessons,
    required this.isArabic,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: isDark ? AppColors.cardDark : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                ReorderableDragStartListener(
                  index: lessonIndex,
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(width: 8),
                // Lesson Number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$lessonNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Lesson Type Icon
                Icon(
                  _getLessonIcon(lesson.type),
                  size: 20,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ],
            ),
            title: Text(
              isArabic ? lesson.titleAr : lesson.titleEn,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  _getLessonTypeLabel(lesson.type, isArabic),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                if (lesson.isFree) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isArabic ? 'مجاني' : 'Free',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
                if (lesson.availableFrom != null ||
                    lesson.availableUntil != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isArabic ? 'مجدول' : 'Scheduled',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  onPressed: onEdit,
                  tooltip: isArabic ? 'تعديل' : 'Edit',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                  tooltip: isArabic ? 'حذف' : 'Delete',
                ),
              ],
            ),
          ),
        ));
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'article':
        return Icons.article_outlined;
      case 'document':
      case 'file':
        return Icons.insert_drive_file_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  String _getLessonTypeLabel(String type, bool isArabic) {
    switch (type) {
      case 'video':
        return isArabic ? 'فيديو' : 'Video';
      case 'article':
        return isArabic ? 'مقال' : 'Article';
      case 'document':
      case 'file':
        return isArabic ? 'مستند/ملف' : 'Document/File';
      case 'quiz':
        return isArabic ? 'اختبار' : 'Quiz';
      default:
        return type;
    }
  }
}
