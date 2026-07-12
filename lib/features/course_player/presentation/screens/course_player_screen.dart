import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/back_button.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/screen_protection_service.dart';
import '../../../../core/services/video_player_notifier_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../quizzes/domain/entities/quiz_entity.dart';
import '../../../quizzes/domain/repositories/quizzes_repository.dart';
import '../cubit/course_player_cubit.dart';
import '../cubit/course_player_state.dart';
import '../../domain/entities/lesson_entity.dart';
import '../widgets/course_player/video_player_section.dart';
import '../widgets/course_player/lesson_header.dart';
import '../widgets/course_player/content_tabs.dart';
import '../widgets/course_player/curriculum_list.dart';
import '../widgets/course_player/bottom_action_bar.dart';
import '../widgets/course_player/notes_sheet.dart';
import '../widgets/course_player/bookmarks_sheet.dart';
import '../widgets/course_player/qa_section.dart';
import '../widgets/course_player/quizzes_section.dart';
import '../widgets/course_player/rating_section.dart';
import '../widgets/course_player/attachments_sheet.dart';
import '../widgets/course_player/announcements_sheet.dart';
import '../widgets/course_player/player_states.dart';
import '../widgets/course_player/more_tab.dart';

/// Course Player Screen
class CoursePlayerScreen extends StatefulWidget {
  final String courseId;
  final String enrollmentId;
  final String courseTitle;
  final String? initialLessonId;
  final String? instructorId;
  final String? instructorName;
  final String? instructorAvatar;

