import 'package:flutter_test/flutter_test.dart';
import 'package:lms_platform/features/course_player/domain/entities/lesson_entity.dart';
import 'package:lms_platform/features/course_player/domain/entities/lesson_progress_entity.dart';
import 'package:lms_platform/features/course_player/domain/entities/section_entity.dart';
import 'package:lms_platform/features/course_player/presentation/cubit/course_player_state.dart';

void main() {
  group('CoursePlayerState learning sequence', () {
    final firstLesson = _lesson('lesson-1', 'section-1', 0);
    final secondLesson = _lesson('lesson-2', 'section-1', 1);
    final nextSectionLesson = _lesson('lesson-3', 'section-2', 0);
    final sections = [
      _section('section-1', 0, [firstLesson, secondLesson]),
      _section('section-2', 1, [nextSectionLesson]),
    ];

    test('locks later lessons and sections until previous lessons finish', () {
      final initial = CoursePlayerState(sections: sections);

      expect(initial.isLessonUnlocked(firstLesson.id), isTrue);
      expect(initial.isLessonUnlocked(secondLesson.id), isFalse);
      expect(initial.isSectionUnlocked(sections.last), isFalse);

      final firstCompleted = initial.copyWith(
        progressMap: {
          firstLesson.id: _progress(firstLesson.id),
        },
      );

      expect(firstCompleted.isLessonUnlocked(secondLesson.id), isTrue);
      expect(firstCompleted.isLessonUnlocked(nextSectionLesson.id), isFalse);
    });

    test('requires every quiz on previous lessons to be submitted', () {
      final state = CoursePlayerState(
        sections: sections,
        progressMap: {
          firstLesson.id: _progress(firstLesson.id),
        },
        incompleteQuizLessonIds: {firstLesson.id},
      );

      expect(state.isLessonUnlocked(secondLesson.id), isFalse);
      expect(state.allLessonsCompleted, isFalse);
      expect(
        state.copyWith(incompleteQuizLessonIds: const {}).isLessonUnlocked(
            secondLesson.id),
        isTrue,
      );
    });

    test('progress uses the current mandatory lesson count', () {
      final state = CoursePlayerState(
        sections: sections,
        progressMap: {
          firstLesson.id: _progress(firstLesson.id),
        },
      );

      expect(state.completedLessonsCount, 1);
      expect(state.totalLessonsCount, 3);
      expect(state.overallProgress, closeTo(33.333, 0.01));
    });
  });
}

LessonEntity _lesson(String id, String sectionId, int sortOrder) {
  return LessonEntity(
    id: id,
    sectionId: sectionId,
    titleAr: id,
    type: LessonType.video,
    sortOrder: sortOrder,
  );
}

SectionEntity _section(
  String id,
  int sortOrder,
  List<LessonEntity> lessons,
) {
  return SectionEntity(
    id: id,
    courseId: 'course-1',
    titleAr: id,
    sortOrder: sortOrder,
    lessons: lessons,
  );
}

LessonProgressEntity _progress(String lessonId) {
  return LessonProgressEntity(
    id: 'progress-$lessonId',
    lessonId: lessonId,
    enrollmentId: 'enrollment-1',
    isCompleted: true,
  );
}
