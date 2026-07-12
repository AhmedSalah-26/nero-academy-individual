import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/features/student/course_player/presentation/cubit/course_player_state.dart';

/// Loading State Widget with Shimmer Effect
class PlayerLoadingState extends StatelessWidget {
  final bool isDark;

  const PlayerLoadingState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Video Player Skeleton
          const LoadingSkeleton(
            type: SkeletonType.custom,
            width: double.infinity,
            height: 220,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: 16),
          // Lesson Header Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton.text(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 20,
                ),
                const SizedBox(height: 8),
                LoadingSkeleton.text(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                ),
                const SizedBox(height: 16),
                // Tabs Skeleton
                Row(
                  children: List.generate(
                    5,
                    (index) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: LoadingSkeleton(
                          type: SkeletonType.custom,
                          width: double.infinity,
                          height: 40,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Content Skeleton
                const LoadingSkeleton.listItem(count: 3, spacing: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error State Widget
class PlayerErrorState extends StatelessWidget {
  final bool isDark;
  final CoursePlayerState state;
  final VoidCallback onRetry;

  const PlayerErrorState({
    super.key,
    required this.isDark,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      type: ErrorType.generic,
      message: state.errorMessage ?? 'course_player.error'.tr(),
      onRetry: onRetry,
    );
  }
}
