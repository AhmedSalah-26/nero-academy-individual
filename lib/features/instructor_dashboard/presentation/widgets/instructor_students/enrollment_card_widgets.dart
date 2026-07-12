import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

/// Enrollment Card Widget
class EnrollmentCard extends StatefulWidget {
  final StudentEnrollmentDetail enrollment;
  final bool isDark;
  final bool isArabic;
  final DateFormat dateFormat;
  final VoidCallback onExtend;
  final VoidCallback onReset;
  final VoidCallback onStatus;
  final VoidCallback onUnenroll;
  final VoidCallback? onRefresh; // Add optional refresh callback

  const EnrollmentCard({
    super.key,
    required this.enrollment,
    required this.isDark,
    required this.isArabic,
    required this.dateFormat,
    required this.onExtend,
    required this.onReset,
    required this.onStatus,
    required this.onUnenroll,
    this.onRefresh, // Optional
  });

  @override
  State<EnrollmentCard> createState() => _EnrollmentCardState();
}

class _EnrollmentCardState extends State<EnrollmentCard> {
  bool _isProcessingRefund = false;

  Future<void> _handleRefund() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isArabic ? 'تأكيد الاسترداد' : 'Confirm Refund'),
        content: Text(
          widget.isArabic
              ? 'هل أنت متأكد من استرداد المبلغ لهذا التسجيل؟'
              : 'Are you sure you want to refund this enrollment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isArabic ? 'استرداد' : 'Refund'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessingRefund = true);

      try {
        await Supabase.instance.client.rpc('process_refund', params: {
          'p_enrollment_id': widget.enrollment.enrollmentId,
          'p_reason': 'Refunded by instructor',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'تم استرداد المبلغ بنجاح'
                    : 'Refund processed successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Trigger parent refresh if callback provided
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'فشل استرداد المبلغ: $e'
                    : 'Failed to process refund: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessingRefund = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildProgressBar(),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: widget.enrollment.courseThumbnail != null
              ? Image.network(widget.enrollment.courseThumbnail!,
                  width: 60, height: 40, fit: BoxFit.cover)
              : Container(
                  width: 60,
                  height: 40,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.play_circle_outline,
                      color: AppColors.primary),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isArabic
                    ? widget.enrollment.courseTitleAr
                    : widget.enrollment.courseTitleEn,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.isArabic ? 'تاريخ التسجيل:' : 'Enrolled:'} ${widget.dateFormat.format(widget.enrollment.enrolledAt)}',
                style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
              ),
            ],
          ),
        ),
        EnrollmentStatusBadge(
            status: widget.enrollment.status, isArabic: widget.isArabic),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.isArabic ? 'التقدم' : 'Progress',
                      style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight)),
                  Text(
                      '${widget.enrollment.progressPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(
                              widget.enrollment.progressPercentage))),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.enrollment.progressPercentage / 100,
                  minHeight: 6,
                  backgroundColor: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation(
                      _getProgressColor(widget.enrollment.progressPercentage)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
            '${widget.enrollment.completedLessons}/${widget.enrollment.totalLessons}',
            style: TextStyle(
                fontSize: 12,
                color: widget.isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        EnrollmentActionChip(
          icon: Icons.access_time,
          label: widget.isArabic ? 'تمديد' : 'Extend',
          color: AppColors.info,
          onTap: widget.onExtend,
        ),
        EnrollmentActionChip(
          icon: Icons.refresh,
          label: widget.isArabic ? 'إعادة تعيين' : 'Reset',
          color: AppColors.warning,
          onTap: widget.onReset,
        ),
        EnrollmentActionChip(
          icon: Icons.edit,
          label: widget.isArabic ? 'الحالة' : 'Status',
          color: AppColors.primary,
          onTap: widget.onStatus,
        ),
        // Refund button - only show for active enrollments
        if (widget.enrollment.status == 'active')
          _isProcessingRefund
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                )
              : EnrollmentActionChip(
                  icon: Icons.money_off_rounded,
                  label: widget.isArabic ? 'استرداد' : 'Refund',
                  color: Colors.red,
                  onTap: _handleRefund,
                ),
        EnrollmentActionChip(
          icon: Icons.delete_outline,
          label: widget.isArabic ? 'إزالة' : 'Remove',
          color: AppColors.error,
          onTap: widget.onUnenroll,
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return AppColors.success;
    if (progress >= 50) return AppColors.info;
    if (progress >= 25) return AppColors.warning;
    return AppColors.error;
  }
}

/// Enrollment Action Chip
class EnrollmentActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const EnrollmentActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enrollment Status Badge
class EnrollmentStatusBadge extends StatelessWidget {
  final String status;
  final bool isArabic;

  const EnrollmentStatusBadge({
    super.key,
    required this.status,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final statusMap = {
      'completed': (AppColors.success, isArabic ? 'مكتمل' : 'Completed'),
      'active': (AppColors.info, isArabic ? 'نشط' : 'Active'),
      'expired': (AppColors.warning, isArabic ? 'منتهي' : 'Expired'),
      'pending': (AppColors.warning, isArabic ? 'معلق' : 'Pending'),
      'refunded': (AppColors.error, isArabic ? 'مسترد' : 'Refunded'),
    };
    final (color, label) =
        statusMap[status] ?? (AppColors.textMutedLight, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
