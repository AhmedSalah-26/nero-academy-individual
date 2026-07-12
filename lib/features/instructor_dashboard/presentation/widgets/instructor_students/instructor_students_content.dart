import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/services/direct_chat_service.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_students_cubit.dart';

/// Instructor Students Content
class InstructorStudentsContent extends StatefulWidget {
  const InstructorStudentsContent({super.key});

  @override
  State<InstructorStudentsContent> createState() =>
      _InstructorStudentsContentState();
}

class _InstructorStudentsContentState extends State<InstructorStudentsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InstructorStudentsCubit>().loadStudents(refresh: true);
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
      context.read<InstructorStudentsCubit>().loadMoreStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<InstructorStudentsCubit, InstructorStudentsState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, isArabic),
            Expanded(child: _buildStudentsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DashboardSearchBar(
              hintText: isArabic ? 'بحث عن طالب...' : 'Search students...',
              onSearch: (query) =>
                  context.read<InstructorStudentsCubit>().search(query),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => AppRouter.goToStudentsProgressSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.table_chart_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(
      BuildContext context, InstructorStudentsState state, bool isArabic) {
    if (state.isLoading && state.students.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: const LoadingSkeleton(width: double.infinity, height: 80),
        ),
      );
    }

    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا يوجد طلاب' : 'No students found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<InstructorStudentsCubit>().loadStudents(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.students.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.students.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          final student = state.students[index];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GestureDetector(
            onTap: () => _showStudentDetails(context, student),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: student.avatarUrl != null
                        ? NetworkImage(student.avatarUrl!)
                        : null,
                    child: student.avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight)),
                        const SizedBox(height: 4),
                        Text(
                          '${student.enrolledCoursesCount} ${isArabic ? 'كورس' : 'courses'} • ${student.totalProgress.toStringAsFixed(0)}% ${isArabic ? 'تقدم' : 'progress'}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStudentDetails(BuildContext context, student) {
    final cubit = context.read<InstructorStudentsCubit>();

    // Navigate to full screen instead of dialog
    AppRouter.goToStudentDetails(
      context,
      student: student,
      onSendMessage: () => _showSendMessageDialog(context, student, cubit),
      onViewEnrollments: () => _showEnrollmentsDialog(context, student, cubit),
      onViewProgress: () => _showProgressDialog(context, student, cubit),
    );
  }

  void _showSendMessageDialog(
      BuildContext context, student, InstructorStudentsCubit cubit) async {
    // Create or get existing 1-on-1 conversation, then navigate
    try {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser!.id;
      if (currentUserId == student.id) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic
                  ? 'لا يمكنك مراسلة نفسك'
                  : 'You cannot message yourself'),
            ),
          );
        }
        return;
      }
      final conversationId =
          await DirectChatService.getOrCreateSingleConversation(
        supabase: client,
        currentUserId: currentUserId,
        otherUserId: student.id,
      );
      if (context.mounted) {
        AppRouter.goToChat(
          context,
          conversationId: conversationId,
          conversationTitle: student.name,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  void _showEnrollmentsDialog(
      BuildContext context, student, InstructorStudentsCubit cubit) async {
    // Show loading
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch enrollments and available courses in parallel
    final results = await Future.wait([
      cubit.getStudentEnrollments(student.id),
      cubit.getAvailableCoursesForStudent(student.id),
    ]);

    final enrollments = results[0] as List<StudentEnrollmentDetail>;
    final availableCourses = results[1] as List<AvailableCourseForEnrollment>;

    if (context.mounted) {
      Navigator.pop(context); // Close loading

      // Navigate to full screen instead of dialog/bottom sheet
      AppRouter.goToStudentEnrollments(
        context,
        studentId: student.id,
        studentName: student.name,
        enrollments: enrollments,
        onExtendAccess: (enrollmentId, days) =>
            cubit.extendEnrollmentAccess(enrollmentId, days),
        onResetProgress: (enrollmentId) =>
            cubit.resetEnrollmentProgress(enrollmentId),
        onUpdateStatus: (enrollmentId, status) =>
            cubit.updateEnrollmentStatus(enrollmentId, status),
        onUnenroll: (enrollmentId) => cubit.unenrollStudent(enrollmentId),
        onEnrollInCourse: (courseId) =>
            cubit.enrollStudent(student.id, courseId),
        availableCourses: availableCourses,
        onRefreshEnrollments: () => cubit.getStudentEnrollments(student.id),
        onRefreshAvailableCourses: () =>
            cubit.getAvailableCoursesForStudent(student.id),
      );
    }
  }

  void _showProgressDialog(
      BuildContext context, student, InstructorStudentsCubit cubit) async {
    // Show loading
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final progressList = await cubit.getStudentProgress(student.id);

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      // Navigate to full screen instead of dialog
      AppRouter.goToStudentProgress(
        context,
        studentId: student.id,
        studentName: student.name,
        progressList: progressList,
      );
    }
  }
}