  const CoursePlayerScreen({
    super.key,
    required this.courseId,
    required this.enrollmentId,
    required this.courseTitle,
    this.initialLessonId,
    this.instructorId,
    this.instructorName,
    this.instructorAvatar,
  });

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen>
    with WidgetsBindingObserver, RouteAware {
  bool _isPlaying = false;
  int _currentPosition = 0;
  final int _totalDuration = 765;
  Timer? _progressTimer;
  // Persistent controller so tab changes don't reset scroll to top
  final ScrollController _playerScrollController = ScrollController();
  late final Future<List<QuizEntity>> _courseQuizzesFuture;

  @override
  void initState() {
    super.initState();
    _courseQuizzesFuture = _fetchCourseQuizzes();
    WidgetsBinding.instance.addObserver(this);
    // Prevent screen recording while watching videos
    ScreenProtectionService.enable();
    // Delay initialization slightly to allow smooth transition
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initializePlayer();
      }
    });
    _startProgressTimer();
    di.sl<VideoPlayerNotifierService>().setPlayerScreenActive(true);
  }

  Future<List<QuizEntity>> _fetchCourseQuizzes() async {
    final result = await di.sl<QuizzesRepository>().getCourseQuizzes(
          courseId: widget.courseId,
        );
    return result.fold(
      (failure) {
        AppLogger.e(
            '[Screen] Failed to load course quizzes: ${failure.message}');
        return <QuizEntity>[];
      },
      (quizzes) => quizzes,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    di.sl<VideoPlayerNotifierService>().setPlayerScreenActive(false);
    super.didPushNext();
  }

  @override
  void didPopNext() {
    di.sl<VideoPlayerNotifierService>().setPlayerScreenActive(true);
    super.didPopNext();
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer?.cancel();
    _progressTimer = null;
    _playerScrollController.dispose();
    // Save progress before disposing
    _saveProgress();
    // Re-allow screen recording when leaving player
    ScreenProtectionService.disable();
    di.sl<VideoPlayerNotifierService>().setPlayerScreenActive(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // App went to background - stop timer and save progress
      _progressTimer?.cancel();
      _progressTimer = null;
      setState(() => _isPlaying = false);
      _saveProgress();
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground - restart timer if needed
      if (_progressTimer == null) {
        _startProgressTimer();
      }
    }
  }

  void _startProgressTimer() {
    // Cancel any existing timer first
    _progressTimer?.cancel();
    // Update progress every 30 seconds while playing
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isPlaying && mounted) {
        _saveProgress();
      }
    });
  }

  void _saveProgress() {
    if (!mounted || !_isPlaying || _currentPosition <= 0) return;
    try {
      final cubit = context.read<CoursePlayerCubit>();
      if (cubit.state.currentLesson != null &&
          cubit.state.enrollmentId != null) {
        AppLogger.i(
            '⏱️ [Progress] Saving watch time: $_currentPosition seconds');
        cubit.updateProgress(
          watchedSeconds: _currentPosition,
          lastPosition: _currentPosition,
        );
      }
    } catch (_) {}
  }

  void _initializePlayer() {
    context.read<CoursePlayerCubit>().initialize(
          courseId: widget.courseId,
          enrollmentId: widget.enrollmentId,
          courseTitle: widget.courseTitle,
          initialLessonId: widget.initialLessonId,
          instructorId: widget.instructorId,
          instructorName: widget.instructorName,
          instructorAvatar: widget.instructorAvatar,
        );
  }

  Future<void> _onRefresh() async {
    AppLogger.i('[CoursePlayer] Pull-to-refresh triggered');
    try {
      final cubit = context.read<CoursePlayerCubit>();
      await cubit.initialize(
        courseId: widget.courseId,
        enrollmentId: widget.enrollmentId,
        courseTitle: widget.courseTitle,
        initialLessonId: cubit.state.currentLesson?.id ?? widget.initialLessonId,
        instructorId: widget.instructorId,
        instructorName: widget.instructorName,
        instructorAvatar: widget.instructorAvatar,
      );
    } catch (e) {
      AppLogger.e('[CoursePlayer] Refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigateBackFromPlayer();
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 78,
          leading: AppBackButton(
            onPressed: _handleBack,
          ),
          title: BlocBuilder<CoursePlayerCubit, CoursePlayerState>(
            builder: (context, state) {
              final isArabic =
                  Localizations.localeOf(context).languageCode == 'ar';
              String subtitle = '';
              final lessonTitle = state.currentLesson?.getTitle(
                isArabic ? 'ar' : 'en',
              );
              if (state.currentLesson != null) {
                for (final section in state.sections) {
                  if (section.lessons
                      .any((l) => l.id == state.currentLesson!.id)) {
                    subtitle =
                        isArabic ? section.titleAr : (section.titleEn ?? '');
                    break;
                  }
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.courseTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (lessonTitle != null && lessonTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lessonTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.primaryOnDark
                            : AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              );
            },
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<CoursePlayerCubit, CoursePlayerState>(
            builder: (context, state) {
              if (state.isLoading) {
                return PlayerLoadingState(isDark: isDark);
              }
              if (state.isError) {
                return PlayerErrorState(
                  isDark: isDark,
                  state: state,
                  onRetry: _initializePlayer,
                );
              }
              return _buildContent(state, isDark);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CoursePlayerState state, bool isDark) {
    // Calculate section and lesson indices
    int sectionIndex = 0, lessonIndex = 0;
    if (state.currentLesson != null) {
      for (int i = 0; i < state.sections.length; i++) {
        for (int j = 0; j < state.sections[i].lessons.length; j++) {
          if (state.sections[i].lessons[j].id == state.currentLesson!.id) {
            sectionIndex = i;
            lessonIndex = j;
            break;
          }
        }
      }
    }

    // Like the Home screen: video+header collapse on scroll, tabs stick at top
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            displacement: 60,
            child: CustomScrollView(
              // Persistent controller: keeps scroll position when tabs change
              controller: _playerScrollController,
              // Must be scrollable even when content fits screen for pull-to-refresh
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Collapsible: video player + lesson header ────────────
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (state.currentLesson != null)
                        VideoPlayerSection(
                          lesson: state.currentLesson!,
                          currentPosition: _currentPosition,
                          totalDuration: _totalDuration,
                          isPlaying: _isPlaying,
                          isDark: isDark,
                          onPlayPause: _togglePlayPause,
                          onReplay10: _replay10,
                          onForward10: _forward10,
                          onFullscreen: () => HapticFeedback.mediumImpact(),
                          onCast: () {},
                          onSeek: _onSeek,
                          onSpeedTap: () {},
                          onBack: _handleBack,
                          courseTitle: state.courseTitle,
                          sectionIndex: sectionIndex,
                          lessonIndex: lessonIndex,
                          // For document/resource lessons, open the file URL
                          onOpenFile: state.currentLesson!.fileUrl != null &&
                                  state.currentLesson!.fileUrl!.isNotEmpty
                              ? () => _openUrl(state.currentLesson!.fileUrl!)
                              : null,
                        ),
                      if (state.currentLesson != null)
                        _buildLessonHeader(state, isDark),
                      if (state.groupLinks.hasAny)
                        _buildCourseGroupLinks(state, isDark),
                    ],
                  ),
                ),
                // ── Sticky: tab bar (like search bar in home) ────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    isDark: isDark,
                    child: ContentTabs(
                      currentIndex: state.currentTabIndex,
                      isDark: isDark,
                      onTabChanged: _changeContentTab,
                    ),
                  ),
                ),
                // ── Scrollable: tab content (no fixed height = all lessons show) ─
                SliverToBoxAdapter(
                  child: _buildCurrentTabContent(state, isDark),
                ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          hasNextLesson: state.hasNextLesson ||
              (state.isLastLesson && !state.allLessonsCompleted),
          isLastLesson: state.showCompleteCourseButton,
          isCompletingCourse: state.isMarkingComplete,
          isDark: isDark,
          onResourcesTap: () => _showAttachments(state),
          onNextLessonTap: _goToNextLesson,
          onCompleteCourse: () => _completeCourse(context),
        ),
      ],
    );
  }

  Widget _buildLessonHeader(CoursePlayerState state, bool isDark) {
    int sectionIndex = 0, lessonIndex = 0;
    for (int i = 0; i < state.sections.length; i++) {
      for (int j = 0; j < state.sections[i].lessons.length; j++) {
        if (state.sections[i].lessons[j].id == state.currentLesson!.id) {
          sectionIndex = i;
          lessonIndex = j;
          break;
        }
      }
    }

    // Use Builder to get a fresh context that can access CoursePlayerCubit
    return Builder(
      builder: (builderContext) {
        return LessonHeader(
          lesson: state.currentLesson!,
          section:
              state.sections.isNotEmpty ? state.sections[sectionIndex] : null,
          sectionIndex: sectionIndex,
          lessonIndex: lessonIndex,
          isBookmarked: state.isBookmarked,
          isDark: isDark,
          instructorName: null,
          instructorAvatar: null,
          onBookmarkTap: () {
            HapticFeedback.lightImpact();
            builderContext.read<CoursePlayerCubit>().toggleBookmark();
          },
          onInstructorTap: state.instructorId != null
              ? () {
                  HapticFeedback.lightImpact();
                  AppLogger.i(
                      '👨‍🏫 [CoursePlayer] Navigating to instructor: ${state.instructorId}');
                  builderContext.goNamed(
                    'instructor-profile',
                    pathParameters: {'instructorId': state.instructorId!},
                    queryParameters: {'returnCourseId': widget.courseId},
                  );
                }
              : () {
                  AppLogger.w(
                      '👨‍🏫 [CoursePlayer] instructorId is null, cannot navigate');
                },
        );
      },
    );
  }

  Widget _buildCourseGroupLinks(CoursePlayerState state, bool isDark) {
    final links = <_GroupLinkAction>[
      if (state.groupLinks.whatsapp != null)
        _GroupLinkAction(
          label: 'WhatsApp',
          icon: Icons.chat_outlined,
          color: const Color(0xFF25D366),
          url: state.groupLinks.whatsapp!,
        ),
      if (state.groupLinks.telegram != null)
        _GroupLinkAction(
          label: 'Telegram',
          icon: Icons.send_outlined,
          color: const Color(0xFF229ED9),
          url: state.groupLinks.telegram!,
        ),
      if (state.groupLinks.facebook != null)
        _GroupLinkAction(
          label: 'Facebook',
          icon: Icons.groups_outlined,
          color: const Color(0xFF1877F2),
          url: state.groupLinks.facebook!,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: links.map((link) {
          return OutlinedButton.icon(
            onPressed: () => _openUrl(link.url),
            icon: Icon(link.icon, size: 18, color: link.color),
            label: Text(link.label),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.textMainDark : AppColors.textMainLight,
              side: BorderSide(color: link.color.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleBack() {
    _navigateBackFromPlayer();
  }

  void _navigateBackFromPlayer() {
    _saveProgress();
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/my-learning');
  }

  /// Build the content for the currently selected tab.
  /// No fixed height — all content is naturally sized so all lessons show.
  Widget _buildCurrentTabContent(CoursePlayerState state, bool isDark) {
    final maxH = MediaQuery.of(context).size.height * 0.75;
    switch (state.currentTabIndex) {
      case 0: // Curriculum — shrinkWrap, no height cap needed
        return FutureBuilder<List<QuizEntity>>(
          future: _courseQuizzesFuture,
          builder: (context, snapshot) {
            return CurriculumList(
              sections: state.sections,
              currentLesson: state.currentLesson,
              completedLessons: const {},
              quizzes: snapshot.data ?? const [],
              isDark: isDark,
              onLessonTap: (lesson) {
                HapticFeedback.lightImpact();
                context.read<CoursePlayerCubit>().selectLesson(lesson);
              },
              isLessonCompleted: state.isLessonCompleted,
              getSectionCompletedCount: state.getSectionCompletedCount,
            );
          },
        );
      case 1: // More
        return MoreTab(
          isDark: isDark,
          onNotesTap: _showNotes,
          onBookmarksTap: _showBookmarks,
          onAnnouncementsTap: _showAnnouncements,
          onAttachmentsTap: () => _showAttachments(state),
        );
      case 2: // Q&A
        if (state.courseId != null && state.enrollmentId != null) {
          return SizedBox(
            height: maxH,
            child: QASection(
              isDark: isDark,
              courseId: state.courseId!,
              enrollmentId: state.enrollmentId!,
              lessonId: state.currentLesson?.id,
              repository: context.read<CoursePlayerCubit>().repository,
            ),
          );
        }
        return const SizedBox.shrink();
      case 3: // Quizzes
        if (state.courseId != null) {
          return SizedBox(
            height: maxH,
            child: QuizzesSection(
              isDark: isDark,
              courseId: state.courseId!,
              sections: state.sections,
              repository: di.sl<QuizzesRepository>(),
              onQuizTap: (quiz) {
                AppLogger.i('📝 [Screen] Quiz tapped: ${quiz.id}');
                context.goNamed(
                  'quiz-info',
                  pathParameters: {'quizId': quiz.id},
                  queryParameters:
                      _buildQuizNavigationQueryParameters(state, quiz),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      case 4: // Rating
        if (state.courseId != null && state.enrollmentId != null) {
          return SizedBox(
            height: maxH,
            child: RatingSection(
              isDark: isDark,
              courseId: state.courseId!,
              enrollmentId: state.enrollmentId!,
            ),
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  void _changeContentTab(int index) {
    context.read<CoursePlayerCubit>().changeTab(index);
  }

  Map<String, String> _buildQuizNavigationQueryParameters(
    CoursePlayerState state,
    QuizEntity quiz,
  ) {
    final params = <String, String>{
      'enrollment': state.enrollmentId ?? '',
    };

    if (state.courseTitle != null && state.courseTitle!.trim().isNotEmpty) {
      params['title'] = state.courseTitle!;
    }
    if (state.courseId != null && state.courseId!.trim().isNotEmpty) {
      params['courseId'] = state.courseId!;
    }
    final quizLessonId = quiz.lessonId;
    if (quizLessonId != null && quizLessonId.trim().isNotEmpty) {
      params['lesson'] = quizLessonId;
    }
    if (state.instructorId != null && state.instructorId!.trim().isNotEmpty) {
      params['instructorId'] = state.instructorId!;
    }
    if (state.instructorName != null &&
        state.instructorName!.trim().isNotEmpty) {
      params['instructor'] = state.instructorName!;
    }
    if (state.instructorAvatar != null &&
        state.instructorAvatar!.trim().isNotEmpty) {
      params['avatar'] = state.instructorAvatar!;
    }

    return params;
  }

  // Video Controls
  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    final state = context.read<CoursePlayerCubit>().state;
    if (state.currentLesson != null &&
        state.currentLesson!.type == LessonType.document) {
      if (state.currentLesson!.fileUrl != null) {
        _openUrl(state.currentLesson!.fileUrl!);
      }
      return;
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح الرابط')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في فتح الرابط: $e')),
        );
      }
    }
  }

  void _replay10() {
    HapticFeedback.lightImpact();
    setState(() =>
        _currentPosition = (_currentPosition - 10).clamp(0, _totalDuration));
  }

  void _forward10() {
    HapticFeedback.lightImpact();
    setState(() =>
        _currentPosition = (_currentPosition + 10).clamp(0, _totalDuration));
  }

  void _onSeek(double p) =>
      setState(() => _currentPosition = (p * _totalDuration).toInt());

  void _goToNextLesson() {
    HapticFeedback.mediumImpact();
    context.read<CoursePlayerCubit>().nextLesson();
  }

  Future<void> _completeCourse(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    final success = await context.read<CoursePlayerCubit>().completeCourse();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('course_player.course_completed_message'.tr()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      // Navigate back after showing snackbar
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.pop();
        }
      });
    }
  }

  // Bottom Sheets
  void _showNotes() {
    final state = context.read<CoursePlayerCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (state.currentLesson == null || state.enrollmentId == null) return;
    AppLogger.i('📝 [Screen] Opening notes sheet...');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      useSafeArea: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: NotesSheet(
          isDark: isDark,
          lessonId: state.currentLesson!.id,
          enrollmentId: state.enrollmentId!,
          currentPosition: _currentPosition,
          repository: context.read<CoursePlayerCubit>().repository,
          onRefresh: _showNotes,
        ),
      ),
    );
  }

  void _showBookmarks() {
    final state = context.read<CoursePlayerCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (state.enrollmentId == null) return;
    AppLogger.i('🔖 [Screen] Opening bookmarks sheet...');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      useSafeArea: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BookmarksSheet(
          isDark: isDark,
          enrollmentId: state.enrollmentId!,
          repository: context.read<CoursePlayerCubit>().repository,
          onGoToLesson: (lessonId) {
            AppLogger.i('🔖 [Screen] Go to lesson: $lessonId');
            for (final s in state.sections) {
              for (final l in s.lessons) {
                if (l.id == lessonId) {
                  context.read<CoursePlayerCubit>().selectLesson(l);
                  return;
                }
              }
            }
          },
        ),
      ),
    );
  }

  void _showAnnouncements() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      useSafeArea: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AnnouncementsSheet(isDark: isDark),
      ),
    );
  }

  void _showAttachments(CoursePlayerState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Combine course and lesson attachments
    final allAttachments = [
      ...state.courseAttachments,
      ...state.lessonAttachments,
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      useSafeArea: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AttachmentsSheet(
          isDark: isDark,
          attachments: allAttachments,
          scrollController: null,
          onPreview: (attachment) {
            _openAttachmentPreview(attachment);
          },
        ),
      ),
    );
  }

  Future<void> _openAttachmentPreview(dynamic attachment) async {
    final url = attachment.fileUrl as String;
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح الملف')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في فتح الملف: $e')),
        );
      }
    }
  }
}

// ── Sticky tab bar delegate (same pattern as home search bar) ─────────────────
class _GroupLinkAction {
  final String label;
  final IconData icon;
  final Color color;
  final String url;

  const _GroupLinkAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.url,
  });
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isDark;

  const _StickyTabBarDelegate({required this.child, required this.isDark});

  static const double _height = 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) => true;
}
