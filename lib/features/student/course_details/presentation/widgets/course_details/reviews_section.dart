import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/rating_stars.dart';
import 'package:lms_platform/core/shared_widgets/report_dialog.dart';
import 'package:lms_platform/core/services/reports_service.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/review_entity.dart';

/// Reviews Section - Amazon-style reviews display
class ReviewsSection extends StatelessWidget {
  final List<ReviewEntity> reviews;
  final Map<int, int> ratingDistribution;
  final double averageRating;
  final int totalReviews;
  final VoidCallback? onSeeAll;

  const ReviewsSection({
    super.key,
    required this.reviews,
    required this.ratingDistribution,
    required this.averageRating,
    required this.totalReviews,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'course_details.student_reviews'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'course_details.see_all'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Rating Overview (Amazon style)
          _buildRatingOverview(isDark),

          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Reviews List (show first 3)
            ...reviews.take(3).map((review) => Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildReviewCard(context, review, isDark),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingOverview(bool isDark) {
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
                '$totalReviews تقييم',
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

  Widget _buildReviewCard(
      BuildContext context, ReviewEntity review, bool isDark) {
    return Container(
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
                backgroundImage: review.userAvatarUrl != null &&
                        review.userAvatarUrl!.isNotEmpty
                    ? NetworkImage(review.userAvatarUrl!)
                    : null,
                child: review.userAvatarUrl == null ||
                        review.userAvatarUrl!.isEmpty
                    ? Text(
                        (review.userName ?? 'U')[0].toUpperCase(),
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
                    Text(
                      review.userName ?? 'مستخدم',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
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
              // Report button
              _buildReportButton(context, review, isDark),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).floor()} أسابيع';
    } else if (difference.inDays < 365) {
      return 'منذ ${(difference.inDays / 30).floor()} أشهر';
    } else {
      return 'منذ ${(difference.inDays / 365).floor()} سنة';
    }
  }

  Widget _buildReportButton(
      BuildContext context, ReviewEntity review, bool isDark) {
    final isArabic = context.locale.languageCode == 'ar';
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
                isArabic ? 'الإبلاغ' : 'Report',
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
            reviewComment: review.comment,
            reviewRating: review.rating,
          );
        }
      },
    );
  }
}
