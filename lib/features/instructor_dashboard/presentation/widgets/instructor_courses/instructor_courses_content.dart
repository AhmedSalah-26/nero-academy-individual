import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_course_model.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_courses_cubit.dart';
import 'instructor_course_list_item.dart';

/// Instructor Courses Content
class InstructorCoursesContent extends StatefulWidget {
  const InstructorCoursesContent({super.key});

  @override
  State<InstructorCoursesContent> createState() =>
      _InstructorCoursesContentState();
}

class _InstructorCoursesContentState extends State<InstructorCoursesContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isPreviewNavigationInProgress = false;

  @override
  void initState() {
    super.initState();
    context.read<InstructorCoursesCubit>().loadCourses(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InstructorCoursesCubit>().loadMoreCourses();
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, InstructorCourseModel course) async {
    final cubit = context.read<InstructorCoursesCubit>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'instructor.delete_course_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'instructor.delete_course_confirm'.tr(namedArgs: {
              'title': course.getTitle(isArabic),
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('common.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text('common.delete'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await cubit.deleteCourse(course.id);
    }
  }

  Future<void> _openPreviewCourse(String courseId) async {
    if (!mounted || _isPreviewNavigationInProgress) return;

    setState(() => _isPreviewNavigationInProgress = true);
    try {
      AppLogger.i('[InstructorCourses] Preview Course: $courseId');
      await context.push('/course/$courseId');
    } finally {
      if (mounted) {
        setState(() => _isPreviewNavigationInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<InstructorCoursesCubit, InstructorCoursesState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic, isDark),
            Expanded(child: _buildCoursesList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, InstructorCoursesState state,
      bool isArabic, bool isDark) {
    final statusOptions = [
      {'value': 'all', 'label': 'All', 'labelAr': 'الكل'},
      {'value': 'published', 'label': 'Published', 'labelAr': 'منشور'},
      {'value': 'draft', 'label': 'Draft', 'labelAr': 'مسودة'},
      {'value': 'suspended', 'label': 'Suspended', 'labelAr': 'موقوف'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: DropdownButton<int>(
                value: _getTabIndex(state.currentStatus),
                underline: const SizedBox(),
                isExpanded: true,
                items: statusOptions.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(
                      isArabic
                          ? entry.value['labelAr'] as String
                          : entry.value['label'] as String,
                    ),
                  );
                }).toList(),
                onChanged: (index) {
                  if (index != null) {
                    context
                        .read<InstructorCoursesCubit>()
                        .changeStatus(_getStatusFromIndex(index));
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          SolidActionButton(
            icon: Icons.add,
            label: isArabic ? 'كورس جديد' : 'New Course',
            color: AppColors.primary,
            onPressed: () {
              AppLogger.i('[InstructorCourses] New Course button pressed');
              context.push('/instructor/course/new');
            },
          ),
        ],
      ),
    );
  }

  int _getTabIndex(InstructorCourseStatus status) {
    switch (status) {
      case InstructorCourseStatus.all:
        return 0;
      case InstructorCourseStatus.published:
        return 1;
      case InstructorCourseStatus.draft:
        return 2;
      case InstructorCourseStatus.suspended:
        return 3;
    }
  }

  InstructorCourseStatus _getStatusFromIndex(int index) {
    switch (index) {
      case 1:
        return InstructorCourseStatus.published;
      case 2:
        return InstructorCourseStatus.draft;
      case 3:
        return InstructorCourseStatus.suspended;
      default:
        return InstructorCourseStatus.all;
    }
  }

  Widget _buildCoursesList(
      BuildContext context, InstructorCoursesState state, bool isArabic) {
    if (state.isLoading && state.courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context
            .read<InstructorCoursesCubit>()
            .loadCourses(status: state.currentStatus, refresh: true),
        color: AppColors.primary,
        child: _buildLoadingSkeleton(),
      );
    }

    if (state.courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context
            .read<InstructorCoursesCubit>()
            .loadCourses(status: state.currentStatus, refresh: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'لا توجد كورسات' : 'No courses found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context
          .read<InstructorCoursesCubit>()
          .loadCourses(status: state.currentStatus, refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.courses.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.courses.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          final course = state.courses[index];
          return InstructorCourseListItem(
            course: course,
            onPublish: course.isPublished
                ? null
                : () => context
                    .read<InstructorCoursesCubit>()
                    .publishCourse(course.id),
            onUnpublish: course.isPublished
                ? () => context
                    .read<InstructorCoursesCubit>()
                    .unpublishCourse(course.id)
                : null,
            onEdit: () {
              AppLogger.i('[InstructorCourses] Edit Course: ${course.id}');
              context.push('/instructor/course/${course.id}/edit');
            },
            onViewEnrollments: () {
              AppLogger.i('[InstructorCourses] View Enrollments: ${course.id}');
              context.push(
                '/instructor/course/${course.id}/enrollments',
                extra: {
                  'courseTitle': course.getTitle(isArabic),
                },
              );
            },
            onPreview: () => _openPreviewCourse(course.id),
            onDelete: course.enrollmentCount == 0
                ? () => _showDeleteConfirmation(context, course)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: const LoadingSkeleton(width: double.infinity, height: 280),
        );
      },
    );
  }
}
