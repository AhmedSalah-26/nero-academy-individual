import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_text_styles.dart';
import 'package:lms_platform/features/student/home/domain/entities/banner_entity.dart';

/// Home Banner Carousel Widget - Responsive
class HomeBannerCarousel extends StatefulWidget {
  final List<BannerEntity> banners;
  final String locale;

  const HomeBannerCarousel(
      {super.key, required this.banners, required this.locale});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.banners.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.banners.length;
      _pageController.animateToPage(nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = (screenHeight * 0.17).clamp(118.0, 155.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
          child: SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: widget.banners.length,
              itemBuilder: (context, index) => _BannerItem(
                banner: widget.banners[index],
                locale: widget.locale,
                screenWidth: screenWidth,
              ),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        _DotsIndicator(
            count: widget.banners.length, currentIndex: _currentPage),
      ],
    );
  }
}

class _BannerItem extends StatelessWidget {
  final BannerEntity banner;
  final String locale;
  final double screenWidth;

  const _BannerItem(
      {required this.banner, required this.locale, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              banner.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                      errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 48),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.8)
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: screenWidth * 0.035,
                right: screenWidth * 0.035,
                bottom: screenWidth * 0.032,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.022,
                          vertical: screenWidth * 0.009),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(5)),
                      child: Text('home.flash_sale'.tr(),
                          style: AppTextStyles.badge
                              .copyWith(color: AppColors.white, fontSize: 9)),
                    ),
                    SizedBox(height: screenWidth * 0.014),
                    if (banner.getTitle(locale).isNotEmpty)
                      Text(
                        banner.getTitle(locale),
                        style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: screenWidth * 0.038),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (banner.getSubtitle(locale).isNotEmpty) ...[
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        banner.getSubtitle(locale),
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: screenWidth * 0.027),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _DotsIndicator({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.grey300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
