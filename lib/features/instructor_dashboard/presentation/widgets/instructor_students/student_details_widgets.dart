import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/animations/widgets/feedback/animated_snackbar.dart';

/// Student Details Widgets - Reusable widgets for student details screen

/// Status Badge Widget
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action Button Widget
class StudentActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const StudentActionButton({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat Card Widget
class StudentStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const StudentStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Details Section Widget
class DetailsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;

  const DetailsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Info Row Widget
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isArabic;
  final bool copyable;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.isArabic,
    this.copyable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ??
                  (isDark ? AppColors.textMainDark : AppColors.textMainLight),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (copyable)
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 18,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              AnimatedSnackbar.showSuccess(
                context: context,
                message: isArabic ? 'تم النسخ' : 'Copied',
                duration: const Duration(seconds: 2),
              );
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
      ],
    );
  }
}

/// Progress Section Widget
class StudentProgressSection extends StatelessWidget {
  final double progress;
  final bool isDark;
  final bool isArabic;

  const StudentProgressSection({
    super.key,
    required this.progress,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = _getProgressColor(progress);

    return DetailsSection(
      title: isArabic ? 'إجمالي التقدم' : 'Overall Progress',
      icon: Icons.trending_up,
      isDark: isDark,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 14,
                      backgroundColor:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${progress.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ),
          ],
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

/// Interest Tag Widget
class InterestTag extends StatelessWidget {
  final String interest;

  const InterestTag({
    super.key,
    required this.interest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        interest,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Ban Info Section Widget
class BanInfoSection extends StatelessWidget {
  final String? banReason;
  final DateTime? bannedUntil;
  final bool isDark;
  final bool isArabic;
  final String Function(DateTime) formatDate;

  const BanInfoSection({
    super.key,
    this.banReason,
    this.bannedUntil,
    required this.isDark,
    required this.isArabic,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'معلومات الحظر' : 'Ban Information',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (banReason != null) ...[
            InfoRow(
              icon: Icons.report_outlined,
              label: isArabic ? 'سبب الحظر' : 'Ban Reason',
              value: banReason!,
              isDark: isDark,
              isArabic: isArabic,
            ),
            const Divider(height: 20),
          ],
          InfoRow(
            icon: Icons.event_outlined,
            label: isArabic ? 'محظور حتى' : 'Banned Until',
            value: bannedUntil != null
                ? formatDate(bannedUntil!)
                : (isArabic ? 'غير محدد' : 'Permanent'),
            isDark: isDark,
            isArabic: isArabic,
          ),
        ],
      ),
    );
  }
}

/// Helper functions
Color getRoleColor(String role) {
  switch (role) {
    case 'admin':
      return AppColors.error;
    case 'instructor':
      return AppColors.primary;
    default:
      return AppColors.info;
  }
}

String getRoleName(String role, bool isArabic) {
  switch (role) {
    case 'admin':
      return isArabic ? 'مدير' : 'Admin';
    case 'instructor':
      return isArabic ? 'مدرس' : 'Instructor';
    default:
      return isArabic ? 'طالب' : 'Student';
  }
}
