import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Cart Loading State Widget - Shimmer effect
class CartLoadingState extends StatefulWidget {
  final bool isDark;

  const CartLoadingState({super.key, required this.isDark});

  @override
  State<CartLoadingState> createState() => _CartLoadingStateState();
}

class _CartLoadingStateState extends State<CartLoadingState>
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
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SafeArea(
          child: Column(
            children: [
              // AppBar Skeleton
              _buildAppBarSkeleton(screenWidth),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Cart Items Skeleton
                      ...List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemSkeleton(
                            isDark: widget.isDark,
                            animValue: _animation.value,
                            screenWidth: screenWidth,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Coupon Section Skeleton
                      _ShimmerBox(
                        height: 56,
                        borderRadius: 12,
                        isDark: widget.isDark,
                        animValue: _animation.value,
                      ),
                      const SizedBox(height: 24),
                      // Summary Card Skeleton
                      _SummaryCardSkeleton(
                        isDark: widget.isDark,
                        animValue: _animation.value,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBarSkeleton(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _ShimmerBox(
            width: 40,
            height: 40,
            borderRadius: 12,
            isDark: widget.isDark,
            animValue: _animation.value,
          ),
          const Spacer(),
          _ShimmerBox(
            width: 80,
            height: 24,
            isDark: widget.isDark,
            animValue: _animation.value,
          ),
          const Spacer(),
          _ShimmerBox(
            width: 60,
            height: 20,
            isDark: widget.isDark,
            animValue: _animation.value,
          ),
        ],
      ),
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

class _CartItemSkeleton extends StatelessWidget {
  final bool isDark;
  final double animValue;
  final double screenWidth;

  const _CartItemSkeleton({
    required this.isDark,
    required this.animValue,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.grey100,
        ),
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                _ShimmerBox(
                  width: 90,
                  height: 90,
                  borderRadius: 12,
                  isDark: isDark,
                  animValue: animValue,
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(
                        height: 16,
                        isDark: isDark,
                        animValue: animValue,
                      ),
                      const SizedBox(height: 8),
                      _ShimmerBox(
                        width: screenWidth * 0.3,
                        height: 12,
                        isDark: isDark,
                        animValue: animValue,
                      ),
                      const SizedBox(height: 12),
                      _ShimmerBox(
                        width: 80,
                        height: 24,
                        borderRadius: 6,
                        isDark: isDark,
                        animValue: animValue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : AppColors.grey50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(
                  width: 100,
                  height: 20,
                  isDark: isDark,
                  animValue: animValue,
                ),
                _ShimmerBox(
                  width: 80,
                  height: 32,
                  borderRadius: 10,
                  isDark: isDark,
                  animValue: animValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  final bool isDark;
  final double animValue;

  const _SummaryCardSkeleton({
    required this.isDark,
    required this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.grey100,
        ),
      ),
      child: Column(
        children: [
          // Subtotal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(
                width: 80,
                height: 14,
                isDark: isDark,
                animValue: animValue,
              ),
              _ShimmerBox(
                width: 60,
                height: 14,
                isDark: isDark,
                animValue: animValue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Discount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(
                width: 70,
                height: 14,
                isDark: isDark,
                animValue: animValue,
              ),
              _ShimmerBox(
                width: 50,
                height: 14,
                isDark: isDark,
                animValue: animValue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          _ShimmerBox(
            height: 1,
            isDark: isDark,
            animValue: animValue,
          ),
          const SizedBox(height: 16),
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(
                width: 60,
                height: 20,
                isDark: isDark,
                animValue: animValue,
              ),
              _ShimmerBox(
                width: 90,
                height: 24,
                isDark: isDark,
                animValue: animValue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Checkout button
          _ShimmerBox(
            height: 56,
            borderRadius: 14,
            isDark: isDark,
            animValue: animValue,
          ),
        ],
      ),
    );
  }
}
