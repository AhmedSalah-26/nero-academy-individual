import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/shared_widgets/user_avatar.dart';
import '../../../data/models/admin_user_model.dart';

/// User List Item Widget
class UserListItem extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback? onBan;
  final VoidCallback? onUnban;
  final VoidCallback? onView;

  const UserListItem({
    super.key,
    required this.user,
    this.onBan,
    this.onUnban,
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
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: user.avatarUrl,
                  name: user.displayName,
                  size: AvatarSize.lg,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(isDark, isArabic),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildActionMenu(context, isDark, isArabic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark, bool isArabic) {
    if (user.isBanned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isArabic ? 'محظور' : 'Banned',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      );
    }

    if (!user.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isArabic ? 'غير نشط' : 'Inactive',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isArabic ? 'نشط' : 'Active',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
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
          case 'ban':
            onBan?.call();
            break;
          case 'unban':
            onUnban?.call();
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
        if (user.isBanned)
          PopupMenuItem(
            value: 'unban',
            child: Row(
              children: [
                const Icon(Icons.lock_open_rounded,
                    size: 20, color: AppColors.success),
                const SizedBox(width: 12),
                Text(
                  isArabic ? 'إلغاء الحظر' : 'Unban User',
                  style: const TextStyle(color: AppColors.success),
                ),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'ban',
            child: Row(
              children: [
                const Icon(Icons.block_rounded,
                    size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text(
                  isArabic ? 'حظر المستخدم' : 'Ban User',
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
