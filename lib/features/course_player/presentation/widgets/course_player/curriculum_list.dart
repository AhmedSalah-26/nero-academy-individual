import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/shared_widgets/empty_state.dart';
import '../../../domain/entities/section_entity.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../../../../quizzes/domain/entities/quiz_entity.dart';
import 'section_header.dart';
import 'lesson_item.dart';

/// Curriculum List Widget
class CurriculumList extends StatelessWidget {
  final List<SectionEntity> sections;
  final LessonEntity? currentLesson;
  final Map<String, bool> completedLessons;
  final List<QuizEntity> quizzes;
  final bool isDark;
  final ValueChanged<LessonEntity> onLessonTap;
  final bool Function(String lessonId) isLessonCompleted;
  final int Function(SectionEntity section) getSectionCompletedCount;

  const CurriculumList({
    super.key,
    required this.sections,
    this.currentLesson,
    required this.completedLessons,
    this.quizzes = const [],
    required this.isDark,
    required this.onLessonTap,
    required this.isLessonCompleted,
    required this.getSectionCompletedCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalLessons = _calculateTotalLessons();

    if (sections.isEmpty || totalLessons == 0) {
      return const Center(
        child: EmptyState(
          type: EmptyStateType.lessons,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE8DDF7),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _calculateItemCount(),
              itemBuilder: (context, index) {
                return _buildItem(index, totalLessons);
              },
            ),
          ),
        ),
      ),
    );
  }

  int _calculateItemCount() {
    int count = 0;
    for (final section in sections) {
      count++; // Section header
      count += section.lessons.length; // Lessons
    }
    return count;
  }

  int _calculateTotalLessons() {
    return sections.fold<int>(
      0,
      (total, section) => total + section.lessons.length,
    );
  }

  Set<String> _lessonIdsWithQuizzes() {
    return quizzes
        .map((quiz) => quiz.lessonId)
        .whereType<String>()
        .where((lessonId) => lessonId.trim().isNotEmpty)
        .toSet();
  }

  int? _currentLessonNumber() {
    if (currentLesson == null) return null;

    int lessonNumber = 0;
    for (final section in sections) {
      for (final lesson in section.lessons) {
        lessonNumber++;
        if (lesson.id == currentLesson!.id) {
          return lessonNumber;
        }
      }
    }

    return null;
  }

  String? _lessonProgressLabel(int totalLessons) {
    final currentNumber = _currentLessonNumber();
    if (currentNumber == null || totalLessons == 0) return null;

    return 'محاضرة رقم $currentNumber من $totalLessons';
  }

  Widget _buildItem(int index, int totalLessons) {
    int currentIndex = 0;
    int globalLessonNumber = 0;
    final lessonProgressLabel = _lessonProgressLabel(totalLessons);
    final lessonIdsWithQuizzes = _lessonIdsWithQuizzes();

    // First, calculate the global lesson number up to this index
    for (int sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];

      // Section header
      if (currentIndex == index) {
        return SectionHeader(
          section: section,
          sectionIndex: sectionIndex,
          completedCount: getSectionCompletedCount(section),
          isDark: isDark,
          showDivider: sectionIndex > 0,
          lessonProgressLabel: lessonProgressLabel,
        );
      }
      currentIndex++;

      // Lessons
      for (int lessonIndex = 0;
          lessonIndex < section.lessons.length;
          lessonIndex++) {
        globalLessonNumber++;
        if (currentIndex == index) {
          final lesson = section.lessons[lessonIndex];
          final isCurrentLesson = currentLesson?.id == lesson.id;
          final isCompleted = isLessonCompleted(lesson.id);

          // Determine if lesson is locked
          // For now, only lock if not preview and not enrolled
          final isLocked = !lesson.isPreview && !lesson.isPublished;

          return LessonItem(
            lesson: lesson,
            lessonNumber: globalLessonNumber,
            isCurrentLesson: isCurrentLesson,
            isCompleted: isCompleted,
            isLocked: isLocked,
            isDark: isDark,
            hasQuiz: lessonIdsWithQuizzes.contains(lesson.id),
            onTap: () => onLessonTap(lesson),
          );
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }
}
