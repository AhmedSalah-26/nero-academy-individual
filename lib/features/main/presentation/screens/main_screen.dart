import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../my_learning/presentation/cubit/my_learning_cubit.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../settings/presentation/cubit/profile_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

/// Main Screen with Bottom Navigation Bar using StatefulShellRoute
class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final HomeCubit _homeCubit;
  late final MyLearningCubit _myLearningCubit;
  late final WishlistCubit _wishlistCubit;
  late final CartCubit _cartCubit;
  late final ProfileCubit _profileCubit;
  late final SettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = sl<HomeCubit>();
    _myLearningCubit = sl<MyLearningCubit>();
    _wishlistCubit = sl<WishlistCubit>();
    _cartCubit = sl<CartCubit>();
    _profileCubit = sl<ProfileCubit>();
    _settingsCubit = sl<SettingsCubit>();
    _initCubits();
  }

  void _initCubits() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _homeCubit.loadHomeData();
      _myLearningCubit.loadMyLearning(user.id);

      if (_wishlistCubit.currentUserId == null) {
        _wishlistCubit.loadWishlist(user.id);
      }
      if (_cartCubit.currentUserId == null) {
        _cartCubit.loadCart(user.id);
      }
      if (_profileCubit.currentUserId == null) {
        _profileCubit.loadProfile(user.id);
      }
      if (_settingsCubit.currentUserId == null) {
        _settingsCubit.loadSettings(user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentIndex = widget.navigationShell.currentIndex;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider.value(value: _myLearningCubit),
        BlocProvider.value(value: _wishlistCubit),
        BlocProvider.value(value: _cartCubit),
        BlocProvider.value(value: _profileCubit),
        BlocProvider.value(value: _settingsCubit),
      ],
      child: PopScope(
        canPop: currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && currentIndex != 0) {
            HapticFeedback.selectionClick();
            widget.navigationShell.goBranch(0);
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            extendBody: false,
            body: widget.navigationShell,
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.09,
                  right: screenWidth * 0.09,
                  bottom: screenWidth * 0.032,
                  top: screenWidth * 0.014,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.035,
                        vertical: screenWidth * 0.018,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark.withValues(alpha: 0.58)
                            : Colors.white.withValues(alpha: 0.52),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            isSelected: currentIndex == 0,
                            onTap: () => _onTabTapped(0),
                          ),
                          _NavItem(
                            icon: Icons.play_circle_outline_rounded,
                            activeIcon: Icons.play_circle_rounded,
                            isSelected: currentIndex == 1,
                            onTap: () => _onTabTapped(1),
                          ),
                          _NavItem(
                            icon: Icons.forum_outlined,
                            activeIcon: Icons.forum_rounded,
                            isSelected: currentIndex == 2,
                            onTap: () => _onTabTapped(2),
                          ),
                          _NavItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            isSelected: currentIndex == 3,
                            onTap: () => _onTabTapped(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // Refresh data when entering each tab
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      switch (index) {
        case 0:
          _homeCubit.loadHomeData();
          break;
        case 1:
          _myLearningCubit.loadMyLearning(user.id);
          break;
      }
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.052).clamp(21.0, 24.0);
    final padding = (screenWidth * 0.021).clamp(8.0, 10.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04)
              : Colors.transparent,
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.22 : 0.16,
                  ),
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          size: iconSize,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.grey400 : AppColors.grey500),
        ),
      ),
    );
  }
}
