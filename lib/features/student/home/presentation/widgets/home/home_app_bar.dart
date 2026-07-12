import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_text_styles.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_cubit.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_state.dart';
import 'package:lms_platform/features/student/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:lms_platform/features/student/notifications/presentation/cubit/notifications_state.dart';

/// Home App Bar Widget - Responsive
class HomeAppBar extends StatelessWidget {
  final String? userName;

  const HomeAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenWidth * 0.018;

    final helloText = 'home.hello'.tr();
    final displayName = (userName != null && userName!.isNotEmpty)
        ? userName!.trim().split(' ').take(2).join(' ')
        : '';

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    helloText,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      fontWeight: FontWeight.w700,
                      fontSize: (screenWidth * 0.034).clamp(12.0, 14.0),
                      fontFamily: 'Almarai',
                    ),
                  ),
                  if (displayName.isNotEmpty) const SizedBox(height: 2),
                  if (displayName.isNotEmpty)
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: (screenWidth * 0.040).clamp(15.0, 17.0),
                        fontFamily: 'Almarai',
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder<NotificationsCubit, NotificationsState>(
                  bloc: sl<NotificationsCubit>(),
                  builder: (context, state) {
                    final hasUnread =
                        state is NotificationsLoaded && state.unreadCount > 0;
                    return _QuickAction(
                      icon: Icons.notifications_outlined,
                      label: 'تنبيهات',
                      onTap: () => AppRouter.goToNotifications(context),
                      hasNotification: hasUnread,
                    );
                  },
                ),
                const SizedBox(width: 6),
                BlocBuilder<CartCubit, CartState>(
                  bloc: sl<CartCubit>(),
                  builder: (context, state) {
                    return _QuickAction(
                      icon: Icons.shopping_cart_outlined,
                      label: 'المتجر',
                      onTap: () => AppRouter.goToCart(context),
                      badgeCount: state.itemsCount,
                      compactBadge: true,
                    );
                  },
                ),
                const SizedBox(width: 6),
                _QuickAction(
                  icon: Icons.history_rounded,
                  label: 'سجل التعلم',
                  onTap: () => AppRouter.goToHistory(context),
                ),
                const SizedBox(width: 6),
                _QuickAction(
                  icon: Icons.favorite_border_rounded,
                  label: 'المفضلة',
                  onTap: () => AppRouter.goToWishlist(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasNotification;
  final int? badgeCount;
  final bool compactBadge;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasNotification = false,
    this.badgeCount,
    this.compactBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonSize = (screenWidth * 0.095).clamp(36.0, 44.0);
    final iconSize = (screenWidth * 0.052).clamp(20.0, 24.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.26),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: iconSize,
            ),
          ),
          if (hasNotification)
            PositionedDirectional(
              top: -1,
              end: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.cardDark : AppColors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          if ((badgeCount ?? 0) > 0)
            PositionedDirectional(
              top: -5,
              end: -5,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: compactBadge ? 16 : 18,
                  minHeight: compactBadge ? 16 : 18,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark ? AppColors.cardDark : AppColors.white,
                    width: 1,
                  ),
                ),
                child: Text(
                  badgeCount! > 99 ? '99+' : badgeCount.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
