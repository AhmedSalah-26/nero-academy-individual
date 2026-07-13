import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/utils/toast_utils.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/features/student/course_player/presentation/cubit/course_player_cubit.dart';
import 'package:lms_platform/features/student/course_player/presentation/screens/course_player_screen.dart';
import 'package:lms_platform/features/student/my_learning/presentation/cubit/my_learning_cubit.dart';
import 'package:lms_platform/features/student/my_learning/presentation/cubit/my_learning_state.dart';
import 'package:lms_platform/features/student/my_learning/presentation/widgets/my_learning/continue_learning_card.dart';
import 'package:lms_platform/features/student/my_learning/presentation/widgets/my_learning/enrolled_course_card.dart';
import 'package:lms_platform/features/student/my_learning/presentation/widgets/my_learning/filter_tabs.dart';
import 'package:lms_platform/features/student/my_learning/presentation/widgets/my_learning/recommended_section.dart';

/// My Learning Screen - Shows user's enrolled courses
class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<MyLearningCubit>().loadMyLearning(userId);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MyLearningCubit>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await context.read<MyLearningCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocConsumer<MyLearningCubit, MyLearningState>(
          listener: (context, state) {
            if (state.isError && state.errorMessage != null) {
              ToastUtils.showError(state.errorMessage!);
              context.read<MyLearningCubit>().clearError();
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildAppBar(isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Theme.of(context).colorScheme.tertiary,
                    backgroundColor: Theme.of(context).cardColor,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: state.isLoading
                          ? _buildLoading(isDark)
                          : state.isEmpty
                              ? _buildEmpty(isDark)
                              : _buildContent(state, isDark),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SafeArea(
      bottom: false,
      child: FadeIn(
        duration: const Duration(milliseconds: 400),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.grey800.withValues(alpha: 0.5)
                    : AppColors.grey200.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'my_learning.title'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              GlassIconButton(
                icon: Icons.search_rounded,
                onTap: _onSearch,
                size: 42,
                iconSize: 22,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MyLearningState state, bool isDark) {
    final locale = context.locale.languageCode;
    int sectionIndex = 0;

    return ListView(
      key: const ValueKey('content'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),
        // Continue Learning Card with animation
        if (state.hasContinueLearning)
          SlideFadeIn.fromBottom(
            delay: Duration(milliseconds: 100 * sectionIndex++),
            child: ContinueLearningCard(
              enrollment: state.continueLearning!,
              locale: locale,
              onResume: () => _onCourseResume(state.continueLearning!.courseId),
              onTap: () => _onCourseTap(state.continueLearning!.courseId),
            ),
          ),
        const SizedBox(height: 24),
        // Filter Tabs with animation
        SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: 100 * sectionIndex++),
          child: FilterTabs(
            currentFilter: state.filter,
            inProgressCount: state.inProgressCount,
            completedCount: state.completedCount,
            onFilterChanged: (filter) {
              context.read<MyLearningCubit>().setFilter(filter);
            },
          ),
        ),
        const SizedBox(height: 20),
        // Course List with animation
        _buildCourseList(state, locale, isDark),
        // Recommended Section with animation
        if (state.recommendedCourses.isNotEmpty) ...[
          const SizedBox(height: 32),
          SlideFadeIn.fromBottom(
            delay: const Duration(milliseconds: 300),
            child: RecommendedSection(
              courses: state.recommendedCourses,
              locale: locale,
              onSeeAll: _onSeeAllRecommended,
              onCourseTap: (course) => _onCourseTap(course.courseId),
            ),
          ),
        ],
        // Bottom spacing
        SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
      ],
    );
  }

  Widget _buildCourseList(
    MyLearningState state,
    String locale,
    bool isDark,
  ) {
    final enrollments = state.filteredEnrollments;

    if (enrollments.isEmpty) {
      return _buildEmptyFilter();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...enrollments.asMap().entries.map((entry) {
            final index = entry.key;
            final enrollment = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SlideFadeIn.fromBottom(
                delay: Duration(milliseconds: 50 * index),
                child: AnimatedCard(
                  child: EnrolledCourseCard(
                    enrollment: enrollment,
                    locale: locale,
                    onTap: () => _onCourseTap(enrollment.courseId),
                  ),
                ),
              ),
            );
          }),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: AppLoadingState.compact(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return EmptyState(
      type: EmptyStateType.myLearning,
      compact: false,
      onAction: _onBrowseCourses,
    );
  }

  Widget _buildEmpty(bool isDark) {
    return EmptyState(
      key: const ValueKey('empty'),
      type: EmptyStateType.myLearning,
      onAction: _onBrowseCourses,
    );
  }

  Widget _buildLoading(bool isDark) {
    return ListView.builder(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FadeIn(
          delay: Duration(milliseconds: 100 * index),
          child: ShimmerEffect(
            baseColor:
                isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
            highlightColor: isDark
                ? AppColors.shimmerHighlightDark
                : AppColors.shimmerHighlight,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSearch() {
    AppRouter.goToSearch(context);
  }

  void _onCourseTap(String courseId) {
    // Get enrollment data to navigate to course player
    final state = context.read<MyLearningCubit>().state;
    final enrollments = state.enrollments.where((e) => e.courseId == courseId);

    if (enrollments.isEmpty) {
      // Fallback to course details if no enrollment found
      AppRouter.goToCourseDetails(context, courseId);
      return;
    }

    final enrollment = enrollments.first;
    if (!enrollment.isCurrentlyAvailable) {
      _showInactiveCourseMessage();
      return;
    }
    // Navigate and refresh when returning
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (_, __, ___) => _buildCoursePlayerScreen(
              courseId: courseId,
              enrollmentId: enrollment.id,
              courseTitle: enrollment.getTitle(context.locale.languageCode),
              teacherId: enrollment.teacherId,
              instructorName: enrollment.instructorName,
              instructorAvatar: enrollment.instructorAvatar,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        )
        .then((_) => _loadData());
  }

  void _onCourseResume(String courseId) {
    // Get enrollment data to navigate to course player at last position
    final state = context.read<MyLearningCubit>().state;
    final enrollments = state.enrollments.where((e) => e.courseId == courseId);

    if (enrollments.isEmpty) {
      AppRouter.goToCourseDetails(context, courseId);
      return;
    }

    final enrollment = enrollments.first;
    if (!enrollment.isCurrentlyAvailable) {
      _showInactiveCourseMessage();
      return;
    }
    // Navigate and refresh when returning
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (_, __, ___) => _buildCoursePlayerScreen(
              courseId: courseId,
              enrollmentId: enrollment.id,
              courseTitle: enrollment.getTitle(context.locale.languageCode),
              teacherId: enrollment.teacherId,
              instructorName: enrollment.instructorName,
              instructorAvatar: enrollment.instructorAvatar,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        )
        .then((_) => _loadData());
  }

  Widget _buildCoursePlayerScreen({
    required String courseId,
    required String enrollmentId,
    required String courseTitle,
    String? lessonId,
    String? teacherId,
    String? instructorName,
    String? instructorAvatar,
  }) {
    return BlocProvider(
      create: (_) => sl<CoursePlayerCubit>(),
      child: CoursePlayerScreen(
        courseId: courseId,
        enrollmentId: enrollmentId,
        courseTitle: courseTitle,
        initialLessonId: lessonId,
        teacherId: teacherId,
        instructorName: instructorName,
        instructorAvatar: instructorAvatar,
      ),
    );
  }

  void _onBrowseCourses() {
    AppRouter.goToHome(context);
  }

  void _onSeeAllRecommended() {
    AppRouter.goToSearch(context);
  }

  void _showInactiveCourseMessage() {
    final isArabic = context.locale.languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'الكورس غير مفعل حاليا وسيكون متاحا في معاده المحدد'
              : 'This course is inactive now and will be available on schedule',
        ),
        backgroundColor: AppColors.warning,
      ),
    );
  }
}
