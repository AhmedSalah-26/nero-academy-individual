import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/category_model.dart';

/// Category List Item Widget
class CategoryListItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const CategoryListItem({
    super.key,
    required this.category,
    this.onEdit,
    this.onToggleStatus,
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
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIcon(isDark),
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

  Widget _buildIcon(bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIconData(category.icon),
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code_rounded;
      case 'design':
        return Icons.design_services_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'photo':
        return Icons.photo_camera_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Widget _buildInfo(bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.getName(isArabic),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(isDark, isArabic),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${category.courseCount} ${isArabic ? 'كورس' : 'courses'}',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        if (category.description != null) ...[
          const SizedBox(height: 4),
          Text(
            category.description!,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textMutedDark.withValues(alpha: 0.7)
                  : AppColors.textMutedLight.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(bool isDark, bool isArabic) {
    final isActive = category.isActive;
    final color = isActive ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive
            ? (isArabic ? 'نشط' : 'Active')
            : (isArabic ? 'غير نشط' : 'Inactive'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
          case 'edit':
            onEdit?.call();
            break;
          case 'toggle':
            onToggleStatus?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, size: 20),
              const SizedBox(width: 12),
              Text(isArabic ? 'تعديل' : 'Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                category.isActive
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color:
                    category.isActive ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 12),
              Text(
                category.isActive
                    ? (isArabic ? 'إلغاء التفعيل' : 'Deactivate')
                    : (isArabic ? 'تفعيل' : 'Activate'),
                style: TextStyle(
                  color:
                      category.isActive ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
