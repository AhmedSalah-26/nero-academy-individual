import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/base/base_state.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/lesson_history_service.dart';
import '../../../../core/services/video_player_notifier_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/lesson_progress_entity.dart';
import '../../domain/usecases/get_course_content_usecase.dart';
import '../../domain/usecases/get_lesson_usecase.dart';
import '../../domain/usecases/update_lesson_progress_usecase.dart';
import '../../domain/usecases/mark_lesson_complete_usecase.dart';
import '../../domain/usecases/add_bookmark_usecase.dart';
import '../../domain/usecases/delete_bookmark_usecase.dart';
import '../../domain/repositories/course_player_repository.dart';
import 'course_player_state.dart';

/// Course Player Cubit
class CoursePlayerCubit extends Cubit<CoursePlayerState> {
  final GetCourseContentUseCase getCourseContentUseCase;
  final GetLessonUseCase getLessonUseCase;
  final UpdateLessonProgressUseCase updateLessonProgressUseCase;
  final MarkLessonCompleteUseCase markLessonCompleteUseCase;
  final AddBookmarkUseCase addBookmarkUseCase;
  final DeleteBookmarkUseCase deleteBookmarkUseCase;
  final CoursePlayerRepository repository;

  bool _isClosed = false;

  CoursePlayerCubit({
    required this.getCourseContentUseCase,
    required this.getLessonUseCase,
    required this.updateLessonProgressUseCase,
    required this.markLessonCompleteUseCase,
    required this.addBookmarkUseCase,
    required this.deleteBookmarkUseCase,
    required this.repository,
  }) : super(const CoursePlayerState());

  @override
  Future<void> close() {
    _isClosed = true;
    return super.close();
  }

  /// Safe emit that checks if cubit is closed
  void _safeEmit(CoursePlayerState newState) {
    if (!_isClosed) {
      emit(newState);
    }
  }

  /// Initialize course player
  Future<void> initialize({
    required String courseId,
    required String enrollmentId,
    required String courseTitle,
    String? initialLessonId,
    String? instructorId,
    String? instructorName,
    String? instructorAvatar,
  }) async {
    AppLogger.i('🎬 [CoursePlayer] Initializing: $courseId');
    _safeEmit(state.copyWith(
      status: StateStatus.loading,
      courseId: courseId,
      enrollmentId: enrollmentId,
      courseTitle: courseTitle,
      instructorId: instructorId,
      instructorName: instructorName,
      instructorAvatar: instructorAvatar,
    ));

    final result = await getCourseContentUseCase(
      GetCourseContentParams(courseId: courseId, enrollmentId: enrollmentId),
    );

    result.fold(
      (failure) {
        AppLogger.e(
            '[CoursePlayer] Failed to load content: ${failure.message}');
        _safeEmit(state.copyWith(status: StateStatus.error, failure: failure));
      },
      (sections) async {
        AppLogger.success('[CoursePlayer] Loaded ${sections.length} sections');

        // Load all lesson progress first to find first incomplete lesson
        final progressMap = await _fetchAllLessonProgress(enrollmentId);

        // Find initial lesson
        LessonEntity? initialLesson;
        if (initialLessonId != null) {
          for (final section in sections) {
            final lesson =
                section.lessons.where((l) => l.id == initialLessonId);
            if (lesson.isNotEmpty) {
              initialLesson = lesson.first;
              break;
            }
          }
        }

        // If no specific lesson, find first incomplete lesson
        if (initialLesson == null) {
          for (final section in sections) {
            for (final lesson in section.lessons) {
              final progress = progressMap[lesson.id];
              if (progress == null || !progress.isCompleted) {
                initialLesson = lesson;
                break;
              }
            }
            if (initialLesson != null) break;
          }
        }

        // Default to first lesson if all completed or no lessons
        initialLesson ??=
            sections.isNotEmpty && sections.first.lessons.isNotEmpty
                ? sections.first.lessons.first
                : null;

        _safeEmit(state.copyWith(
          status: StateStatus.success,
          sections: sections,
          currentLesson: initialLesson,
          progressMap: progressMap,
        ));

        // Load course attachments
        await _loadCourseAttachments(courseId);

        // Load lesson details if we have one
        if (initialLesson != null) {
          await _loadLessonDetails(initialLesson.id);
        }
      },
    );
  }

