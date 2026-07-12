import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Course Details Skeleton - Shimmer loading state
class CourseDetailsSkeleton extends StatelessWidget {
  const CourseDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase;
    final highlightColor =
        isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              height: 220,
              width: double.infinity,
              color: baseColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Container(
                    height: 24,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 24,
                    width: 200,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Rating row
                  Row(
                    children: [
                      Container(
                        height: 16,
                        width: 60,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 16,
                        width: 80,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 16,
                        width: 60,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Instructor card
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats grid - 3 items with equal spacing
                  Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: Container(
                          height: 70,
                          margin: EdgeInsets.only(
                            left: index > 0 ? 6 : 0,
                            right: index < 2 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // What you'll learn section
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Curriculum section
                  Container(
                    height: 20,
                    width: 120,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
