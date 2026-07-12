import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_banner_model.dart';

/// Banner List Item Widget
class BannerListItem extends StatelessWidget {
  final AdminBannerModel banner;
  final int index;
  final int totalCount;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const BannerListItem({
    super.key,
    required this.banner,
    required this.index,
    required this.totalCount,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // Banner image (full width) with drag handle and order number overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? AppColors.grey800 : Colors.grey[200],
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark ? AppColors.grey600 : Colors.grey[400],
                          size: 48,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: isDark ? AppColors.grey800 : Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Drag handle + Order number on top of image
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Positioned(
                top: 8,
                right: isArabic ? null : 8,
                left: isArabic ? 8 : null,
                child: _buildStatusBadge(isArabic),
              ),
            ],
          ),
          // Banner info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(context, isArabic),
                if (banner.subtitleAr != null || banner.subtitleEn != null) ...[
                  const SizedBox(height: 6),
                  _buildSubtitle(context, isArabic),
                ],
                const SizedBox(height: 12),
                _buildMetaRow(isArabic),
                const SizedBox(height: 12),
                _buildStatsRow(isArabic),
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

  Widget _buildTitleRow(BuildContext context, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      isArabic ? banner.titleAr : (banner.titleEn ?? banner.titleAr),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusBadge(bool isArabic) {
    Color bgColor;
    String label;

    switch (banner.statusLabel) {
      case 'active':
        bgColor = AppColors.success;
        label = isArabic ? 'نشط' : 'Active';
        break;
      case 'inactive':
        bgColor = Colors.grey;
        label = isArabic ? 'غير نشط' : 'Inactive';
        break;
      case 'scheduled':
        bgColor = AppColors.info;
        label = isArabic ? 'مجدول' : 'Scheduled';
        break;
      case 'expired':
        bgColor = AppColors.error;
        label = isArabic ? 'منتهي' : 'Expired';
        break;
      default:
        bgColor = Colors.grey;
        label = banner.statusLabel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitle =
        isArabic ? banner.subtitleAr : (banner.subtitleEn ?? banner.subtitleAr);
    if (subtitle == null) return const SizedBox.shrink();

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetaRow(bool isArabic) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        // Link type
        _buildMetaItem(
          icon: _getLinkTypeIcon(),
          label: _getLinkTypeLabel(isArabic),
        ),
        // Date range
        if (banner.startDate != null || banner.endDate != null)
          _buildMetaItem(
            icon: Icons.calendar_today_rounded,
            label: banner.startDate != null && banner.endDate != null
                ? '${dateFormat.format(banner.startDate!)} - ${dateFormat.format(banner.endDate!)}'
                : banner.startDate != null
                    ? '${isArabic ? 'من' : 'From'} ${dateFormat.format(banner.startDate!)}'
                    : '${isArabic ? 'حتى' : 'Until'} ${dateFormat.format(banner.endDate!)}',
          ),
      ],
    );
  }

  Widget _buildMetaItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  IconData _getLinkTypeIcon() {
    switch (banner.linkType) {
      case 'course':
        return Icons.school_outlined;
      case 'category':
        return Icons.category_outlined;
      case 'url':
        return Icons.link_rounded;
      case 'instructor':
        return Icons.person_outline_rounded;
      default:
        return Icons.link_off_rounded;
    }
  }

  String _getLinkTypeLabel(bool isArabic) {
    switch (banner.linkType) {
      case 'course':
        return isArabic ? 'كورس' : 'Course';
      case 'category':
        return isArabic ? 'تصنيف' : 'Category';
      case 'url':
        return isArabic ? 'رابط خارجي' : 'External URL';
      case 'instructor':
        return isArabic ? 'مدرس' : 'Instructor';
      default:
        return isArabic ? 'بدون رابط' : 'No Link';
    }
  }

  Widget _buildStatsRow(bool isArabic) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.visibility_outlined,
          value: _formatNumber(banner.viewsCount),
          label: isArabic ? 'مشاهدة' : 'views',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.touch_app_outlined,
          value: _formatNumber(banner.clicksCount),
          label: isArabic ? 'نقرة' : 'clicks',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.percent_rounded,
          value: '${banner.clickThroughRate.toStringAsFixed(1)}%',
          label: 'CTR',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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

  Widget _buildActionsBar(BuildContext context, bool isDark, bool isArabic) {
    return Row(
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
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onToggleStatus,
            icon: Icon(
              banner.isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 16,
            ),
            label: Text(
              banner.isActive
                  ? (isArabic ? 'إخفاء' : 'Hide')
                  : (isArabic ? 'إظهار' : 'Show'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  banner.isActive ? AppColors.warning : AppColors.success,
              side: BorderSide(
                color: banner.isActive ? AppColors.warning : AppColors.success,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: Text(isArabic ? 'حذف' : 'Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
      ],
    );
  }
}
