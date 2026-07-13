import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';

/// Enrolled Course Card - List item for My Learning screen
class EnrolledCourseCard extends StatelessWidget {
  final EnrollmentEntity enrollment;
  final String locale;
  final VoidCallback onTap;

  const EnrolledCourseCard({
    super.key,
    required this.enrollment,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final title = enrollment.getTitle(locale);
    final progress = enrollment.progressPercentage.round();
    final remaining = _formatDuration(enrollment.remainingMinutes);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? primary.withValues(alpha: 0.7)
                : primary.withValues(alpha: 0.25),
            width: isDark ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            _buildThumbnail(isDark),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with chevron
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.white
                                : AppColors.textMainLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: enrollment.progressPercentage / 100,
                      backgroundColor:
                          isDark ? AppColors.grey700 : AppColors.grey100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress, primary),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Progress text
                  Row(
                    children: [
                      Text(
                        '$progress%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getProgressColor(progress, primary),
                        ),
                      ),
                      Text(
                        ' • $remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ),
                      if (!enrollment.isCurrentlyAvailable) ...[
                        const Spacer(),
                        _buildInactiveBadge(locale),
                      ] else if (enrollment.accessExpiresAt != null) ...[
                        const Spacer(),
                        _buildExpirationBadge(
                            enrollment.accessExpiresAt!, locale, isDark),
                      ] else if (enrollment.isCompleted) ...[
                        const Spacer(),
                        _buildCompletedBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveBadge(String locale) {
    final isArabic = locale == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 12,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            isArabic ? 'غير مفعل حاليا' : 'Inactive now',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: enrollment.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: enrollment.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                  child: const Icon(Icons.play_circle_outline, size: 24),
                ),
              )
            : Container(
                color: isDark ? AppColors.grey800 : AppColors.grey100,
                child: const Icon(Icons.play_circle_outline, size: 24),
              ),
      ),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: AppColors.success,
          ),
          const SizedBox(width: 3),
          Text(
            'my_learning.completed'.tr(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationBadge(DateTime expiresAt, String locale, bool isDark) {
    final daysLeft = expiresAt.difference(DateTime.now()).inDays;
    final isArabic = locale == 'ar';
    final text = daysLeft > 0
        ? (isArabic ? 'باقي $daysLeft يوم' : '$daysLeft days left')
        : (isArabic ? 'ينتهي اليوم' : 'Expires today');
    final color = daysLeft <= 3
        ? AppColors.error
        : (isDark ? AppColors.grey400 : AppColors.grey600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(int progress, Color primary) {
    if (progress >= 80) return AppColors.success;
    if (progress >= 30) return primary;
    return AppColors.warning;
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return 'my_learning.completed'.tr();
    if (minutes < 60) return '${minutes}m ${'my_learning.remaining'.tr()}';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h ${'my_learning.remaining'.tr()}';
    return '${hours}h ${mins}m ${'my_learning.remaining'.tr()}';
  }
}
