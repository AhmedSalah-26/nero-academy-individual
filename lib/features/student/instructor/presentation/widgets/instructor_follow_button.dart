import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Follow Button with animation
class InstructorFollowButton extends StatefulWidget {
  final bool isFollowing;
  final int followersCount;
  final VoidCallback onTap;
  final bool isDark;
  final bool isCompact;

  const InstructorFollowButton({
    super.key,
    required this.isFollowing,
    required this.followersCount,
    required this.onTap,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  State<InstructorFollowButton> createState() => _InstructorFollowButtonState();
}

class _InstructorFollowButtonState extends State<InstructorFollowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactButton();
    }
    return _buildFullButton();
  }

  Widget _buildCompactButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isFollowing
                ? (widget.isDark ? AppColors.cardDark : AppColors.grey100)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            border: widget.isFollowing
                ? Border.all(
                    color: widget.isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isFollowing
                    ? Icons.check_rounded
                    : Icons.person_add_alt_rounded,
                size: 16,
                color: widget.isFollowing
                    ? (widget.isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)
                    : AppColors.white,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isFollowing
                    ? 'instructor.following'.tr()
                    : 'instructor.follow'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isFollowing
                      ? (widget.isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight)
                      : AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isFollowing
                ? (widget.isDark ? AppColors.cardDark : AppColors.grey100)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            border: widget.isFollowing
                ? Border.all(
                    color: widget.isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  )
                : null,
            boxShadow: widget.isFollowing
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isFollowing
                    ? Icons.check_rounded
                    : Icons.person_add_alt_rounded,
                size: 20,
                color: widget.isFollowing
                    ? (widget.isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)
                    : AppColors.white,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isFollowing
                    ? 'instructor.following'.tr()
                    : 'instructor.follow'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.isFollowing
                      ? (widget.isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight)
                      : AppColors.white,
                ),
              ),
              if (widget.followersCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isFollowing
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatNumber(widget.followersCount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isFollowing
                          ? AppColors.primary
                          : AppColors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
