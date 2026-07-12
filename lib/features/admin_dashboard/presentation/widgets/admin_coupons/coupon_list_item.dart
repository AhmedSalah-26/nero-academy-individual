import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_coupon_model.dart';

/// Coupon List Item Widget - Colorful design like instructor coupons
class CouponListItem extends StatelessWidget {
  final AdminCouponModel coupon;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onToggleSuspension;
  final VoidCallback? onDelete;
  final VoidCallback? onViewUsage;
  final bool readOnly; // For instructor coupons in admin dashboard

  const CouponListItem({
    super.key,
    required this.coupon,
    this.onEdit,
    this.onToggleStatus,
    this.onToggleSuspension,
    this.onDelete,
    this.onViewUsage,
    this.readOnly = false,
  });

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'تم نسخ الكود' : 'Code copied'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Code + Name + Status
          Row(
            children: [
              // Code badge with copy button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _copyCode(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          coupon.code,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                child: Text(
                  isArabic ? coupon.nameAr : (coupon.nameEn ?? coupon.nameAr),
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
              ),
              const SizedBox(width: 12),

              // Status badge
              _buildStatusBadge(isArabic),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom row: Details + Actions
          Row(
            children: [
              // Details
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    // Discount badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        coupon.discountDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    // Usage
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coupon.usageLimit != null
                              ? '${coupon.usageCount}/${coupon.usageLimit}'
                              : '${coupon.usageCount}x',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    // Scope
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getScopeIcon(),
                          size: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getScopeLabel(isArabic),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    // Date
                    if (coupon.endDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: coupon.statusLabel == 'expired'
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yy').format(coupon.endDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: coupon.statusLabel == 'expired'
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!readOnly)
                    _buildActionBtn(
                      icon: Icons.edit_rounded,
                      color: AppColors.info,
                      onTap: onEdit,
                    ),
                  if (!readOnly) const SizedBox(width: 6),
                  _buildActionBtn(
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: onViewUsage,
                  ),
                  const SizedBox(width: 6),
                  _buildActionBtn(
                    icon: coupon.isActive
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color:
                        coupon.isActive ? AppColors.warning : AppColors.success,
                    onTap: onToggleStatus,
                  ),
                  const SizedBox(width: 6),
                  _buildActionBtn(
                    icon: coupon.isSuspended
                        ? Icons.check_circle_rounded
                        : Icons.block_rounded,
                    color: coupon.isSuspended
                        ? AppColors.success
                        : const Color(0xFFEF4444),
                    onTap: onToggleSuspension,
                  ),
                  if (!readOnly) ...[
                    const SizedBox(width: 6),
                    _buildActionBtn(
                      icon: Icons.delete_rounded,
                      color: AppColors.error,
                      onTap: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getScopeIcon() {
    switch (coupon.scope) {
      case 'all':
        return Icons.all_inclusive_rounded;
      case 'categories':
        return Icons.category_rounded;
      case 'courses':
        return Icons.school_rounded;
      case 'instructors':
        return Icons.person_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  String _getScopeLabel(bool isArabic) {
    switch (coupon.scope) {
      case 'all':
        return isArabic ? 'الكل' : 'All';
      case 'categories':
        return isArabic ? 'فئات' : 'Cat';
      case 'courses':
        return isArabic ? 'كورسات' : 'Crs';
      case 'instructors':
        return isArabic ? 'مدرسين' : 'Inst';
      default:
        return coupon.scope;
    }
  }

  Widget _buildStatusBadge(bool isArabic) {
    Color color;
    String label;

    switch (coupon.statusLabel) {
      case 'active':
        color = AppColors.success;
        label = isArabic ? 'نشط' : 'Active';
        break;
      case 'inactive':
        color = Colors.grey;
        label = isArabic ? 'متوقف' : 'Off';
        break;
      case 'expired':
        color = AppColors.error;
        label = isArabic ? 'منتهي' : 'Exp';
        break;
      case 'suspended':
        color = const Color(0xFFEF4444);
        label = isArabic ? 'موقوف' : 'Susp';
        break;
      case 'limit_reached':
        color = AppColors.warning;
        label = isArabic ? 'مستنفد' : 'Full';
        break;
      case 'scheduled':
        color = AppColors.info;
        label = isArabic ? 'مجدول' : 'Soon';
        break;
      default:
        color = Colors.grey;
        label = coupon.statusLabel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    // If onTap is null, show disabled button
    final isDisabled = onTap == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
