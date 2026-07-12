import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_course_model.dart';

/// Course List Item Widget
class CourseListItem extends StatelessWidget {
  final AdminCourseModel course;
  final VoidCallback? onSuspend;
  final VoidCallback? onUnsuspend;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final VoidCallback? onPublish;
  final VoidCallback? onUnpublish;
  final VoidCallback? onFeature;
  final VoidCallback? onUnfeature;
  final VoidCallback? onViewEnrollments;

  const CourseListItem({
    super.key,
    required this.course,
    this.onSuspend,
    this.onUnsuspend,
    this.onDelete,
    this.onView,
    this.onPublish,
    this.onUnpublish,
    this.onFeature,
    this.onUnfeature,
    this.onViewEnrollments,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildThumbnail(),
                const SizedBox(width: 12),
                Expanded(child: _buildInfo(isDark, isArabic)),
                _buildActionMenu(context, isDark, isArabic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: course.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: course.thumbnailUrl!,
              width: 80,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 80,
                height: 60,
                color: AppColors.grey200,
                child: const Icon(Icons.image, color: AppColors.grey400),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 80,
                height: 60,
                color: AppColors.grey200,
                child: const Icon(Icons.broken_image, color: AppColors.grey400),
              ),
            )
          : Container(
              width: 80,
              height: 60,
              color: AppColors.grey200,
              child: const Icon(Icons.school, color: AppColors.grey400),
            ),
    );
  }

  Widget _buildInfo(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                course.getTitle(isArabic),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(isDark, isArabic),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          course.instructorName,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildStat(
                Icons.people_rounded, course.enrolledCount.toString(), isDark),
            const SizedBox(width: 12),
            _buildStat(
                Icons.star_rounded, course.rating.toStringAsFixed(1), isDark),
            const SizedBox(width: 12),
            _buildStat(
              Icons.attach_money_rounded,
              course.totalRevenue.toStringAsFixed(0),
              isDark,
            ),
          ],
        ),
        if (course.isSuspended && course.suspensionReason != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              course.suspensionReason!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.error,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isDark, bool isArabic) {
    if (course.isSuspended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isArabic ? 'موقوف' : 'Suspended',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      );
    }

    if (course.isPublished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isArabic ? 'منشور' : 'Published',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isArabic ? 'مسودة' : 'Draft',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, bool isDark, bool isArabic) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView?.call();
            break;
          case 'enrollments':
            onViewEnrollments?.call();
            break;
          case 'publish':
            onPublish?.call();
            break;
          case 'unpublish':
            onUnpublish?.call();
            break;
          case 'suspend':
            onSuspend?.call();
            break;
          case 'unsuspend':
            onUnsuspend?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.visibility_rounded, size: 20),
              const SizedBox(width: 12),
              Text(isArabic ? 'عرض التفاصيل' : 'View Details'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'enrollments',
          child: Row(
            children: [
              const Icon(Icons.people_rounded, size: 20, color: AppColors.info),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'المسجلين' : 'Enrollments',
                style: const TextStyle(color: AppColors.info),
              ),
            ],
          ),
        ),
        if (!course.isSuspended) ...[
          if (course.isPublished)
            PopupMenuItem(
              value: 'unpublish',
              child: Row(
                children: [
                  const Icon(Icons.unpublished_rounded,
                      size: 20, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Text(
                    isArabic ? 'إلغاء النشر' : 'Unpublish',
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ],
              ),
            )
          else
            PopupMenuItem(
              value: 'publish',
              child: Row(
                children: [
                  const Icon(Icons.publish_rounded,
                      size: 20, color: AppColors.success),
                  const SizedBox(width: 12),
                  Text(
                    isArabic ? 'نشر' : 'Publish',
                    style: const TextStyle(color: AppColors.success),
                  ),
                ],
              ),
            ),
        ],
        if (course.isSuspended)
          PopupMenuItem(
            value: 'unsuspend',
            child: Row(
              children: [
                const Icon(Icons.play_arrow_rounded,
                    size: 20, color: AppColors.success),
                const SizedBox(width: 12),
                Text(
                  isArabic ? 'إلغاء الإيقاف' : 'Unsuspend',
                  style: const TextStyle(color: AppColors.success),
                ),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'suspend',
            child: Row(
              children: [
                const Icon(Icons.pause_rounded,
                    size: 20, color: AppColors.warning),
                const SizedBox(width: 12),
                Text(
                  isArabic ? 'إيقاف' : 'Suspend',
                  style: const TextStyle(color: AppColors.warning),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_rounded,
                  size: 20, color: AppColors.error),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'حذف' : 'Delete',
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
