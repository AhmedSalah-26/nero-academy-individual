import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/course_details_cubit.dart';
import '../cubit/course_details_state.dart';
import '../widgets/course_details/reviews_section.dart';

/// Displays every review for a course and loads additional pages on demand.
class CourseReviewsScreen extends StatelessWidget {
  final String courseId;

  const CourseReviewsScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('course_details.student_reviews'.tr()),
        centerTitle: true,
      ),
      body: BlocBuilder<CourseDetailsCubit, CourseDetailsState>(
        builder: (context, state) {
          if (state.reviews.isEmpty) {
            if (state.isReviewsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return const EmptyState(type: EmptyStateType.reviews);
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 240 &&
                  state.hasMoreReviews &&
                  !state.isReviewsLoading) {
                context
                    .read<CourseDetailsCubit>()
                    .loadReviews(courseId, loadMore: true);
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.reviews.length +
                  (state.isReviewsLoading || state.hasMoreReviews ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == state.reviews.length) {
                  if (!state.isReviewsLoading) {
                    return const SizedBox(height: 24);
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return CourseReviewCard(review: state.reviews[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
