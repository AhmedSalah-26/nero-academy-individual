import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Skeleton Type
enum SkeletonType {
  courseCard,
  listItem,
  text,
  avatar,
  button,
  custom,
}

/// Unified Loading Skeleton Widget
class LoadingSkeleton extends StatefulWidget {
  final SkeletonType type;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int count;
  final Axis direction;
  final double spacing;

  const LoadingSkeleton({
    super.key,
    this.type = SkeletonType.custom,
    this.width,
    this.height,
    this.borderRadius,
    this.count = 1,
    this.direction = Axis.vertical,
    this.spacing = 16,
  });

  /// Course card skeleton
  const LoadingSkeleton.courseCard({
    super.key,
    this.count = 1,
    this.direction = Axis.horizontal,
    this.spacing = 16,
  })  : type = SkeletonType.courseCard,
        width = null,
        height = null,
        borderRadius = null;

  /// List item skeleton
  const LoadingSkeleton.listItem({
    super.key,
    this.count = 1,
    this.spacing = 12,
  })  : type = SkeletonType.listItem,
        width = null,
        height = null,
        borderRadius = null,
        direction = Axis.vertical;

  /// Text skeleton
  const LoadingSkeleton.text({
    super.key,
    this.width,
    this.height = 16,
    this.count = 1,
    this.spacing = 8,
  })  : type = SkeletonType.text,
        borderRadius = null,
        direction = Axis.vertical;

  /// Avatar skeleton
  const LoadingSkeleton.avatar({
    super.key,
    double size = 48,
  })  : type = SkeletonType.avatar,
        width = size,
        height = size,
        borderRadius = null,
        count = 1,
        direction = Axis.vertical,
        spacing = 0;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
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
    if (widget.count > 1) {
      return _buildMultiple();
    }
    return _buildSkeleton();
  }

  Widget _buildMultiple() {
    final children = List.generate(
      widget.count,
      (index) => _buildSkeleton(),
    );

    if (widget.direction == Axis.horizontal) {
      return Row(
        children: children
            .expand((w) => [w, SizedBox(width: widget.spacing)])
            .toList()
          ..removeLast(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children.expand((w) => [w, SizedBox(height: widget.spacing)]).toList()
            ..removeLast(),
    );
  }

  Widget _buildSkeleton() {
    switch (widget.type) {
      case SkeletonType.courseCard:
        return _buildCourseCardSkeleton();
      case SkeletonType.listItem:
        return _buildListItemSkeleton();
      case SkeletonType.text:
        return _buildTextSkeleton();
      case SkeletonType.avatar:
        return _buildAvatarSkeleton();
      case SkeletonType.button:
        return _buildButtonSkeleton();
      case SkeletonType.custom:
        return _buildCustomSkeleton();
    }
  }

  Widget _buildCourseCardSkeleton() {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(
              height: 120, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 12),
          _buildShimmerBox(height: 16, width: 160),
          const SizedBox(height: 8),
          _buildShimmerBox(height: 14, width: 100),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildShimmerBox(height: 14, width: 60),
              const SizedBox(width: 8),
              _buildShimmerBox(height: 14, width: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton() {
    return Row(
      children: [
        _buildShimmerBox(
            width: 60, height: 60, borderRadius: BorderRadius.circular(8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(height: 16),
              const SizedBox(height: 8),
              _buildShimmerBox(height: 14, width: 120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextSkeleton() {
    return _buildShimmerBox(
      width: widget.width,
      height: widget.height ?? 16,
    );
  }

  Widget _buildAvatarSkeleton() {
    return _buildShimmerBox(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      borderRadius: BorderRadius.circular((widget.width ?? 48) / 2),
    );
  }

  Widget _buildButtonSkeleton() {
    return _buildShimmerBox(
      width: widget.width ?? 120,
      height: widget.height ?? 44,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildCustomSkeleton() {
    return _buildShimmerBox(
      width: widget.width,
      height: widget.height ?? 20,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
    );
  }

  Widget _buildShimmerBox({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
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
      },
    );
  }
}
