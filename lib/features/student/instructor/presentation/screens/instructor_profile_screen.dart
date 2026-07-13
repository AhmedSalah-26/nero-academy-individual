import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/features/student/instructor/presentation/cubit/instructor_cubit.dart';
import 'package:lms_platform/features/student/instructor/presentation/cubit/instructor_state.dart';
import 'package:lms_platform/features/student/instructor/presentation/widgets/instructor_course_grid.dart';
import 'package:lms_platform/features/student/instructor/presentation/widgets/instructor_stats_row.dart';
import 'package:lms_platform/features/student/instructor/presentation/widgets/instructor_skeleton.dart';

/// Instructor Profile Screen - Instagram-like bio page
class InstructorProfileScreen extends StatefulWidget {
  final String teacherId;
  final String fallbackLocation;

  const InstructorProfileScreen({
    super.key,
    required this.teacherId,
    this.fallbackLocation = '/home',
  });

  @override
  State<InstructorProfileScreen> createState() =>
      _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  late final ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context.read<InstructorCubit>().loadInstructor(widget.teacherId);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > (200 - kToolbarHeight);
    if (show != _showTitle) {
      setState(() {
        _showTitle = show;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocBuilder<InstructorCubit, InstructorState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const InstructorSkeleton();
          }

          if (state.isError) {
            return _buildError(state.errorMessage);
          }

          if (state.instructor == null) {
            return _buildError('Instructor not found');
          }

          return _buildContent(state, isDark);
        },
      ),
    );
  }

  Widget _buildContent(InstructorState state, bool isDark) {
    final instructor = state.instructor!;
    final locale = context.locale.languageCode;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Collapsing Header with instructor cover/avatar
        // SliverAppBar replacing CollapsingHeader
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: AppBackButton(fallbackLocation: widget.fallbackLocation),
          title: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showTitle ? 1.0 : 0.0,
            child: Text(
              instructor.name,
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.textMainLight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(
            background: instructor.coverImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: instructor.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark ? AppColors.surfaceDark : AppColors.grey200,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
        ),

        // Profile Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar and Stats Row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: instructor.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: instructor.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.grey200,
                                ),
                                errorWidget: (_, __, ___) =>
                                    _buildAvatarPlaceholder(instructor.name),
                              )
                            : _buildAvatarPlaceholder(instructor.name),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Stats
                    Expanded(
                      child: InstructorStatsRow(
                        courses: instructor.totalCourses,
                        students: instructor.totalStudents,
                        rating: instructor.averageRating,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name and Headline
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructor.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.white
                              : AppColors.textMainLight,
                        ),
                      ),
                      if (instructor.headline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          instructor.headline!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Bio
                if (instructor.bio != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      instructor.bio!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                  ),
                ],
                // Expertise Tags
                if (instructor.expertise != null &&
                    instructor.expertise!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: instructor.expertise!.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // Social Links
                if (_hasSocialLinks(instructor)) ...[
                  const SizedBox(height: 16),
                  _buildSocialLinks(instructor, isDark),
                ],
              ],
            ),
          ),
        ),

        // Divider
        SliverToBoxAdapter(
          child: Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),

        // Courses Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'instructor.courses'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.courses.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Courses Grid (Instagram-like)
        if (state.courses.isNotEmpty)
          InstructorCourseGrid(
            courses: state.courses,
            locale: locale,
            onCourseTap: (courseId) => context.push('/course/$courseId'),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'instructor.no_courses'.tr(),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ),
            ),
          ),

        // Bottom Spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'I',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  bool _hasSocialLinks(instructor) {
    return instructor.website != null ||
        instructor.linkedin != null ||
        instructor.twitter != null ||
        instructor.facebook != null ||
        instructor.youtube != null;
  }

  Widget _buildSocialLinks(instructor, bool isDark) {
    return Row(
      children: [
        if (instructor.website != null)
          _buildSocialButton(
            icon: FontAwesomeIcons.globe,
            url: instructor.website!,
            isDark: isDark,
            brandColor: Colors.blueGrey,
          ),
        if (instructor.linkedin != null) ...[
          if (instructor.website != null) const SizedBox(width: 12),
          _buildSocialButton(
            icon: FontAwesomeIcons.linkedinIn,
            url: instructor.linkedin!,
            isDark: isDark,
            brandColor: const Color(0xFF0077B5),
          ),
        ],
        if (instructor.twitter != null) ...[
          if (instructor.website != null || instructor.linkedin != null)
            const SizedBox(width: 12),
          _buildSocialButton(
            icon: FontAwesomeIcons.twitter,
            url: instructor.twitter!,
            isDark: isDark,
            brandColor: const Color(0xFF1DA1F2),
          ),
        ],
        if (instructor.facebook != null) ...[
          if (instructor.website != null ||
              instructor.linkedin != null ||
              instructor.twitter != null)
            const SizedBox(width: 12),
          _buildSocialButton(
            icon: FontAwesomeIcons.facebookF,
            url: instructor.facebook!,
            isDark: isDark,
            brandColor: const Color(0xFF1877F2),
          ),
        ],
        if (instructor.youtube != null) ...[
          if (instructor.website != null ||
              instructor.linkedin != null ||
              instructor.twitter != null ||
              instructor.facebook != null)
            const SizedBox(width: 12),
          _buildSocialButton(
            icon: FontAwesomeIcons.youtube,
            url: instructor.youtube!,
            isDark: isDark,
            brandColor: const Color(0xFFFF0000),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required FaIconData icon,
    required String url,
    required bool isDark,
    Color? brandColor,
  }) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching URL: $e');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: FaIcon(
          icon,
          size: 20,
          color: brandColor ??
              (isDark ? AppColors.white : AppColors.textMainLight),
        ),
      ),
    );
  }

  Widget _buildError(String? message) {
    return ErrorState(
      type: ErrorType.generic,
      message: message ?? 'common.error'.tr(),
      onGoBack: () => Navigator.pop(context),
    );
  }
}
