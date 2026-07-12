// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/models/course_commerce_models.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/shared_widgets/report_dialog.dart';
import 'package:lms_platform/core/services/reports_service.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_cubit.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_state.dart';
import 'package:lms_platform/features/student/course_player/data/services/youtube_stream_service.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/lesson_entity.dart';
import 'package:lms_platform/features/student/course_details/presentation/cubit/course_details_cubit.dart';
import 'package:lms_platform/features/student/course_details/presentation/cubit/course_details_state.dart';
import 'course_preview_player_screen.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/course_hero_section.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/course_info_section.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/instructor_card.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/course_stats_grid.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/what_you_learn_section.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/curriculum_section.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/reviews_section.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/bottom_price_bar.dart';
import 'package:lms_platform/features/student/course_details/presentation/widgets/course_details/course_details_skeleton.dart';

/// Course Details Screen
class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 150;
    if (showTitle != _showTitle) {
      setState(() => _showTitle = showTitle);
    }
  }

  void _loadCourseDetails() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    context.read<CourseDetailsCubit>().loadCourseDetails(
          widget.courseId,
          userId: userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale.languageCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: BlocBuilder<CourseDetailsCubit, CourseDetailsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return _buildLoading();
            }

            if (state.isError) {
              return _buildError(state.errorMessage ?? '');
            }

            if (state.course == null) {
              return _buildError(
                'course_details.not_found'.tr(),
                type: ErrorType.notFound,
              );
            }

            return _buildContent(state, locale, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildContent(CourseDetailsState state, String locale, bool isDark) {
    final course = state.course!;
    int sectionIndex = 0;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(course, locale, isDark),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section with animation
                  FadeIn(
                    duration: const Duration(milliseconds: 400),
                    child: CourseHeroSection(
                      course: course,
                      scrollController: _scrollController,
                      onPlayPreview: () => _playPreview(course),
                    ),
                  ),
                  // Course Info with staggered animation
                  SlideFadeIn.fromBottom(
                    delay: Duration(milliseconds: 100 * sectionIndex++),
                    child: CourseInfoSection(course: course, locale: locale),
                  ),
                  // Instructor Card with animation
                  if (course.instructor != null)
                    SlideFadeIn.fromBottom(
                      delay: Duration(milliseconds: 100 * sectionIndex++),
                      child: InstructorCard(
                        instructor: course.instructor!,
                        locale: locale,
                        onTap: () =>
                            _navigateToInstructor(course.instructor!.id),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Stats Grid with animation
                  SlideFadeIn.fromBottom(
                    delay: Duration(milliseconds: 100 * sectionIndex++),
                    child: CourseStatsGrid(course: course),
                  ),
                  // What You Learn with animation
                  SlideFadeIn.fromBottom(
                    delay: Duration(milliseconds: 100 * sectionIndex++),
                    child: WhatYouLearnSection(objectives: course.objectives),
                  ),
                  const SizedBox(height: 8),
                  // Curriculum with expandable animation
                  SlideFadeIn.fromBottom(
                    delay: Duration(milliseconds: 100 * sectionIndex++),
                    child: CurriculumSection(
                      sections: course.sections,
                      locale: locale,
                      expandedSections: state.expandedSections,
                      onToggleSection: (index) {
                        context.read<CourseDetailsCubit>().toggleSection(index);
                      },
                      onLessonTap: course.isEnrolled
                          ? null
                          : (lesson) => _playLessonPreview(course, lesson),
                      isEnrolled: course.isEnrolled,
                    ),
                  ),
                  if (course.instructor != null) ...[
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark ? AppColors.borderDark : AppColors.grey200,
                    ),
                    SlideFadeIn.fromBottom(
                      delay: Duration(milliseconds: 100 * sectionIndex++),
                      child: InstructorCard(
                        instructor: course.instructor!,
                        locale: locale,
                        isCompact: false,
                        onTap: () =>
                            _navigateToInstructor(course.instructor!.id),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(
                    color: isDark ? AppColors.borderDark : AppColors.grey200,
                  ),
                  // Reviews Section with animation
                  SlideFadeIn.fromBottom(
                    delay: Duration(milliseconds: 100 * sectionIndex++),
                    child: ReviewsSection(
                      reviews: state.reviews,
                      ratingDistribution: state.ratingDistribution,
                      averageRating: course.rating,
                      totalReviews: course.ratingCount,
                      onSeeAll: () => _navigateToReviews(course.id),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        // Bottom price bar with animation
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideFadeIn.fromBottom(
            duration: const Duration(milliseconds: 400),
            child: BottomPriceBar(
              course: course,
              isLoading: _isAddingToCart,
              onEnroll: () => _handleEnrollFree(course),
              onAddToCart: () => _handleAddToCart(course),
              onGoToCart: _navigateToCart,
              onStartLearning: () => _navigateToCoursePlayer(course.id),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(CourseDetailsEntity course, String locale, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go('/home'),
      ),
      title: AnimatedOpacity(
        opacity: _showTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          course.getTitle(locale),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        // Cart button with badge
        ScaleIn(
          delay: const Duration(milliseconds: 100),
          child: _buildCartButton(isDark),
        ),
        // Wishlist button
        ScaleIn(
          delay: const Duration(milliseconds: 200),
          child: BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, wishlistState) {
              return BlocBuilder<CourseDetailsCubit, CourseDetailsState>(
                builder: (context, state) {
                  final isInWishlist = state.course != null
                      ? wishlistState.isInWishlist(state.course!.id)
                      : false;
                  return IconButton(
                    icon: Icon(
                      isInWishlist
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: state.isWishlistLoading
                        ? null
                        : () =>
                            context.read<CourseDetailsCubit>().toggleWishlist(),
                  );
                },
              );
            },
          ),
        ),
        // More options menu
        ScaleIn(
          delay: const Duration(milliseconds: 300),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'report':
                  _reportCourse(course, locale);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 20, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text(
                      locale == 'ar' ? 'الإبلاغ عن مشكلة' : 'Report Problem',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartButton(bool isDark) {
    // Use singleton CartCubit from service locator
    final cartCubit = sl<CartCubit>();
    return BlocBuilder<CartCubit, CartState>(
      bloc: cartCubit,
      builder: (context, cartState) {
        final itemCount = cartState.cart?.itemsCount ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: _navigateToCart,
            ),
            if (itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    itemCount > 9 ? '9+' : '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return const CourseDetailsSkeleton();
  }

  Widget _buildError(
    String message, {
    ErrorType type = ErrorType.generic,
  }) {
    return ErrorState(
      type: type,
      message: message,
      onRetry: _loadCourseDetails,
    );
  }

  // Navigation methods
  void _playPreview(CourseDetailsEntity course) {
    final rawUrl = (course.previewVideoUrl ?? '').trim();
    if (rawUrl.isEmpty) {
      _showErrorSnackBar('course_details.preview_not_available'.tr());
      return;
    }

    final normalizedUrl = _normalizePreviewUrl(rawUrl);
    if (normalizedUrl == null) {
      _showErrorSnackBar('course_details.invalid_preview_link'.tr());
      return;
    }

    final videoId = YouTubeStreamService.extractVideoId(normalizedUrl);
    if (videoId != null) {
      _openPreviewPlayerScreen(normalizedUrl, course);
      return;
    }

    _showErrorSnackBar('course_details.invalid_preview_link'.tr());
  }

  String? _normalizePreviewUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (url.isEmpty) return null;

    // Allow passing only a YouTube video ID.
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(url)) {
      return 'https://www.youtube.com/watch?v=$url';
    }

    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('www.')) return 'https://$url';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    return uri.toString();
  }

  void _openPreviewPlayerScreen(String videoUrl, CourseDetailsEntity course) {
    final locale = context.locale.languageCode;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoursePreviewPlayerScreen(
          videoUrl: videoUrl,
          courseTitle: course.getTitle(locale),
        ),
      ),
    );
  }

  void _playLessonPreview(CourseDetailsEntity course, LessonEntity lesson) {
    if (!lesson.isPreview) {
      _showErrorSnackBar('course_details.preview_not_available'.tr());
      return;
    }

    final rawUrl = (lesson.videoUrl ?? '').trim();
    if (rawUrl.isEmpty) {
      _showErrorSnackBar('course_details.preview_not_available'.tr());
      return;
    }

    final normalizedUrl = _normalizePreviewUrl(rawUrl);
    if (normalizedUrl == null ||
        YouTubeStreamService.extractVideoId(normalizedUrl) == null) {
      _showErrorSnackBar('course_details.invalid_preview_link'.tr());
      return;
    }

    _openPreviewPlayerScreen(normalizedUrl, course);
  }

  void _navigateToInstructor(String instructorId) {
    AppRouter.goToInstructor(context, instructorId);
  }

  void _navigateToReviews(String courseId) {
    // TODO: Navigate to all reviews
  }

  void _navigateToCart() {
    AppRouter.goToCart(context);
  }

  void _navigateToCoursePlayer(String courseId) {
    final state = context.read<CourseDetailsCubit>().state;
    final course = state.course;
    if (course == null) return;

    final locale = context.locale.languageCode;

    // If enrolled, navigate to course player
    if (course.isEnrolled && course.enrollmentId != null) {
      AppRouter.goToCoursePlayer(
        context,
        courseId: courseId,
        enrollmentId: course.enrollmentId!,
        courseTitle: course.getTitle(locale),
        instructorId: course.instructor?.id,
        instructorName: course.instructor?.displayName,
        instructorAvatar: course.instructor?.avatarUrl,
      );
    }
  }

  Future<void> _handleEnrollFree(CourseDetailsEntity course) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      _showErrorSnackBar('auth.login_required'.tr());
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final success =
          await context.read<CourseDetailsCubit>().enrollFreeCourse(userId);
      if (mounted) {
        setState(() => _isAddingToCart = false);
        if (success) {
          _showSuccessSnackBar('course_details.enrolled_successfully'.tr());
          // Navigate to course player directly or let it reload and stay
        } else {
          _showErrorSnackBar('errors.unknown'.tr());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _showErrorSnackBar('errors.unknown'.tr());
      }
    }
  }

  Future<void> _handleAddToCart(CourseDetailsEntity course) async {
    // Get current user ID from Supabase
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      AppLogger.e('[CourseDetails] User not logged in!');
      _showErrorSnackBar('auth.login_required'.tr());
      return;
    }

    // Get the singleton CartCubit
    final cartCubit = sl<CartCubit>();

    AppLogger.i('🛒 [CourseDetails] Checking cart - courseId: ${course.id}');
    AppLogger.i(
        '🛒 [CourseDetails] CartCubit userId: ${cartCubit.currentUserId}');
    AppLogger.i(
        '🛒 [CourseDetails] Cart items count: ${cartCubit.state.cart?.itemsCount ?? 0}');

    // Set userId and load cart if not already loaded
    if (cartCubit.currentUserId == null || cartCubit.currentUserId != userId) {
      AppLogger.i('🛒 [CourseDetails] Loading cart first...');
      cartCubit.setUserId(userId);
      await cartCubit.loadCart(userId);
    }

    // Check if course is already in cart (after loading)
    if (cartCubit.isInCart(course.id)) {
      AppLogger.i('[CourseDetails] Course already in cart, navigating to cart');
      _showInfoSnackBar('cart.already_in_cart'.tr());
      AppRouter.goToCart(context);
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      AppLogger.i(
          '🛒 [CourseDetails] Adding to cart - userId: $userId, courseId: ${course.id}');

      final selectedOption = await _selectPricingOptionIfNeeded(course);
      if (!mounted) return;
      if (course.pricingOptions.isNotEmpty && selectedOption == null) {
        setState(() => _isAddingToCart = false);
        return;
      }

      final success = await cartCubit.addToCart(
        course.id,
        pricingOption: selectedOption,
      );

      if (mounted) {
        setState(() => _isAddingToCart = false);

        if (success) {
          AppLogger.success('[CourseDetails] Added to cart successfully');
          _showSuccessSnackBar('cart.added_to_cart'.tr());
          AppRouter.goToCart(context);
        } else {
          final errorMsg = cartCubit.state.addToCartError;
          if (errorMsg != null && errorMsg.isNotEmpty) {
            _showErrorSnackBar(
                errorMsg.contains('.') ? errorMsg.tr() : errorMsg);
          } else {
            // Course might be already in cart
            _showInfoSnackBar('cart.already_in_cart'.tr());
            AppRouter.goToCart(context);
          }
        }
      }
    } catch (e, stack) {
      AppLogger.e('[CourseDetails] Error adding to cart', e, stack);
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _showErrorSnackBar('cart.add_failed'.tr());
      }
    }
  }

  void _showInfoSnackBar(String message) {
    AnimatedSnackbar.show(
      context: context,
      message: message,
      type: SnackbarType.info,
      actionLabel: 'cart.cart'.tr(),
      onActionPressed: () => AppRouter.goToCart(context),
    );
  }

  Future<CoursePricingOption?> _selectPricingOptionIfNeeded(
    CourseDetailsEntity course,
  ) async {
    if (course.pricingOptions.isEmpty) return null;

    final locale = context.locale.languageCode;
    final isArabic = locale == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'اختر مدة الاشتراك' : 'Choose subscription option',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 12),
                ...course.pricingOptions.map((option) {
                  final hasDiscount = option.discountPrice != null &&
                      option.discountPrice! < option.price;
                  final discountPct = hasDiscount
                      ? ((option.price - option.discountPrice!) /
                              option.price *
                              100)
                          .round()
                      : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      title: Text(option.label),
                      subtitle: option.durationDays == null
                          ? null
                          : Text(
                              isArabic
                                  ? '${option.durationDays} يوم'
                                  : '${option.durationDays} days',
                            ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              '${course.currency} ${option.discountPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                                fontSize: 15,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${course.currency} ${option.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-$discountPct%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              '${course.currency} ${option.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).pop(option),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    AnimatedSnackbar.showSuccess(
      context: context,
      message: message,
    );
  }

  void _showErrorSnackBar(String message) {
    AnimatedSnackbar.showError(
      context: context,
      message: message,
    );
  }

  void _reportCourse(CourseDetailsEntity course, String locale) {
    ReportDialog.show(
      context,
      targetType: ReportTargetType.course,
      targetId: course.id,
      targetTitle: course.getTitle(locale),
    );
  }
}
