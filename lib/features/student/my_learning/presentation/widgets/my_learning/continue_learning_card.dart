import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';

/// Continue Learning Card - Hero section for My Learning screen
class ContinueLearningCard extends StatelessWidget {
  final EnrollmentEntity enrollment;
  final String locale;
  final VoidCallback onResume;
  final VoidCallback onTap;

  const ContinueLearningCard({
    super.key,
    required this.enrollment,
    required this.locale,
    required this.onResume,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final buttonColor = Theme.of(context).colorScheme.tertiary;
    final title = enrollment.getTitle(locale);
    final progress = enrollment.progressPercentage.round();
    final remaining = _formatDuration(enrollment.remainingMinutes);
    const radius = 16.0;
    const borderWidth = 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark
                ? AppColors.grey700.withValues(alpha: 0.5)
                : AppColors.grey100,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.25 : 0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - borderWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(isDark, primary),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'my_learning.continue_learning'.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.white
                              : AppColors.textMainLight,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (enrollment.instructorName != null)
                        Text(
                          '${'course.instructor'.tr()}: ${enrollment.instructorName}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark ? AppColors.grey400 : AppColors.grey500,
                          ),
                        ),
                      if (!enrollment.isCurrentlyAvailable) ...[
                        const SizedBox(height: 12),
                        _buildInactiveBadge(locale),
                      ],
                      if (enrollment.accessExpiresAt != null) ...[
                        const SizedBox(height: 12),
                        _buildExpirationBadge(
                            enrollment.accessExpiresAt!, locale, isDark),
                      ],
                      const SizedBox(height: 16),
                      _buildProgressSection(
                          progress, remaining, isDark, primary),
                      const SizedBox(height: 16),
                      _buildResumeButton(buttonColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark, Color primary) {
    final placeholderWidget = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [primary.withValues(alpha: 0.3), AppColors.surfaceDark]
              : [primary.withValues(alpha: 0.1), AppColors.grey100],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_filled_rounded,
          size: 56,
          color: primary.withValues(alpha: 0.7),
        ),
      ),
    );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: enrollment.thumbnailUrl != null &&
                    enrollment.thumbnailUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: enrollment.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => placeholderWidget,
                    errorWidget: (_, __, ___) => placeholderWidget,
                  )
                : placeholderWidget,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'my_learning.in_progress'.tr(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(
    int progress,
    String remaining,
    bool isDark,
    Color primary,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$progress% ${'my_learning.complete'.tr()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
              ),
            ),
            Text(
              remaining,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: enrollment.progressPercentage / 100,
            backgroundColor: isDark ? AppColors.grey700 : AppColors.grey100,
            valueColor: AlwaysStoppedAnimation<Color>(primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildResumeButton(Color buttonColor) {
    final isActive = enrollment.isCurrentlyAvailable;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isActive
            ? () {
                HapticFeedback.mediumImpact();
                onResume();
              }
            : null,
        icon: Icon(
          isActive ? Icons.play_arrow_rounded : Icons.lock_clock_outlined,
          size: 22,
        ),
        label: Text(
          isActive
              ? 'my_learning.resume_lesson'.tr(args: [
                  (enrollment.completedLessons + 1).toString(),
                ])
              : (locale == 'ar' ? 'غير مفعل حاليا' : 'Inactive now'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildInactiveBadge(String locale) {
    final isArabic = locale == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock_outlined,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            isArabic ? 'غير مفعل حاليا' : 'Inactive now',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
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
        ? (isArabic
            ? 'ينتهي الاشتراك خلال $daysLeft يوم'
            : 'Subscription expires in $daysLeft days')
        : (isArabic ? 'ينتهي الاشتراك اليوم' : 'Subscription expires today');
    final color = daysLeft <= 3 ? AppColors.error : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m ${'my_learning.left'.tr()}';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h ${'my_learning.left'.tr()}';
    }
    return '${hours}h ${mins}m ${'my_learning.left'.tr()}';
  }
}