  /// Load course-level attachments
  Future<void> _loadCourseAttachments(String courseId) async {
    AppLogger.i('📎 [CoursePlayer] Loading course attachments...');
    final result = await repository.getCourseAttachments(courseId: courseId);
    result.fold(
      (failure) {
        AppLogger.e(
            '[CoursePlayer] Failed to load attachments: ${failure.message}');
        // Don't fail the whole initialization, just log the error
      },
      (attachments) {
        AppLogger.success(
            '[CoursePlayer] Loaded ${attachments.length} course attachments');
        _safeEmit(state.copyWith(courseAttachments: attachments));
      },
    );
  }

  /// Fetch all lesson progress and return as map
  Future<Map<String, LessonProgressEntity>> _fetchAllLessonProgress(
      String enrollmentId) async {
    final progressResult = await repository.getAllLessonProgress(
      enrollmentId: enrollmentId,
    );
    final progressMap = <String, LessonProgressEntity>{};
    progressResult.fold(
      (_) {},
      (progressList) {
        for (final progress in progressList) {
          progressMap[progress.lessonId] = progress;
        }
        AppLogger.i(
            '🎬 [CoursePlayer] Loaded ${progressList.length} lesson progress records');
      },
    );
    return progressMap;
  }

  /// Load lesson details
  Future<void> _loadLessonDetails(String lessonId) async {
    if (_isClosed) return;

    // Load attachments
    final attachmentsResult = await repository.getLessonAttachments(
      lessonId: lessonId,
    );
    attachmentsResult.fold(
      (_) {},
      (attachments) =>
          _safeEmit(state.copyWith(lessonAttachments: attachments)),
    );

    // Load progress
    if (state.enrollmentId != null && !_isClosed) {
      final progressResult = await repository.getLessonProgress(
        lessonId: lessonId,
        enrollmentId: state.enrollmentId!,
      );
      progressResult.fold(
        (_) {},
        (progress) => _safeEmit(state.copyWith(currentProgress: progress)),
      );

      // Check bookmark status
      if (!_isClosed) {
        AppLogger.i(
            '🔖 [CoursePlayer] Checking bookmark status for lesson: $lessonId');
        final bookmarkResult = await repository.isLessonBookmarked(
          lessonId: lessonId,
          enrollmentId: state.enrollmentId!,
        );
        bookmarkResult.fold(
          (failure) {
            AppLogger.e(
                '[CoursePlayer] Failed to check bookmark: ${failure.message}');
          },
          (isBookmarked) {
            AppLogger.i('🔖 [CoursePlayer] Bookmark status: $isBookmarked');
            _safeEmit(state.copyWith(isBookmarked: isBookmarked));
          },
        );
      }
    }
  }

  /// Select a lesson
  Future<void> selectLesson(LessonEntity lesson) async {
    if (_isClosed) return;
    AppLogger.i('🎬 [CoursePlayer] Selecting lesson: ${lesson.id}');

    // Dismiss the media notification / stop any background video
    try {
      sl<VideoPlayerNotifierService>().dismiss();
    } catch (_) {}

    // Load progress first to get last position
    LessonProgressEntity? progress;
    if (state.enrollmentId != null) {
      final progressResult = await repository.getLessonProgress(
        lessonId: lesson.id,
        enrollmentId: state.enrollmentId!,
      );
      progressResult.fold(
        (_) {},
        (p) => progress = p,
      );
    }

    _safeEmit(state.copyWith(
      currentLesson: lesson,
      currentProgress: progress,
      lessonAttachments: [],
      // Don't reset bookmark status here, let _loadLessonDetails handle it
    ));

    await _loadLessonDetails(lesson.id);

    // Save to history
    _saveToHistory(lesson, progress);
  }

