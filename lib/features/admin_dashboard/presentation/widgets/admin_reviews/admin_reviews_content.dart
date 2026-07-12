import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/error_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/admin_reviews_cubit.dart';

/// Admin Reviews Content
class AdminReviewsContent extends StatefulWidget {
  const AdminReviewsContent({super.key});

  @override
  State<AdminReviewsContent> createState() => _AdminReviewsContentState();
}

class _AdminReviewsContentState extends State<AdminReviewsContent> {
  @override
  void initState() {
    super.initState();
    context.read<AdminReviewsCubit>().loadReviews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AdminReviewsCubit, AdminReviewsState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic, isDark),
            Expanded(child: _buildBody(context, state, isArabic, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AdminReviewsState state,
      bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DashboardSearchBar(
              hintText: 'Search reviews...',
              hintTextAr: 'بحث في التقييمات...',
              onSearch: (q) => context
                  .read<AdminReviewsCubit>()
                  .loadReviews(search: q.isEmpty ? null : q, refresh: true),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isArabic
                ? '${state.reviews.length} تقييم'
                : '${state.reviews.length} reviews',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminReviewsState state,
      bool isArabic, bool isDark) {
    if (state.status == AdminReviewsStatus.loading && state.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AdminReviewsStatus.error) {
      return ErrorState(
        type: ErrorType.server,
        message: state.errorMessage,
        onRetry: () =>
            context.read<AdminReviewsCubit>().loadReviews(refresh: true),
      );
    }

    if (state.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 48,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا توجد تقييمات' : 'No reviews found'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = state.reviews[index];
        final isHidden = review['is_hidden'] == true;
        return _buildReviewCard(context, review, isArabic, isDark, isHidden);
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> review,
      bool isArabic, bool isDark, bool isHidden) {
    final userName = review['user']?['name'] as String? ?? 'Unknown';
    final courseName =
        review['course']?['title_ar'] as String? ?? 'Unknown Course';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final reviewId = review['id'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHidden
            ? (isDark
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.errorLight)
            : (isDark ? AppColors.cardDark : AppColors.white),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(userName[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(courseName,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.rating,
                  ),
                ),
              ),
              if (isHidden) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isArabic ? 'مخفي' : 'Hidden',
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 11)),
                ),
              ],
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  if (isHidden) {
                    context.read<AdminReviewsCubit>().unhideReview(reviewId);
                  } else {
                    context.read<AdminReviewsCubit>().hideReview(reviewId);
                  }
                },
                icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off,
                    size: 18),
                label: Text(isHidden
                    ? (isArabic ? 'إظهار' : 'Show')
                    : (isArabic ? 'إخفاء' : 'Hide')),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, reviewId, isArabic),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                label: Text(isArabic ? 'حذف' : 'Delete',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String reviewId, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(isArabic
            ? 'هل أنت متأكد من حذف هذا التقييم؟'
            : 'Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminReviewsCubit>().deleteReview(reviewId);
            },
            child: Text(isArabic ? 'حذف' : 'Delete',
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
