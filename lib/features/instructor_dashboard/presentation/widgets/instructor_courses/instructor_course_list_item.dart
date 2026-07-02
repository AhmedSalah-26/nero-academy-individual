import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/instructor_course_model.dart';

/// Instructor Course List Item - Banner Style Design
class InstructorCourseListItem extends StatelessWidget {
  final InstructorCourseModel course;
  final VoidCallback? onPublish;
  final VoidCallback? onUnpublish;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewEnrollments;
  final VoidCallback? onPreview;

  const InstructorCourseListItem({
    super.key,
    required this.course,
    this.onPublish,
    this.onUnpublish,
    this.onEdit,
    this.onDelete,
    this.onViewEnrollments,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course thumbnail (full width) with status badge overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: course.thumbnailUrl != null
                      ? Image.network(
                          course.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(isDark);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color:
                                  isDark ? AppColors.grey800 : Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : _buildPlaceholder(isDark),
                ),
              ),
              // Status badge on top of image (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: _buildStatusBadge(isDark, isArabic),
              ),
              // Delete icon button on top of image (top-left) if onDelete is available
              if (onDelete != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: isArabic ? 'حذف الكورس نهائياً' : 'Delete Course Permanently',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Course info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  course.getTitle(isArabic),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Stats Row
                _buildStatsRow(isDark, isArabic),
                // Suspension warning if applicable
                if (course.isSuspended && course.suspensionReason != null) ...[
                  const SizedBox(height: 12),
                  _buildSuspensionWarning(isArabic),
                ],
                const SizedBox(height: 12),
                // Actions at the bottom
                _buildActionsBar(context, isDark, isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Icon(
          Icons.school_rounded,
          color: isDark ? AppColors.grey600 : AppColors.grey400,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark, bool isArabic) {
    Color bgColor;
    Color textColor;
    String label;

    if (course.isSuspended) {
      bgColor = AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
      label = isArabic ? 'موقوف' : 'Suspended';
    } else if (course.isPublished) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      label = isArabic ? 'منشور' : 'Published';
    } else {
      bgColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
      label = isArabic ? 'مسودة' : 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, bool isArabic) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.people_outlined,
          value: _formatNumber(course.enrollmentCount),
          label: isArabic ? 'طالب' : 'students',
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.star_outline_rounded,
          value: course.averageRating.toStringAsFixed(1),
          label: isArabic ? 'تقييم' : 'rating',
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.attach_money_rounded,
          value: _formatNumber(course.totalRevenue.toInt()),
          label: '\$',
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.play_lesson_outlined,
          value: '${course.lessonCount}',
          label: isArabic ? 'درس' : 'lessons',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : Colors.grey[500],
          ),
        ),
      ],
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

  Widget _buildSuspensionWarning(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              course.suspensionReason!,
              style: const TextStyle(fontSize: 11, color: AppColors.error),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context, bool isDark, bool isArabic) {
    return Column(
      children: [
        // First row: Edit, Publish/Hide, Delete
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(isArabic ? 'تعديل' : 'Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  side: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: course.isPublished ? onUnpublish : onPublish,
                icon: Icon(
                  course.isPublished
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
                label: Text(
                  course.isPublished
                      ? (isArabic ? 'إخفاء' : 'Hide')
                      : (isArabic ? 'نشر' : 'Publish'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: course.isPublished
                      ? AppColors.warning
                      : AppColors.success,
                  side: BorderSide(
                    color: course.isPublished
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(isArabic ? 'حذف' : 'Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Second row: View Enrollments, Preview
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewEnrollments,
                icon: const Icon(Icons.people_outline_rounded, size: 16),
                label: Text(isArabic ? 'الطلاب' : 'Students'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                label: Text(isArabic ? 'معاينة' : 'Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: const BorderSide(color: AppColors.info),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
