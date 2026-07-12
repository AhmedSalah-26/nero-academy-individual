import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// User Avatar Sizes
enum AvatarSize { xs, sm, md, lg, xl }

/// Unified User Avatar Widget
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AvatarSize size;
  final bool showBorder;
  final Color? borderColor;
  final bool isVerified;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.md,
    this.showBorder = false,
    this.borderColor,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = _getRadius();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: borderColor ??
                          AppColors.primary.withValues(alpha: 0.4),
                      width: 2,
                    )
                  : null,
            ),
            child: CircleAvatar(
              radius: radius - (showBorder ? 2 : 0),
              backgroundColor: isDark
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.15),
              child: _buildContent(isDark, radius),
            ),
          ),
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _getVerifiedSize(),
                height: _getVerifiedSize(),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.backgroundDark : AppColors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  size: _getVerifiedSize() * 0.6,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, double radius) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildPlaceholder(isDark, radius),
          errorWidget: (_, __, ___) => _buildInitials(isDark, radius),
        ),
      );
    }
    return _buildInitials(isDark, radius);
  }

  Widget _buildPlaceholder(bool isDark, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey700 : AppColors.grey200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: radius * 0.6,
          height: radius * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(bool isDark, double radius) {
    final initials = _getInitials();
    return Center(
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            )
          : Icon(
              Icons.person,
              size: radius,
              color: AppColors.primary,
            ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  double _getRadius() {
    switch (size) {
      case AvatarSize.xs:
        return 16;
      case AvatarSize.sm:
        return 20;
      case AvatarSize.md:
        return 24;
      case AvatarSize.lg:
        return 32;
      case AvatarSize.xl:
        return 48;
    }
  }

  double _getVerifiedSize() {
    switch (size) {
      case AvatarSize.xs:
        return 12;
      case AvatarSize.sm:
        return 14;
      case AvatarSize.md:
        return 16;
      case AvatarSize.lg:
        return 20;
      case AvatarSize.xl:
        return 24;
    }
  }
}
