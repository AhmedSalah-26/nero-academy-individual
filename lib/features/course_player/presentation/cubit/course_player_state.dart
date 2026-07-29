import 'package:equatable/equatable.dart';
import '../../../../core/base/base_state.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/lesson_progress_entity.dart';
import '../../domain/entities/attachment_entity.dart';

/// Course Player State
class CoursePlayerState extends Equatable {
  final StateStatus status;
  final Failure? failure;
  final String? courseId;
  final String? enrollmentId;
  final String? courseTitle;
  final String? instructorId;
  final String? instructorName;
  final String? instructorAvatar;
  final List<SectionEntity> sections;
  final LessonEntity? currentLesson;
  final LessonProgressEntity? currentProgress;
  final List<AttachmentEntity> lessonAttachments;
  final List<AttachmentEntity> courseAttachments;
  final CourseGroupLinks groupLinks;
  final Map<String, LessonProgressEntity> progressMap;
  final Set<String> incompleteQuizLessonIds;
  final int currentTabIndex;
  final bool isBookmarked;
  final bool isMarkingComplete;
  final bool isUpdatingProgress;

  const CoursePlayerState({
    this.status = StateStatus.initial,
    this.failure,
    this.courseId,
    this.enrollmentId,
    this.courseTitle,
    this.instructorId,
    this.instructorName,
    this.instructorAvatar,
    this.sections = const [],
    this.currentLesson,
    this.currentProgress,
    this.lessonAttachments = const [],
    this.courseAttachments = const [],
    this.groupLinks = const CourseGroupLinks(),
    this.progressMap = const {},
    this.incompleteQuizLessonIds = const {},
    this.currentTabIndex = 0,
    this.isBookmarked = false,
    this.isMarkingComplete = false,
    this.isUpdatingProgress = false,
  });

  bool get isLoading => status == StateStatus.loading;
  bool get isError => status == StateStatus.error;
  bool get isSuccess => status == StateStatus.success;
  String? get errorMessage => failure?.message;

  /// Get all lessons from all sections
  List<LessonEntity> get allLessons {
    return sections.expand((s) => s.lessons).toList();
  }

  /// Get current lesson index
  int get currentLessonIndex {
    if (currentLesson == null) return -1;
    return allLessons.indexWhere((l) => l.id == currentLesson!.id);
  }

  /// Check if current lesson is the last lesson
  bool get isLastLesson {
    final index = currentLessonIndex;
    return index >= 0 && index == allLessons.length - 1;
  }

  /// Check if all lessons are completed (for showing complete course button)
  bool get allLessonsCompleted {
    final mandatoryLessons =
        allLessons.where((lesson) => lesson.isMandatory).toList();
    if (mandatoryLessons.isEmpty) return false;
    return mandatoryLessons.every(
      (lesson) =>
          isLessonCompleted(lesson.id) &&
          !incompleteQuizLessonIds.contains(lesson.id),
    );
  }

  /// Show complete course button only when on last lesson and all lessons are completed
  bool get showCompleteCourseButton {
    return isLastLesson && allLessonsCompleted;
  }

  /// Check if there's a next lesson
  bool get hasNextLesson {
    final index = currentLessonIndex;
    return index >= 0 && index < allLessons.length - 1;
  }

  /// Check if there's a previous lesson
  bool get hasPreviousLesson {
    final index = currentLessonIndex;
    return index > 0;
  }

  /// Get next lesson
  LessonEntity? get nextLesson {
    if (!hasNextLesson) return null;
    return allLessons[currentLessonIndex + 1];
  }

  /// Get previous lesson
  LessonEntity? get previousLesson {
    if (!hasPreviousLesson) return null;
    return allLessons[currentLessonIndex - 1];
  }

  /// Get completed lessons count
  int get completedLessonsCount {
    return allLessons
        .where(
          (lesson) => lesson.isMandatory && isLessonCompleted(lesson.id),
        )
        .length;
  }

  /// Get total lessons count
  int get totalLessonsCount =>
      allLessons.where((lesson) => lesson.isMandatory).length;

  /// Get overall progress percentage
  double get overallProgress {
    if (totalLessonsCount == 0) return 0;
    return (completedLessonsCount / totalLessonsCount) * 100;
  }

