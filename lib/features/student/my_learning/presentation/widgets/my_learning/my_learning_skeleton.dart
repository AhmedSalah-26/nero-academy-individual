import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// My Learning Loading Skeleton - Shimmer effect
class MyLearningSkeleton extends StatefulWidget {
  const MyLearningSkeleton({super.key});

  @override
  State<MyLearningSkeleton> createState() => _MyLearningSkeletonState();
}

class _MyLearningSkeletonState extends State<MyLearningSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Tabs Skeleton
              Row(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _ShimmerBox(
                      width: 90 + (i * 10),
                      height: 40,
                      borderRadius: 24,
                      isDark: isDark,
                      animValue: _animation.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Course Cards Skeleton
              ...List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EnrolledCourseCardSkeleton(
                    isDark: isDark,
                    animValue: _animation.value,
                    screenWidth: screenWidth,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final bool isDark;
  final double animValue;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.borderRadius = 8,
    required this.isDark,
    required this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(animValue - 1, 0),
          end: Alignment(animValue + 1, 0),
          colors: isDark
              ? [
                  AppColors.shimmerBaseDark,
                  AppColors.shimmerHighlightDark,
                  AppColors.shimmerBaseDark,
                ]
              : [
                  AppColors.shimmerBase,
                  AppColors.shimmerHighlight,
                  AppColors.shimmerBase,
                ],
        ),
      ),
    );
  }
}

class _EnrolledCourseCardSkeleton extends StatelessWidget {
  final bool isDark;
  final double animValue;
  final double screenWidth;

  const _EnrolledCourseCardSkeleton({
    required this.isDark,
    required this.animValue,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = (screenWidth * 0.24).clamp(90.0, 110.0);

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.grey100,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          _ShimmerBox(
            width: cardHeight,
            height: cardHeight,
            borderRadius: 14,
            isDark: isDark,
            animValue: animValue,
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerBox(
                    height: 14,
                    isDark: isDark,
                    animValue: animValue,
                  ),
                  const SizedBox(height: 8),
                  _ShimmerBox(
                    width: screenWidth * 0.3,
                    height: 10,
                    isDark: isDark,
                    animValue: animValue,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _ShimmerBox(
                          height: 6,
                          borderRadius: 3,
                          isDark: isDark,
                          animValue: animValue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ShimmerBox(
                        width: 40,
                        height: 12,
                        isDark: isDark,
                        animValue: animValue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
