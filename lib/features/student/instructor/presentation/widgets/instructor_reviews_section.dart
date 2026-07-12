import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Review Model
class InstructorReview {
  final String id;
  final String studentName;
  final String? studentAvatarUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? courseName;

  const InstructorReview({
    required this.id,
    required this.studentName,
    this.studentAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.courseName,
  });
}

/// Instructor Reviews Section
class InstructorReviewsSection extends StatelessWidget {
  final List<InstructorReview> reviews;
  final double averageRating;
  final int totalReviews;
  final bool isDark;
  final VoidCallback? onSeeAllTap;

  const InstructorReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
    required this.isDark,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rate_review_rounded,
                    size: 20,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'instructor.reviews'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.textMainLight,
                    ),
                  ),
                ],
              ),
              if (onSeeAllTap != null)
                GestureDetector(
                  onTap: onSeeAllTap,
                  child: Text(
                    'home.see_all'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Rating Summary
        _buildRatingSummary(),
        const SizedBox(height: 16),
        // Reviews List
        if (reviews.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reviews.length > 3 ? 3 : reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ReviewCard(
                review: reviews[index],
                isDark: isDark,
              );
            },
          ),
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Big Rating Number
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < averageRating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.warning,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalReviews ${'instructor.reviews'.tr()}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Rating Bars
          Expanded(
            child: Column(
              children: [
                _RatingBar(stars: 5, percentage: 0.7, isDark: isDark),
                _RatingBar(stars: 4, percentage: 0.2, isDark: isDark),
                _RatingBar(stars: 3, percentage: 0.06, isDark: isDark),
                _RatingBar(stars: 2, percentage: 0.03, isDark: isDark),
                _RatingBar(stars: 1, percentage: 0.01, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              'instructor.no_reviews'.tr(),
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final double percentage;
  final bool isDark;

  const _RatingBar({
    required this.stars,
    required this.percentage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: isDark ? AppColors.grey700 : AppColors.grey200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.warning),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final InstructorReview review;
  final bool isDark;

  const _ReviewCard({
    required this.review,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: review.studentAvatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: review.studentAvatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildAvatarPlaceholder(),
                          errorWidget: (_, __, ___) =>
                              _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
              ),
              const SizedBox(width: 10),
              // Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.studentName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Comment
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // Course Name
          if (review.courseName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    review.courseName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.grey400,
        size: 24,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'common.today'.tr();
    } else if (diff.inDays == 1) {
      return 'common.yesterday'.tr();
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${'common.days_ago'.tr()}';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} ${'common.weeks_ago'.tr()}';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} ${'common.months_ago'.tr()}';
    } else {
      return DateFormat('MMM yyyy').format(date);
    }
  }
}
