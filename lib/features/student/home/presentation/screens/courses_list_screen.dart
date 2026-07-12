import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/home/presentation/widgets/home/course_card_horizontal.dart';

/// Courses List Screen - Shows all courses of a category
class CoursesListScreen extends StatelessWidget {
  final String title;
  final List<CourseEntity> courses;

  const CoursesListScreen({
    super.key,
    required this.title,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale.languageCode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, wishlistState) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = courses[index];
              final isInWishlist =
                  wishlistState.wishlistCourseIds.contains(course.id);

              return SlideFadeIn.fromBottom(
                delay: Duration(milliseconds: index < 10 ? 30 * index : 300),
                duration: const Duration(milliseconds: 300),
                child: CourseCardHorizontal(
                  course: course,
                  locale: locale,
                  isInWishlist: isInWishlist,
                  onTap: () => context.push('/course/${course.id}'),
                  onWishlistTap: () {
                    HapticFeedback.lightImpact();
                    context.read<WishlistCubit>().toggleWishlist(course.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
