import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/widgets/entry/scale_in.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';

/// Bottom Price Bar - Sticky bottom bar with price and CTA
class BottomPriceBar extends StatelessWidget {
  final CourseDetailsEntity course;
  final VoidCallback? onEnroll;
  final VoidCallback? onAddToCart;
  final VoidCallback? onGoToCart;
  final VoidCallback? onStartLearning;
  final bool isLoading;

  const BottomPriceBar({
    super.key,
    required this.course,
    this.onEnroll,
    this.onAddToCart,
    this.onGoToCart,
    this.onStartLearning,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.grey200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildPriceSection(isDark)),
          const SizedBox(width: 16),
          _buildCTAButton(isDark),
        ],
      ),
    );
  }

  Widget _buildPriceSection(bool isDark) {
    if (course.isFree) {
      return Text(
        'course_details.free'.tr(),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      );
    }

    final hasDiscount = course.discountPercentage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                'EGP ${course.currentPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${course.discountPercentage}% ${'course_details.off'.tr()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasDiscount)
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              'EGP ${course.originalPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCTAButton(bool isDark) {
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = AppColors.primary;

    if (course.isEnrolled) {
      buttonText = course.progressPercentage > 0
          ? 'course_details.continue_learning'.tr()
          : 'course_details.start_learning'.tr();
      onPressed = onStartLearning;
      buttonColor = AppColors.success;
    } else if (course.isFree || course.currentPrice == 0) {
      buttonText = 'course_details.get_for_free'.tr();
      onPressed = onEnroll;
    } else if (course.isInCart) {
      buttonText = 'course_details.go_to_cart'.tr();
      onPressed = onGoToCart;
    } else {
      buttonText = 'cart.add_to_cart'.tr();
      onPressed = onAddToCart;
    }

    return ScaleIn(
      delay: const Duration(milliseconds: 200),
      child: SizedBox(
        width: 160,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: buttonColor.withValues(alpha: 0.3),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
