import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';
import 'package:lms_platform/core/theme/app_text_styles.dart';

/// Home Search Bar Widget - Responsive
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenWidth * 0.02;
    final searchHeight = (screenHeight * 0.058).clamp(44.0, 52.0);
    final borderRadius = (screenWidth * 0.03).clamp(10.0, 14.0);
    final iconSize = (screenWidth * 0.055).clamp(20.0, 24.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: GlassSearchBar(
        hintText: 'home.search_placeholder'.tr(),
        onTap: () => _navigateToSearch(context),
        readOnly: true,
        height: searchHeight,
        borderRadius: borderRadius,
        iconSize: iconSize,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: (screenWidth * 0.035).clamp(13.0, 15.0),
        ),
        trailing: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: Icon(
            Icons.tune_rounded,
            size: iconSize * 0.9,
          ),
        ),
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    context.pushNamed('search');
  }
}
