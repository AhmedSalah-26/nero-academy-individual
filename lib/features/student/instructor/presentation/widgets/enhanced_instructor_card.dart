import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/instructor/domain/entities/instructor_entity.dart';

/// Enhanced Instructor Card with premium design
class EnhancedInstructorCard extends StatelessWidget {
  final InstructorEntity instructor;
  final bool isDark;
  final bool isVerified;
  final bool isFollowing;
  final int followersCount;
  final String? lastActive;
  final VoidCallback? onTap;
  final VoidCallback? onFollowTap;

  const EnhancedInstructorCard({
    super.key,
    required this.instructor,
    required this.isDark,
    this.isVerified = false,
    this.isFollowing = false,
    this.followersCount = 0,
    this.lastActive,
    this.onTap,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isDark ? Border.all(color: AppColors.borderDark, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.1),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top gradient section with avatar
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      left: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Avatar positioned to overlap
                    Positioned(
                      bottom: -40,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.cardDark : AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: ClipOval(
                              child: instructor.avatarUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: instructor.avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          _buildPlaceholder(),
                                      errorWidget: (_, __, ___) =>
                                          _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Verified badge
                    if (isVerified || instructor.averageRating >= 4.5)
                      Positioned(
                        bottom: -35,
                        right: 30,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDark ? AppColors.cardDark : AppColors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content section
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 42, 8, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      instructor.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    // Headline
                    if (instructor.headline != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        instructor.headline!,
                        style: TextStyle(
                          fontSize: 8,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.grey800.withValues(alpha: 0.5)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            Icons.star_rounded,
                            instructor.averageRating.toStringAsFixed(1),
                            AppColors.warning,
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            color:
                                isDark ? AppColors.grey700 : AppColors.grey300,
                          ),
                          _buildStatItem(
                            Icons.people_rounded,
                            _formatNumber(instructor.totalStudents),
                            AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: const Icon(
        Icons.person_rounded,
        size: 35,
        color: AppColors.grey400,
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
