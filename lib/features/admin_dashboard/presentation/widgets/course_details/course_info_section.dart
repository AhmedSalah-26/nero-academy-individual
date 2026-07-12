import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_course_model.dart';

class CourseDetailsInfoSection extends StatelessWidget {
  final AdminCourseModel course;
  final bool isDark;
  final bool isArabic;

  const CourseDetailsInfoSection({
    super.key,
    required this.course,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              course.getTitle(isArabic),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            // Status badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusBadge(course, isDark, isArabic),
                if (course.categoryName != null)
                  _buildBadge(
                    course.categoryName!,
                    AppColors.info,
                    isDark,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Instructor
            _buildInfoRow(
              Icons.person_rounded,
              isArabic ? 'المدرس' : 'Instructor',
              course.instructorName,
              isDark,
            ),
            const SizedBox(height: 12),
            // Price
            _buildInfoRow(
              Icons.attach_money_rounded,
              isArabic ? 'السعر' : 'Price',
              course.discountPrice != null
                  ? '${course.discountPrice!.toStringAsFixed(0)} (${isArabic ? 'بدلاً من' : 'was'} ${course.price.toStringAsFixed(0)})'
                  : course.price.toStringAsFixed(0),
              isDark,
            ),
            const SizedBox(height: 12),
            // Created date
            _buildInfoRow(
              Icons.calendar_today_rounded,
              isArabic ? 'تاريخ الإنشاء' : 'Created',
              _formatDate(course.createdAt, isArabic),
              isDark,
            ),
            // Suspension reason if suspended
            if (course.isSuspended && course.suspensionReason != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${isArabic ? 'سبب الإيقاف:' : 'Suspension reason:'} ${course.suspensionReason}',
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      AdminCourseModel course, bool isDark, bool isArabic) {
    if (course.isSuspended) {
      return _buildBadge(
        isArabic ? 'موقوف' : 'Suspended',
        AppColors.error,
        isDark,
      );
    }
    if (course.isPublished) {
      return _buildBadge(
        isArabic ? 'منشور' : 'Published',
        AppColors.success,
        isDark,
      );
    }
    return _buildBadge(
      isArabic ? 'مسودة' : 'Draft',
      AppColors.warning,
      isDark,
    );
  }

  Widget _buildBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, bool isArabic) {
    final months = isArabic
        ? [
            'يناير',
            'فبراير',
            'مارس',
            'أبريل',
            'مايو',
            'يونيو',
            'يوليو',
            'أغسطس',
            'سبتمبر',
            'أكتوبر',
            'نوفمبر',
            'ديسمبر'
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
