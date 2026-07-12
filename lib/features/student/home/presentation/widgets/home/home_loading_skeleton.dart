import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Home Loading Skeleton Widget - Professional shimmer effect
class HomeLoadingSkeleton extends StatefulWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  State<HomeLoadingSkeleton> createState() => _HomeLoadingSkeletonState();
}

class _HomeLoadingSkeletonState extends State<HomeLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
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
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(
                  height: screenHeight * 0.22,
                  borderRadius: 20,
                  isDark: isDark,
                  animValue: _animation.value),
              SizedBox(height: screenHeight * 0.03),
              _ShimmerBox(
                  height: 18,
                  width: screenWidth * 0.35,
                  isDark: isDark,
                  animValue: _animation.value),
              SizedBox(height: screenHeight * 0.015),
              SizedBox(
                height: (screenWidth * 0.58).clamp(200.0, 260.0) * 1.3,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.04),
                    child: _CourseCardSkeleton(
                        isDark: isDark, animValue: _animation.value),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              _ShimmerBox(
                  height: 18,
                  width: screenWidth * 0.3,
                  isDark: isDark,
                  animValue: _animation.value),
              SizedBox(height: screenHeight * 0.02),
              ...List.generate(
                  3,
                  (i) => Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                        child: _HorizontalCardSkeleton(
                            isDark: isDark, animValue: _animation.value),
                      )),
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

  const _ShimmerBox(
      {this.width,
      required this.height,
      this.borderRadius = 8,
      required this.isDark,
      required this.animValue});

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
                  AppColors.shimmerBaseDark
                ]
              : [
                  AppColors.shimmerBase,
                  AppColors.shimmerHighlight,
                  AppColors.shimmerBase
                ],
        ),
      ),
    );
  }
}

class _CourseCardSkeleton extends StatelessWidget {
  final bool isDark;
  final double animValue;

  const _CourseCardSkeleton({required this.isDark, required this.animValue});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.58).clamp(200.0, 260.0);
    final imageHeight = cardWidth * 0.56;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _ShimmerBox(
                height: imageHeight,
                borderRadius: 0,
                isDark: isDark,
                animValue: animValue),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShimmerBox(height: 12, isDark: isDark, animValue: animValue),
                const SizedBox(height: 6),
                _ShimmerBox(
                    height: 10,
                    width: cardWidth * 0.6,
                    isDark: isDark,
                    animValue: animValue),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ShimmerBox(
                        height: 10,
                        width: cardWidth * 0.25,
                        isDark: isDark,
                        animValue: animValue),
                    _ShimmerBox(
                        height: 18,
                        width: cardWidth * 0.2,
                        isDark: isDark,
                        animValue: animValue),
                  ],
                ),
                const SizedBox(height: 10),
                _ShimmerBox(
                    height: 16,
                    width: cardWidth * 0.5,
                    isDark: isDark,
                    animValue: animValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalCardSkeleton extends StatelessWidget {
  final bool isDark;
  final double animValue;

  const _HorizontalCardSkeleton(
      {required this.isDark, required this.animValue});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = (screenWidth * 0.26).clamp(95.0, 120.0);
    final padding = screenWidth * 0.03;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isDark ? Colors.white10 : AppColors.grey100),
        ),
        child: Row(
          children: [
            _ShimmerBox(
                width: cardHeight,
                height: cardHeight,
                borderRadius: 12,
                isDark: isDark,
                animValue: animValue),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ShimmerBox(
                        height: 14, isDark: isDark, animValue: animValue),
                    SizedBox(height: screenWidth * 0.02),
                    _ShimmerBox(
                        height: 10,
                        width: screenWidth * 0.25,
                        isDark: isDark,
                        animValue: animValue),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ShimmerBox(
                            height: 12,
                            width: screenWidth * 0.12,
                            isDark: isDark,
                            animValue: animValue),
                        _ShimmerBox(
                            height: 16,
                            width: screenWidth * 0.15,
                            isDark: isDark,
                            animValue: animValue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