  /// Check if a lesson is completed
  bool isLessonCompleted(String lessonId) {
    return progressMap[lessonId]?.isCompleted ?? false;
  }

  /// A lesson opens only after all mandatory lessons before it are completed
  /// and every published quiz attached to those lessons is submitted.
  bool isLessonUnlocked(String lessonId) {
    final targetIndex =
        allLessons.indexWhere((lesson) => lesson.id == lessonId);
    if (targetIndex < 0) return false;

    for (var index = 0; index < targetIndex; index++) {
      final previousLesson = allLessons[index];
      if (!previousLesson.isMandatory) continue;
      if (!isLessonCompleted(previousLesson.id) ||
          incompleteQuizLessonIds.contains(previousLesson.id)) {
        return false;
      }
    }
    return true;
  }

  bool isSectionUnlocked(SectionEntity section) {
    if (section.lessons.isEmpty) return true;
    return isLessonUnlocked(section.lessons.first.id);
  }

  bool get canAdvanceFromCurrentLesson {
    final lesson = currentLesson;
    if (lesson == null) return false;
    final hasDestination =
        hasNextLesson || (isLastLesson && !allLessonsCompleted);
    return hasDestination && !incompleteQuizLessonIds.contains(lesson.id);
  }

  /// Get first incomplete lesson
  LessonEntity? get firstIncompleteLesson {
    return allLessons.firstWhere(
      (lesson) => !isLessonCompleted(lesson.id),
      orElse: () => allLessons.first,
    );
  }

  LessonEntity? get firstAccessibleIncompleteLesson {
    for (final lesson in allLessons) {
      if (isLessonUnlocked(lesson.id) && !isLessonCompleted(lesson.id)) {
        return lesson;
      }
    }
    for (final lesson in allLessons) {
      if (isLessonUnlocked(lesson.id)) return lesson;
    }
    return null;
  }

  /// Get section completed count
  int getSectionCompletedCount(SectionEntity section) {
    return section.lessons
        .where((l) => progressMap[l.id]?.isCompleted ?? false)
        .length;
  }

  CoursePlayerState copyWith({
    StateStatus? status,
    Failure? failure,
    String? courseId,
    String? enrollmentId,
    String? courseTitle,
    String? instructorId,
    String? instructorName,
    String? instructorAvatar,
    List<SectionEntity>? sections,
    LessonEntity? currentLesson,
    LessonProgressEntity? currentProgress,
    List<AttachmentEntity>? lessonAttachments,
    List<AttachmentEntity>? courseAttachments,
    CourseGroupLinks? groupLinks,
    Map<String, LessonProgressEntity>? progressMap,
    Set<String>? incompleteQuizLessonIds,
    int? currentTabIndex,
    bool? isBookmarked,
    bool? isMarkingComplete,
    bool? isUpdatingProgress,
    bool clearFailure = false,
  }) {
    return CoursePlayerState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
      courseId: courseId ?? this.courseId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      courseTitle: courseTitle ?? this.courseTitle,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      instructorAvatar: instructorAvatar ?? this.instructorAvatar,
      sections: sections ?? this.sections,
      currentLesson: currentLesson ?? this.currentLesson,
      currentProgress: currentProgress ?? this.currentProgress,
      lessonAttachments: lessonAttachments ?? this.lessonAttachments,
      courseAttachments: courseAttachments ?? this.courseAttachments,
      groupLinks: groupLinks ?? this.groupLinks,
      progressMap: progressMap ?? this.progressMap,
      incompleteQuizLessonIds:
          incompleteQuizLessonIds ?? this.incompleteQuizLessonIds,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isMarkingComplete: isMarkingComplete ?? this.isMarkingComplete,
      isUpdatingProgress: isUpdatingProgress ?? this.isUpdatingProgress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        failure,
        courseId,
        enrollmentId,
        courseTitle,
        instructorId,
        instructorName,
        instructorAvatar,
        sections,
        currentLesson,
        currentProgress,
        lessonAttachments,
        courseAttachments,
        groupLinks,
        progressMap,
        incompleteQuizLessonIds,
        currentTabIndex,
        isBookmarked,
        isMarkingComplete,
        isUpdatingProgress,
      ];
}
