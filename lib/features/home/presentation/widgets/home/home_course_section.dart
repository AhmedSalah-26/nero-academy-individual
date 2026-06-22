import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../../wishlist/presentation/cubit/wishlist_state.dart';
import '../../../domain/entities/course_entity.dart';
import 'course_card.dart';
import 'course_card_horizontal.dart';

/// Home Course Section Widget - Responsive
class HomeCourseSection extends StatelessWidget {
  final String title;
  final List<CourseEntity> courses;
  final String locale;
  final VoidCallback? onSeeAll;
  final bool isVertical;

  const HomeCourseSection({
    super.key,
    required this.title,
    required this.courses,
    required this.locale,
    this.onSeeAll,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.055,
              vertical: screenHeight * 0.006,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onSeeAll != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    child: Text(
                      'home.see_all'.tr(),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Course List with BlocBuilder for proper rebuilds
        if (courses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'home.no_courses_available'.tr(),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : const Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, wishlistState) {
              if (isVertical) {
                return _buildVerticalList(context, screenWidth, wishlistState);
              }
              return _buildHorizontalList(
                  context, screenWidth, screenHeight, wishlistState);
            },
          ),
      ],
    );
  }

  Widget _buildHorizontalList(BuildContext context, double screenWidth,
      double screenHeight, WishlistState wishlistState) {
    final cardWidth = (screenWidth * 0.46).clamp(160.0, 205.0);
    final listHeight = (cardWidth * 1.14).clamp(195.0, 242.0);
    // Extra padding for shadow/glow visibility
    const shadowPadding = 10.0;

    return SizedBox(
      height: listHeight + (shadowPadding * 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.055,
          vertical: shadowPadding,
        ),
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: courses.length,
        separatorBuilder: (_, __) => SizedBox(width: screenWidth * 0.035),
        itemBuilder: (context, index) {
          final course = courses[index];
          final isInWishlist =
              wishlistState.wishlistCourseIds.contains(course.id);
          return CourseCard(
            course: course,
            locale: locale,
            width: cardWidth,
            isInWishlist: isInWishlist,
            onTap: () => context.push('/course/${course.id}'),
            onWishlistTap: () {
              HapticFeedback.lightImpact();
              context.read<WishlistCubit>().toggleWishlist(course.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildVerticalList(
      BuildContext context, double screenWidth, WishlistState wishlistState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: courses.take(5).map((course) {
          final isInWishlist =
              wishlistState.wishlistCourseIds.contains(course.id);
          return Padding(
            padding: EdgeInsets.only(bottom: screenWidth * 0.03),
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
        }).toList(),
      ),
    );
  }
}
