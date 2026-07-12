import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/rating_stars.dart';
import 'package:lms_platform/core/shared_widgets/report_dialog.dart';
import 'package:lms_platform/core/services/reports_service.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/review_entity.dart';

/// Rating Overview Widget - Shows average rating and distribution (Amazon style)
class RatingOverview extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final bool isDark;

  const RatingOverview({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Average rating
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              RatingStars(
                rating: averageRating,
                size: RatingSize.lg,
                showValue: false,
              ),
              const SizedBox(height: 8),
              Text(
                'course_player.review_count'
                    .tr(args: [totalReviews.toString()]),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right side: Rating distribution
        Expanded(
          flex: 3,
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count = ratingDistribution[star] ?? 0;
              final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 16, color: AppColors.rating),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor:
                              isDark ? AppColors.grey700 : AppColors.grey200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.rating),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Review Card Widget - Shows a single review
class ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final bool isDark;
  final bool isCurrentUser;

  const ReviewCard({
    super.key,
    required this.review,
    required this.isDark,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: review.userAvatar != null
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null
                    ? Text(
                        review.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'course_player.you'.tr(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingStars(
                          rating: review.rating.toDouble(),
                          size: RatingSize.sm,
                          showValue: false,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Report button (only for other users' reviews)
              if (!isCurrentUser) _buildReportButton(context),
            ],
          ),
          if (review.review != null && review.review!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.review!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'course_player.today'.tr();
    } else if (difference.inDays == 1) {
      return 'course_player.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return 'course_player.days_ago'.tr(args: [difference.inDays.toString()]);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'course_player.weeks_ago'.tr(args: [weeks.toString()]);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'course_player.months_ago'.tr(args: [months.toString()]);
    } else {
      final years = (difference.inDays / 365).floor();
      return 'course_player.years_ago'.tr(args: [years.toString()]);
    }
  }

  Widget _buildReportButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: isDark ? AppColors.textMutedDark : AppColors.grey400,
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'course_player.report'.tr(),
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'report') {
          ReportDialog.show(
            context,
            targetType: ReportTargetType.review,
            targetId: review.id,
            reviewerId: review.userId,
            reviewComment: review.review,
            reviewRating: review.rating,
          );
        }
      },
    );
  }
}

/// Write Review Form Widget
class WriteReviewForm extends StatelessWidget {
  final int rating;
  final TextEditingController reviewController;
  final bool hasExistingRating;
  final bool isLoading;
  final bool isDark;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const WriteReviewForm({
    super.key,
    required this.rating,
    required this.reviewController,
    required this.hasExistingRating,
    required this.isLoading,
    required this.isDark,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'course_player.your_rating'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text('common.cancel'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Rating Stars
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: AppColors.rating,
                  ),
                ),
              );
            }),
          ),
        ),
        if (rating > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$rating / 5',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        // Review Text Field
        TextField(
          controller: reviewController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'course_player.write_review'.tr(),
            hintStyle: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 16),
        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    hasExistingRating
                        ? 'course_player.update_rating'.tr()
                        : 'course_player.submit_rating'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
