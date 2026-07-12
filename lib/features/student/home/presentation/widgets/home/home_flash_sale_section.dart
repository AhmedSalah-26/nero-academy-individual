import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'course_card.dart';

/// Home Flash Sale Section Widget - Responsive
class HomeFlashSaleSection extends StatefulWidget {
  final List<CourseEntity> courses;
  final String locale;

  const HomeFlashSaleSection(
      {super.key, required this.courses, required this.locale});

  @override
  State<HomeFlashSaleSection> createState() => _HomeFlashSaleSectionState();
}

class _HomeFlashSaleSectionState extends State<HomeFlashSaleSection> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    DateTime? earliestEnd;
    for (final course in widget.courses) {
      if (course.flashSaleEnd != null) {
        if (earliestEnd == null || course.flashSaleEnd!.isBefore(earliestEnd)) {
          earliestEnd = course.flashSaleEnd;
        }
      }
    }
    if (earliestEnd != null) {
      _remainingTime = earliestEnd.difference(DateTime.now());
      if (_remainingTime.isNegative) _remainingTime = Duration.zero;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = (screenWidth * 0.38).clamp(140.0, 170.0);
    final listHeight = (screenHeight * 0.26).clamp(200.0, 240.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - Slim Banner
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.016,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded,
                    color: AppColors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'home.flash_sale'.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _buildCountdownTimer(),
              ],
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        // Course List with BlocBuilder
        BlocBuilder<WishlistCubit, WishlistState>(
          builder: (context, wishlistState) {
            return SizedBox(
              height: listHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                physics: const BouncingScrollPhysics(),
                itemCount: widget.courses.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: screenWidth * 0.03),
                itemBuilder: (context, index) {
                  final course = widget.courses[index];
                  final isInWishlist =
                      wishlistState.wishlistCourseIds.contains(course.id);
                  return CourseCard(
                    course: course,
                    locale: widget.locale,
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
          },
        ),
      ],
    );
  }

  Widget _buildCountdownTimer() {
    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours.remainder(24);
    final minutes = _remainingTime.inMinutes.remainder(60);
    final seconds = _remainingTime.inSeconds.remainder(60);

    String timeText;
    if (days > 0) {
      timeText = '${days}d ${hours}h';
    } else if (hours > 0) {
      timeText = '${hours}h ${minutes}m';
    } else {
      timeText = '${minutes}m ${seconds}s';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, color: AppColors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
