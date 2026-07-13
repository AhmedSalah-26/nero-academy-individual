import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lms_platform/core/services/teacher_context_service.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';
import 'home_app_bar.dart';

class HomeSliverAppBar extends StatelessWidget {
  final String? userName;

  const HomeSliverAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toolbarHeight = (w * 0.24).clamp(92.0, 108.0);
    final expandedHeight =
        (w * 0.58 + toolbarHeight + 54.0).clamp(335.0, 395.0);

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: expandedHeight,
      toolbarHeight: toolbarHeight,
      titleSpacing: 0,
      title: HomeAppBar(userName: userName),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: toolbarHeight),
              Expanded(
                child: _HeroVisual(isDark: isDark),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(46.0 + (w * 0.038) + 8.0),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.038,
            top: 8,
          ),
          child: GlassSearchBar(
            hintText: 'home.search_placeholder'.tr(),
            onTap: () => context.pushNamed('search'),
            readOnly: true,
            height: 46,
            borderRadius: 12,
            iconSize: w * 0.05,
            hintStyle: TextStyle(fontSize: w * 0.033),
          ),
        ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final bool isDark;

  const _HeroVisual({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        ValueListenableBuilder<SelectedTeacher?>(
          valueListenable: TeacherContextService.instance.selectedTeacher,
          builder: (context, teacher, _) {
            final customImageUrl = (teacher?.theme.logoUrl ?? '').trim();
            final fallbackAsset = isDark
                ? 'assets/default_identity/default_teacher_cover_dark.png'
                : 'assets/default_identity/default_teacher_cover_light.png';

            if (customImageUrl.isNotEmpty) {
              return Image.network(
                customImageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  fallbackAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              );
            }

            return Image.asset(
              fallbackAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            );
          },
        ),
      ],
    );
  }
}