  /// Save lesson to history
  void _saveToHistory(LessonEntity lesson, LessonProgressEntity? progress) {
    try {
      final historyService = sl<LessonHistoryService>();
      final historyItem = LessonHistoryItem(
        lessonId: lesson.id,
        lessonTitle: lesson.titleAr, // Use titleAr as default
        courseId: state.courseId ?? '',
        courseTitle: state.courseTitle ?? '',
        enrollmentId: state.enrollmentId ?? '',
        lastWatched: DateTime.now(),
        lastPosition: progress?.lastPosition,
        thumbnailUrl: null, // Lesson doesn't have thumbnail
        instructorId: state.instructorId,
        instructorName: state.instructorName,
        instructorAvatar: state.instructorAvatar,
      );
      historyService.addToHistory(historyItem);
      AppLogger.i('📚 [History] Saved lesson to history: ${lesson.titleAr}');
    } catch (e) {
      AppLogger.e('❌ [History] Failed to save to history', e);
    }
  }

  /// Go to next lesson (marks current as complete first)
  Future<void> nextLesson() async {
    // Mark current lesson as complete before moving to next
    if (state.currentLesson != null && state.enrollmentId != null) {
      if (!state.isLessonCompleted(state.currentLesson!.id)) {
        await markComplete(autoNext: false);
      }
    }

    if (state.hasNextLesson && state.nextLesson != null) {
      await selectLesson(state.nextLesson!);
    } else if (state.isLastLesson && !state.allLessonsCompleted) {
      // If on last lesson but not all lessons completed, go to first incomplete
      final firstIncomplete = state.firstIncompleteLesson;
      if (firstIncomplete != null) {
        await selectLesson(firstIncomplete);
      }
    }
  }

  /// Go to previous lesson
  Future<void> previousLesson() async {
    if (state.hasPreviousLesson && state.previousLesson != null) {
      await selectLesson(state.previousLesson!);
    }
  }

  /// Update video progress
  Future<void> updateProgress({
    required int watchedSeconds,
    required int lastPosition,
  }) async {
    if (state.currentLesson == null || state.enrollmentId == null) {
      return;
    }
    if (_isClosed) {
      return;
    }

    // Skip if already updating (but don't block)
    if (state.isUpdatingProgress) {
      return;
    }

    // Only log every 60 seconds to reduce overhead
    if (watchedSeconds % 60 == 0) {
      AppLogger.i(
          '⏱️ [CoursePlayer] Updating progress: $watchedSeconds seconds');
    }

    _safeEmit(state.copyWith(isUpdatingProgress: true));

    final result = await updateLessonProgressUseCase(
      UpdateLessonProgressParams(
        lessonId: state.currentLesson!.id,
        enrollmentId: state.enrollmentId!,
        watchedSeconds: watchedSeconds,
        lastPosition: lastPosition,
      ),
    );

    result.fold(
      (failure) {
        AppLogger.e('⏱️ [CoursePlayer] Update failed: ${failure.message}');
        _safeEmit(state.copyWith(isUpdatingProgress: false));
      },
      (progress) {
        final updatedMap =
            Map<String, LessonProgressEntity>.from(state.progressMap);
        updatedMap[state.currentLesson!.id] = progress;
        _safeEmit(state.copyWith(
          currentProgress: progress,
          progressMap: updatedMap,
          isUpdatingProgress: false,
        ));
      },
    );
  }

  /// Mark current lesson as complete
  Future<void> markComplete({bool autoNext = false}) async {
    if (state.currentLesson == null || state.enrollmentId == null) return;
    if (state.isMarkingComplete || _isClosed) return;

    // Check if already completed
    if (state.isLessonCompleted(state.currentLesson!.id)) {
      return;
    }

    AppLogger.i('🎬 [CoursePlayer] Marking lesson complete');
    _safeEmit(state.copyWith(isMarkingComplete: true));

    final result = await markLessonCompleteUseCase(
      MarkLessonCompleteParams(
        lessonId: state.currentLesson!.id,
        enrollmentId: state.enrollmentId!,
      ),
    );

    result.fold(
      (failure) {
        AppLogger.e(
            '[CoursePlayer] Failed to mark complete: ${failure.message}');
        _safeEmit(state.copyWith(isMarkingComplete: false));
      },
      (progress) {
        AppLogger.success('[CoursePlayer] Lesson marked complete');
        final updatedMap =
            Map<String, LessonProgressEntity>.from(state.progressMap);
        updatedMap[state.currentLesson!.id] = progress;
        _safeEmit(state.copyWith(
          currentProgress: progress,
          progressMap: updatedMap,
          isMarkingComplete: false,
        ));
      },
    );
  }

