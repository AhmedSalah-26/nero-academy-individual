import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../cubit/admin_courses_cubit.dart';
import 'course_list_item.dart';

/// Admin Courses Content
class AdminCoursesContent extends StatefulWidget {
  const AdminCoursesContent({super.key});

  @override
  State<AdminCoursesContent> createState() => _AdminCoursesContentState();
}

class _AdminCoursesContentState extends State<AdminCoursesContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCoursesCubit>().loadCourses();
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
      context.read<AdminCoursesCubit>().loadMoreCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AdminCoursesCubit, AdminCoursesState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic),
            Expanded(child: _buildCoursesList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminCoursesState state,
    bool isArabic,
  ) {
    final statusOptions = [
      {'value': 'all', 'label': 'All', 'labelAr': 'الكل'},
      {'value': 'published', 'label': 'Published', 'labelAr': 'منشور'},
      {'value': 'draft', 'label': 'Draft', 'labelAr': 'مسودة'},
      {'value': 'suspended', 'label': 'Suspended', 'labelAr': 'موقوف'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DashboardSearchBar(
                  hintText: 'Search by course title or instructor...',
                  hintTextAr: 'بحث بعنوان الكورس أو اسم المدرس...',
                  onSearch: (query) {
                    context.read<AdminCoursesCubit>().search(query);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardDark
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: DropdownButton<int>(
                  value: state.currentStatus.index,
                  underline: const SizedBox(),
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
                          .read<AdminCoursesCubit>()
                          .changeStatus(CourseStatus.values[index]);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(
    BuildContext context,
    AdminCoursesState state,
    bool isArabic,
  ) {
    if (state.isLoading && state.courses.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.courses.isEmpty) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminCoursesCubit>().loadCourses(
            status: state.currentStatus,
            refresh: true,
          ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.courses.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.courses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final course = state.courses[index];
          final cubit = context.read<AdminCoursesCubit>();
          return CourseListItem(
            course: course,
            onView: () => _showCourseDetails(context, course, isArabic),
            onViewEnrollments: () => AppRouter.goToAdminCourseEnrollments(
                context,
                courseId: course.id,
                course: course),
            onPublish: () => cubit.publishCourse(course.id),
            onUnpublish: () => cubit.unpublishCourse(course.id),
            onFeature: () => cubit.featureCourse(course.id),
            onUnfeature: () => cubit.unfeatureCourse(course.id),
            onSuspend: () => _showSuspendDialog(context, course.id, isArabic),
            onUnsuspend: () => cubit.unsuspendCourse(course.id),
            onDelete: () => _showDeleteDialog(context, course.id, isArabic),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 80, height: 60),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 200),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 150),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuspendDialog(
      BuildContext context, String courseId, bool isArabic) {
    final cubit = context.read<AdminCoursesCubit>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardInputDialog(
        title: isArabic ? 'إيقاف الكورس' : 'Suspend Course',
        message: isArabic
            ? 'أدخل سبب إيقاف الكورس'
            : 'Enter the reason for suspending this course',
        hintText: isArabic ? 'سبب الإيقاف...' : 'Suspension reason...',
        confirmText: isArabic ? 'إيقاف' : 'Suspend',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        maxLines: 3,
      ),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty) {
        cubit.suspendCourse(courseId, reason);
      }
    });
  }

  void _showDeleteDialog(BuildContext context, String courseId, bool isArabic) {
    final cubit = context.read<AdminCoursesCubit>();
    DashboardConfirmDialog.show(
      context,
      title: isArabic ? 'حذف الكورس' : 'Delete Course',
      message: isArabic
          ? 'هل أنت متأكد من حذف هذا الكورس؟ لا يمكن التراجع عن هذا الإجراء.'
          : 'Are you sure you want to delete this course? This action cannot be undone.',
      confirmText: isArabic ? 'حذف' : 'Delete',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      icon: Icons.delete_forever_rounded,
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        cubit.deleteCourse(courseId);
      }
    });
  }

  void _showCourseDetails(
    BuildContext context,
    dynamic course,
    bool isArabic,
  ) {
    final cubit = context.read<AdminCoursesCubit>();
    AppRouter.goToAdminCourseDetails(
      context,
      courseId: course.id,
      course: course,
      onPublish: () => cubit.publishCourse(course.id),
      onUnpublish: () => cubit.unpublishCourse(course.id),
      onFeature: () => cubit.featureCourse(course.id),
      onUnfeature: () => cubit.unfeatureCourse(course.id),
      onSuspend: () => _showSuspendDialog(context, course.id, isArabic),
      onUnsuspend: () => cubit.unsuspendCourse(course.id),
      onDelete: () => cubit.deleteCourse(course.id),
      onViewEnrollments: () => AppRouter.goToAdminCourseEnrollments(context,
          courseId: course.id, course: course),
    );
  }
}
