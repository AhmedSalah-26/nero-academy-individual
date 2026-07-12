import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_reviews_cubit.dart';

/// Instructor Reviews Content
class InstructorReviewsContent extends StatefulWidget {
  const InstructorReviewsContent({super.key});

  @override
  State<InstructorReviewsContent> createState() =>
      _InstructorReviewsContentState();
}

class _InstructorReviewsContentState extends State<InstructorReviewsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InstructorReviewsCubit>().loadReviews(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InstructorReviewsCubit>().loadMoreReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<InstructorReviewsCubit, InstructorReviewsState>(
      builder: (context, state) {
        return _buildReviewsList(context, state, isArabic);
      },
    );
  }

  Widget _buildReviewsList(
      BuildContext context, InstructorReviewsState state, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.reviews.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: const LoadingSkeleton(width: double.infinity, height: 100)),
      );
    }

    if (state.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا توجد تقييمات' : 'No reviews found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<InstructorReviewsCubit>().loadReviews(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.reviews.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.reviews.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          final review = state.reviews[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: review.userAvatar != null
                          ? NetworkImage(review.userAvatar!)
                          : null,
                      child: review.userAvatar == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.userName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textMainDark
                                      : AppColors.textMainLight)),
                          Text(review.courseTitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight)),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: AppColors.warning,
                              )),
                    ),
                  ],
                ),
                if (review.comment != null) ...[
                  const SizedBox(height: 12),
                  Text(review.comment!,
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(review.createdAt),
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)),
                    if (review.isFeatured) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(isArabic ? 'مميز' : 'Featured',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.warning)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
