import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../data/models/admin_enrollment_model.dart';

/// Enrollment List Item Widget
class EnrollmentListItem extends StatelessWidget {
  final AdminEnrollmentModel enrollment;
  final VoidCallback? onRefund;
  final VoidCallback? onView;

  const EnrollmentListItem({
    super.key,
    required this.enrollment,
    this.onRefund,
    this.onView,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCourseInfo(isDark, isArabic)),
                    _buildStatusBadge(isDark, isArabic),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStudentInfo(isDark, isArabic),
                const SizedBox(height: 12),
                _buildFooter(context, isDark, isArabic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          enrollment.courseTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${enrollment.id.substring(0, 8)}...',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInfo(bool isDark, bool isArabic) {
    return Row(
      children: [
        Icon(
          Icons.person_rounded,
          size: 16,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            enrollment.userName,
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.email_rounded,
          size: 16,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            enrollment.userEmail ?? '',
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, bool isArabic) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 14,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 4),
        Text(
          dateFormat.format(enrollment.enrolledAt),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.attach_money_rounded,
          size: 14,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        Text(
          '${enrollment.price.toStringAsFixed(0)} EGP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const Spacer(),
        if (enrollment.status == EnrollmentStatus.active ||
            enrollment.status == EnrollmentStatus.completed)
          _buildProgressIndicator(isDark, isArabic),
        if (enrollment.status == EnrollmentStatus.active)
          IconButton(
            icon: const Icon(Icons.money_off_rounded, color: AppColors.warning),
            onPressed: onRefund,
            tooltip: isArabic ? 'استرداد' : 'Refund',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up_rounded,
              size: 14, color: AppColors.info),
          const SizedBox(width: 4),
          Text(
            '${enrollment.progress}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark, bool isArabic) {
    Color color;
    String label;

    switch (enrollment.status) {
      case EnrollmentStatus.active:
        color = AppColors.success;
        label = isArabic ? 'نشط' : 'Active';
        break;
      case EnrollmentStatus.completed:
        color = AppColors.info;
        label = isArabic ? 'مكتمل' : 'Completed';
        break;
      case EnrollmentStatus.pending:
        color = AppColors.warning;
        label = isArabic ? 'معلق' : 'Pending';
        break;
      case EnrollmentStatus.refunded:
        color = AppColors.error;
        label = isArabic ? 'مسترد' : 'Refunded';
        break;
      default:
        color = AppColors.grey500;
        label = enrollment.status.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
