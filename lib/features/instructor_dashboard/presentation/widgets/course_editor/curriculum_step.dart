import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';
import 'curriculum_section_card.dart';
import 'curriculum_dialogs.dart';

/// Curriculum Step - Sections and Lessons
class CurriculumStep extends StatelessWidget {
  const CurriculumStep({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<CourseEditorCubit>();

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: state.sections.isEmpty
                  ? _buildEmptyState(context, cubit, isArabic, isDark)
                  : _buildSectionsList(context, cubit, state, isArabic, isDark),
            ),
            _buildBottomBar(context, cubit, state, isArabic, isDark),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CourseEditorCubit cubit,
      bool isArabic, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا توجد أقسام بعد' : 'No sections yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'أضف قسم لبدء إنشاء محتوى الكورس'
                : 'Add a section to start building your course',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => showAddSectionDialog(context, cubit, isArabic),
            icon: const Icon(Icons.add),
            label: Text(isArabic ? 'إضافة قسم' : 'Add Section'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList(BuildContext context, CourseEditorCubit cubit,
      CourseEditorState state, bool isArabic, bool isDark) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.sections.length,
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        // reorderSectionsAndSave → updates state locally + persists to database
        cubit.reorderSectionsAndSave(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final section = state.sections[index];
        return SectionCard(
          key: ValueKey(section.id ?? index),
          section: section,
          index: index,
          isArabic: isArabic,
          isDark: isDark,
          onEdit: () =>
              showEditSectionDialog(context, cubit, index, section, isArabic),
          onDelete: () => confirmDeleteSection(context, cubit, index, isArabic),
          onAddLesson: () =>
              showAddLessonDialog(context, cubit, index, isArabic),
          onEditLesson: (lessonIndex) => showEditLessonDialog(context, cubit,
              index, lessonIndex, section.lessons[lessonIndex], isArabic),
          onDeleteLesson: (lessonIndex) =>
              confirmDeleteLesson(context, cubit, index, lessonIndex, isArabic),
          // reorderLessonsAndSave → updates state locally + persists to database
          onReorderLessons: (oldIndex, newIndex) =>
              cubit.reorderLessonsAndSave(index, oldIndex, newIndex),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, CourseEditorCubit cubit,
      CourseEditorState state, bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              if (!state.isEditing)
                OutlinedButton.icon(
                  onPressed: () => cubit.setStep(0),
                  icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
                  label: Text(isArabic ? 'السابق' : 'Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                )
              else
                const SizedBox(),
              const SizedBox(width: 8),
              // Right Side Actions
              Row(
                children: [
                  // Add Section Button
                  ElevatedButton.icon(
                    onPressed: () =>
                        showAddSectionDialog(context, cubit, isArabic),
                    icon: const Icon(Icons.add),
                    label: Text(isArabic ? 'إضافة قسم' : 'Add Section'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      elevation: 2,
                    ),
                  ),
                  if (!state.isEditing) ...[
                    const SizedBox(width: 8),
                    // Next Button
                    ElevatedButton(
                      onPressed: () => cubit.setStep(2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isArabic ? 'التالي' : 'Next'),
                          const SizedBox(width: 8),
                          Icon(isArabic
                              ? Icons.arrow_back
                              : Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
