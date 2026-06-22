import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/shared_widgets/empty_state.dart';
import '../../../../../core/shared_widgets/loading_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../domain/entities/review_entity.dart';
import 'rating_widgets.dart';

/// Rating Section Widget - Allows users to rate and review the course
class RatingSection extends StatefulWidget {
  final bool isDark;
  final String courseId;
  final String enrollmentId;

  const RatingSection({
    super.key,
    required this.isDark,
    required this.courseId,
    required this.enrollmentId,
  });

  @override
  State<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<RatingSection> {
  final _reviewController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;
  bool _hasExistingRating = false;
  int? _existingRating;
  String? _existingReview;

  // Reviews data
  List<ReviewEntity> _reviews = [];
  bool _isLoadingReviews = false;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  double _averageRating = 0;
  int _totalReviews = 0;
  bool _showWriteReview = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
    _loadAllReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadAllReviews() async {
    AppLogger.i(
        '⭐ [RatingSection] Loading all reviews for course: ${widget.courseId}');
    setState(() => _isLoadingReviews = true);

    try {
      final response = await Supabase.instance.client
          .from('course_reviews')
          .select('''
            id,
            user_id,
            rating,
            review,
            created_at,
            profiles!inner(name, avatar_url)
          ''')
          .eq('course_id', widget.courseId)
          .order('created_at', ascending: false);

      if (mounted) {
        final reviews = (response as List).map((json) {
          return ReviewEntity.fromJson(json);
        }).toList();

        // Calculate statistics
        final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (var review in reviews) {
          distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
        }

        final total = reviews.length;
        final average = total > 0
            ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / total
            : 0.0;

        setState(() {
          _reviews = reviews;
          _ratingDistribution = distribution;
          _totalReviews = total;
          _averageRating = average;
        });

        AppLogger.success('[RatingSection] Loaded ${reviews.length} reviews');
      }
    } catch (e) {
      AppLogger.e('[RatingSection] Error loading reviews: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _loadExistingRating() async {
    AppLogger.i(
        '⭐ [RatingSection] Loading existing rating for course: ${widget.courseId}');
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.w('[RatingSection] User not authenticated');
        return;
      }

      final response = await Supabase.instance.client
          .from('course_reviews')
          .select('rating, review')
          .eq('course_id', widget.courseId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        AppLogger.success(
            '[RatingSection] Found existing rating: ${response['rating']} stars');
        setState(() {
          _hasExistingRating = true;
          _existingRating = response['rating'] as int?;
          _existingReview = response['review'] as String?;
          _rating = _existingRating ?? 0;
          _reviewController.text = _existingReview ?? '';
        });
      } else {
        AppLogger.i('[RatingSection] No existing rating found');
      }
    } catch (e) {
      AppLogger.e('[RatingSection] Error loading rating: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      AppLogger.w('[RatingSection] Rating is 0, cannot submit');
      ToastUtils.showError('course_player.select_rating'.tr());
      return;
    }

    AppLogger.i(
        '⭐ [RatingSection] Submitting rating: $_rating stars for course: ${widget.courseId}');
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.e('[RatingSection] User not authenticated');
        return;
      }

      final reviewText = _reviewController.text.trim();
      final data = {
        'course_id': widget.courseId,
        'user_id': userId,
        'rating': _rating,
        'review': reviewText.isEmpty ? null : reviewText,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_hasExistingRating) {
        // Update existing rating
        AppLogger.i('[RatingSection] Updating existing rating');
        await Supabase.instance.client
            .from('course_reviews')
            .update(data)
            .eq('course_id', widget.courseId)
            .eq('user_id', userId);
        AppLogger.success('[RatingSection] Rating updated successfully');
      } else {
        // Insert new rating
        AppLogger.i('[RatingSection] Inserting new rating');
        data['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client.from('course_reviews').insert(data);
        AppLogger.success('[RatingSection] Rating inserted successfully');
      }

      if (mounted) {
        ToastUtils.showSuccess('course_player.rating_submitted'.tr());
        setState(() {
          _hasExistingRating = true;
          _existingRating = _rating;
          _existingReview = reviewText;
          _showWriteReview = false;
        });
        AppLogger.i('[RatingSection] UI updated with new rating');
        // Reload all reviews to show the new one
        _loadAllReviews();
      }
    } catch (e) {
      AppLogger.e('[RatingSection] Error submitting rating: $e');
      if (mounted) {
        ToastUtils.showError('course_player.rating_submit_error'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_hasExistingRating) {
      return const AppLoadingState.section();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Overview (Amazon style)
          RatingOverview(
            averageRating: _averageRating,
            totalReviews: _totalReviews,
            ratingDistribution: _ratingDistribution,
            isDark: widget.isDark,
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Write Review Button or Form
          if (!_showWriteReview)
            _buildWriteReviewButton()
          else
            WriteReviewForm(
              rating: _rating,
              reviewController: _reviewController,
              hasExistingRating: _hasExistingRating,
              isLoading: _isLoading,
              isDark: widget.isDark,
              onRatingChanged: (rating) => setState(() => _rating = rating),
              onSubmit: _submitRating,
              onCancel: () => setState(() => _showWriteReview = false),
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Reviews List
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildWriteReviewButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _showWriteReview = true;
          });
        },
        icon: const Icon(Icons.edit_outlined),
        label: Text(
          _hasExistingRating
              ? 'course_player.update_rating'.tr()
              : 'course_player.rate_course'.tr(),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoadingReviews) {
      return const AppLoadingState.section();
    }

    if (_reviews.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Center(
          child: EmptyState(
            type: EmptyStateType.reviews,
            compact: true,
            title: 'empty.reviews_title'.tr(),
            message: 'empty.reviews_message'.tr(),
          ),
        ),
      );
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reviews.reviews'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.isDark
                ? AppColors.textMainDark
                : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 16),
        ..._reviews.map((review) => ReviewCard(
              review: review,
              isDark: widget.isDark,
              isCurrentUser: currentUserId == review.userId,
            )),
      ],
    );
  }
}
