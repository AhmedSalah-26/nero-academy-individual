import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Rating Stars Size
enum RatingSize { xs, sm, md, lg }

/// Unified Rating Stars Widget
class RatingStars extends StatelessWidget {
  final double rating;
  final int? ratingCount;
  final RatingSize size;
  final bool showValue;
  final bool showCount;
  final bool interactive;
  final void Function(int)? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.ratingCount,
    this.size = RatingSize.sm,
    this.showValue = true,
    this.showCount = false,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showValue) ...[
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w700,
              color: AppColors.rating,
            ),
          ),
          SizedBox(width: _getSpacing()),
        ],
        ...List.generate(5, (index) => _buildStar(index, isDark)),
        if (showCount && ratingCount != null) ...[
          SizedBox(width: _getSpacing()),
          Text(
            '(${_formatCount(ratingCount!)})',
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: _getFontSize() * 0.9,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int index, bool isDark) {
    final starValue = index + 1;
    final isFilled = rating >= starValue;
    final isHalfFilled = rating > index && rating < starValue;

    IconData icon;
    if (isFilled) {
      icon = Icons.star_rounded;
    } else if (isHalfFilled) {
      icon = Icons.star_half_rounded;
    } else {
      icon = Icons.star_outline_rounded;
    }

    final star = Icon(
      icon,
      size: _getIconSize(),
      color: isFilled || isHalfFilled
          ? AppColors.rating
          : (isDark ? AppColors.grey600 : AppColors.grey300),
    );

    if (interactive) {
      return GestureDetector(
        onTap: () => onRatingChanged?.call(starValue),
        child: Padding(
          padding: EdgeInsets.all(_getSpacing() / 2),
          child: star,
        ),
      );
    }

    return star;
  }

  double _getIconSize() {
    switch (size) {
      case RatingSize.xs:
        return 12;
      case RatingSize.sm:
        return 14;
      case RatingSize.md:
        return 18;
      case RatingSize.lg:
        return 24;
    }
  }

  double _getFontSize() {
    switch (size) {
      case RatingSize.xs:
        return 11;
      case RatingSize.sm:
        return 12;
      case RatingSize.md:
        return 14;
      case RatingSize.lg:
        return 18;
    }
  }

  double _getSpacing() {
    switch (size) {
      case RatingSize.xs:
        return 2;
      case RatingSize.sm:
        return 4;
      case RatingSize.md:
        return 6;
      case RatingSize.lg:
        return 8;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
