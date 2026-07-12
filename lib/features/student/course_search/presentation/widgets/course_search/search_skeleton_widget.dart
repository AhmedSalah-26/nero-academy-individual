import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Search Skeleton Widget - Loading placeholder for course cards
class SearchSkeletonWidget extends StatelessWidget {
  const SearchSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          _SkeletonBox(
            width: 112,
            height: 84,
            borderRadius: 8,
            isDark: isDark,
          ),
          const SizedBox(width: 12),

          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _SkeletonBox(
                  width: 120,
                  height: 12,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _SkeletonBox(
                  width: 80,
                  height: 12,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton Box - Animated placeholder box
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isDark;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
    required this.isDark,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
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

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: widget.isDark
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
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Search Skeleton List - Multiple skeleton cards
class SearchSkeletonList extends StatelessWidget {
  final int itemCount;

  const SearchSkeletonList({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const SearchSkeletonWidget(),
    );
  }
}
