import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Profile Skeleton - Shimmer loading
class InstructorSkeleton extends StatefulWidget {
  const InstructorSkeleton({super.key});

  @override
  State<InstructorSkeleton> createState() => _InstructorSkeletonState();
}

class _InstructorSkeletonState extends State<InstructorSkeleton>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Avatar
                    _ShimmerCircle(
                      size: 90,
                      isDark: isDark,
                      animValue: _animation.value,
                    ),
                    const SizedBox(width: 24),
                    // Stats
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          3,
                          (i) => Column(
                            children: [
                              _ShimmerBox(
                                width: 40,
                                height: 20,
                                isDark: isDark,
                                animValue: _animation.value,
                              ),
                              const SizedBox(height: 4),
                              _ShimmerBox(
                                width: 50,
                                height: 12,
                                isDark: isDark,
                                animValue: _animation.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Name
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _ShimmerBox(
                    width: 150,
                    height: 20,
                    isDark: isDark,
                    animValue: _animation.value,
                  ),
                ),
                const SizedBox(height: 8),
                // Headline
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _ShimmerBox(
                    width: 200,
                    height: 14,
                    isDark: isDark,
                    animValue: _animation.value,
                  ),
                ),
                const SizedBox(height: 16),
                // Bio
                _ShimmerBox(
                  height: 60,
                  isDark: isDark,
                  animValue: _animation.value,
                ),
                const SizedBox(height: 16),
                // Tags
                Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ShimmerBox(
                        width: 70 + (i * 10),
                        height: 28,
                        borderRadius: 20,
                        isDark: isDark,
                        animValue: _animation.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                _ShimmerBox(
                  height: 1,
                  isDark: isDark,
                  animValue: _animation.value,
                ),
                const SizedBox(height: 16),
                // Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: 9,
                  itemBuilder: (_, i) => _ShimmerBox(
                    isDark: isDark,
                    animValue: _animation.value,
                    borderRadius: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDark;
  final double animValue;

  const _ShimmerBox({
    this.width,
    this.height,
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

class _ShimmerCircle extends StatelessWidget {
  final double size;
  final bool isDark;
  final double animValue;

  const _ShimmerCircle({
    required this.size,
    required this.isDark,
    required this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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
