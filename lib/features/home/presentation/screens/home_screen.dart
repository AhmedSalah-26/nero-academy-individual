import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/animations/animations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/services/app_logger.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home/home_hero_section.dart';
import '../widgets/home/home_banner_carousel.dart';

import '../widgets/home/home_course_section.dart';
import '../widgets/home/home_flash_sale_section.dart';
import '../widgets/home/home_loading_skeleton.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../notifications/presentation/cubit/notifications_cubit.dart';

/// Home Screen - Main screen of the app
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Load notifications for badge indicator
    di.sl<NotificationsCubit>().loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Load user name with timeout
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', user.id)
            .single()
            .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⚠️ [HomeScreen] Profile load timeout');
            return {'name': null};
          },
        );
        if (mounted) {
          setState(() {
            _userName = profile['name'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [HomeScreen] Failed to load user data: $e');
      // Continue without user name - not critical
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    try {
      await Future.wait([
        context.read<HomeCubit>().refreshHomeData(),
        _loadUserData(),
        di.sl<NotificationsCubit>().loadNotifications(),
      ]);
    } catch (e) {
      AppLogger.e('[HomeScreen] Error refreshing', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) {
            if (state.isError && state.errorMessage != null) {
              ToastUtils.showError(state.errorMessage!);
              context.read<HomeCubit>().clearError();
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
              displacement: 40,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  // Sticky Header with Hero Image and Search Bar
                  HomeSliverAppBar(userName: _userName),
                  // Scrollable Content
                  if (state.isLoading)
                    const SliverToBoxAdapter(
                      child: HomeLoadingSkeleton(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildListDelegate(
                        _buildContent(state, isDark),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(HomeState state, bool isDark) {
    final locale = context.locale.languageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final sectionSpacing = screenWidth * 0.055;

    final sections = <Widget>[];
    int sectionIndex = 0;

    // Banner Carousel
    if (state.banners.isNotEmpty) {
      sections.add(
        SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: 100 * sectionIndex++),
          child: Padding(
            padding: EdgeInsets.only(top: screenWidth * 0.04),
            child: HomeBannerCarousel(banners: state.banners, locale: locale),
          ),
        ),
      );
    }

    // Flash Sale Section
    if (state.hasFlashSale) {
      sections.add(
        SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: 100 * sectionIndex++),
          child: Padding(
            padding: EdgeInsets.only(top: sectionSpacing),
            child: HomeFlashSaleSection(
                courses: state.flashSaleCourses, locale: locale),
          ),
        ),
      );
    }

    // Featured Courses Section
    if (state.featuredCourses.isNotEmpty) {
      sections.add(
        SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: 100 * sectionIndex++),
          child: Padding(
            padding: EdgeInsets.only(top: sectionSpacing),
            child: HomeCourseSection(
              title: 'home.featured_courses'.tr(),
              courses: state.featuredCourses,
              locale: locale,
              onSeeAll: () => AppRouter.goToCoursesList(
                context,
                title: 'home.featured_courses'.tr(),
                courses: state.featuredCourses,
              ),
            ),
          ),
        ),
      );
    }

    // Popular Courses Section
    if (state.popularCourses.isNotEmpty) {
      sections.add(
        SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: 100 * sectionIndex++),
          child: Padding(
            padding: EdgeInsets.only(top: sectionSpacing),
            child: HomeCourseSection(
              title: 'home.popular_courses'.tr(),
              courses: state.popularCourses,
              locale: locale,
              onSeeAll: () => AppRouter.goToCoursesList(
                context,
                title: 'home.popular_courses'.tr(),
                courses: state.popularCourses,
              ),
            ),
          ),
        ),
      );
    }

    // New Arrivals Section
    if (state.newCourses.isNotEmpty) {
      sections.add(
        SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: 100 * sectionIndex++),
          child: Padding(
            padding: EdgeInsets.only(top: sectionSpacing),
            child: HomeCourseSection(
              title: 'home.new_arrivals'.tr(),
              courses: state.newCourses,
              locale: locale,
              isVertical: true,
              onSeeAll: () => AppRouter.goToCoursesList(
                context,
                title: 'home.new_arrivals'.tr(),
                courses: state.newCourses,
              ),
            ),
          ),
        ),
      );
    }

    // Bottom Spacing
    sections.add(SizedBox(height: (screenHeight * 0.08).clamp(110.0, 130.0)));

    // If no courses at all, show empty state message
    final hasCourses = state.hasFlashSale ||
        state.featuredCourses.isNotEmpty ||
        state.popularCourses.isNotEmpty ||
        state.newCourses.isNotEmpty;

    if (!hasCourses) {
      sections.insert(
        sections.length - 1,
        _EmptyCoursesState(isDark: isDark),
      );
    }

    return sections;
  }
}

class _EmptyCoursesState extends StatelessWidget {
  final bool isDark;

  const _EmptyCoursesState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          'home.no_courses_available'.tr(),
          style: TextStyle(
            color: isDark ? AppColors.textMutedDark : const Color(0xFF6B7280),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