  /// Toggle bookmark
  Future<void> toggleBookmark() async {
    if (state.currentLesson == null || state.enrollmentId == null) {
      AppLogger.w(
          '[CoursePlayer] Cannot toggle bookmark - missing lesson or enrollment');
      return;
    }
    if (_isClosed) return;

    AppLogger.i(
        '🔖 [CoursePlayer] Toggling bookmark for lesson: ${state.currentLesson!.id}');

    if (state.isBookmarked) {
      // Find and delete bookmark
      AppLogger.i('🔖 [CoursePlayer] Removing bookmark...');
      final bookmarksResult = await repository.getBookmarks(
        enrollmentId: state.enrollmentId!,
      );

      final bookmarks = bookmarksResult.fold(
        (failure) {
          AppLogger.e(
              '[CoursePlayer] Failed to get bookmarks: ${failure.message}');
          return <dynamic>[];
        },
        (bookmarks) => bookmarks,
      );

      final bookmark = bookmarks.where(
        (b) => b.lessonId == state.currentLesson!.id,
      );

      if (bookmark.isNotEmpty) {
        final deleteResult = await deleteBookmarkUseCase(
          DeleteBookmarkParams(bookmarkId: bookmark.first.id),
        );
        deleteResult.fold(
          (failure) => AppLogger.e(
              '[CoursePlayer] Failed to delete bookmark: ${failure.message}'),
          (_) {
            AppLogger.success('[CoursePlayer] Bookmark removed');
            _safeEmit(state.copyWith(isBookmarked: false));
          },
        );
      }
    } else {
      // Add bookmark
      AppLogger.i('🔖 [CoursePlayer] Adding bookmark...');
      final result = await addBookmarkUseCase(
        AddBookmarkParams(
          lessonId: state.currentLesson!.id,
          enrollmentId: state.enrollmentId!,
        ),
      );
      result.fold(
        (failure) => AppLogger.e(
            '[CoursePlayer] Failed to add bookmark: ${failure.message}'),
        (_) {
          AppLogger.success('[CoursePlayer] Bookmark added');
          _safeEmit(state.copyWith(isBookmarked: true));
        },
      );
    }
  }

  /// Complete the entire course (mark last lesson complete + issue certificate)
  Future<bool> completeCourse() async {
    AppLogger.i('🎬 [CoursePlayer] completeCourse() called');
    AppLogger.i('🎬 [CoursePlayer] currentLesson: ${state.currentLesson?.id}');
    AppLogger.i('🎬 [CoursePlayer] enrollmentId: ${state.enrollmentId}');
    AppLogger.i('🎬 [CoursePlayer] courseId: ${state.courseId}');
    AppLogger.i(
        '🎬 [CoursePlayer] isMarkingComplete: ${state.isMarkingComplete}');

    if (state.currentLesson == null || state.enrollmentId == null) {
      AppLogger.e(
          '[CoursePlayer] Cannot complete - missing lesson or enrollment');
      return false;
    }
    if (state.isMarkingComplete) {
      AppLogger.w('[CoursePlayer] Already marking complete, skipping');
      return false;
    }

    AppLogger.i('🎬 [CoursePlayer] Completing course...');
    emit(state.copyWith(isMarkingComplete: true));

    final result = await markLessonCompleteUseCase(
      MarkLessonCompleteParams(
        lessonId: state.currentLesson!.id,
        enrollmentId: state.enrollmentId!,
      ),
    );

    return result.fold(
      (failure) {
        AppLogger.e(
            '[CoursePlayer] Failed to complete course: ${failure.message}');
        emit(state.copyWith(isMarkingComplete: false));
        return false;
      },
      (progress) async {
        AppLogger.success('[CoursePlayer] Course completed successfully!');
        final updatedMap =
            Map<String, LessonProgressEntity>.from(state.progressMap);
        updatedMap[state.currentLesson!.id] = progress;
        emit(state.copyWith(
          currentProgress: progress,
          progressMap: updatedMap,
          isMarkingComplete: false,
        ));

        return true;
      },
    );
  }

  /// Change tab
  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index));
  }
}
