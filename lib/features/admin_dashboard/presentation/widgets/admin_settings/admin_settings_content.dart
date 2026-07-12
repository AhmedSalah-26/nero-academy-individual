import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/logout_service.dart';
import '../../../../../core/services/theme_service.dart';

/// Admin Settings Content
class AdminSettingsContent extends StatefulWidget {
  const AdminSettingsContent({super.key});

  @override
  State<AdminSettingsContent> createState() => _AdminSettingsContentState();
}

class _AdminSettingsContentState extends State<AdminSettingsContent> {
  Future<void> _logout(BuildContext context) async {
    await LogoutService.logout(context);
  }

  void _showLanguageSelector(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final currentLanguage = context.locale.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'settings.select_language'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
                context, 'en', 'English', currentLanguage, isDark),
            const SizedBox(height: 8),
            _buildLanguageOption(
                context, 'ar', 'العربية', currentLanguage, isDark),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String code, String name,
      String current, bool isDark) {
    final isSelected = code == current;
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        context.setLocale(Locale(code));
      },
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.white : AppColors.textMainLight),
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.grey700 : AppColors.grey200),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'settings.dark_mode'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeOption(
                context, false, 'settings.light'.tr(), '☀️', isDark),
            const SizedBox(height: 8),
            _buildThemeOption(
                context, true, 'settings.dark'.tr(), '🌙', isDark),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, bool darkMode, String name,
      String emoji, bool isDark) {
    final isSelected = ThemeService.instance.currentDarkMode == darkMode;
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        ThemeService.instance.setDarkMode(darkMode);
        setState(() {});
      },
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.white : AppColors.textMainLight),
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.grey700 : AppColors.grey200),
        ),
      ),
    );
  }

  void _showNotificationsSettings(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'settings.notifications'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 20),
              _buildNotificationToggle(
                context,
                isArabic
                    ? 'إشعارات المستخدمين الجدد'
                    : 'New User Notifications',
                true,
                (v) {},
                isDark,
              ),
              _buildNotificationToggle(
                context,
                isArabic ? 'إشعارات البلاغات' : 'Report Notifications',
                true,
                (v) {},
                isDark,
              ),
              _buildNotificationToggle(
                context,
                isArabic ? 'إشعارات المدفوعات' : 'Payout Notifications',
                true,
                (v) {},
                isDark,
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(BuildContext context, String title,
      bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            title: isArabic ? 'الحساب' : 'Account',
            items: [
              _SettingsItem(
                  icon: Icons.person,
                  title: isArabic ? 'الملف الشخصي' : 'Profile',
                  onTap: () => context.pushNamed('edit-profile')),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: isArabic ? 'التطبيق' : 'App',
            items: [
              _SettingsItem(
                  icon: Icons.language,
                  title: isArabic ? 'اللغة' : 'Language',
                  onTap: () => _showLanguageSelector(context, isDark)),
              _SettingsItem(
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: isArabic ? 'المظهر' : 'Theme',
                  onTap: () => _showThemeSelector(context, isDark)),
              _SettingsItem(
                  icon: Icons.notifications,
                  title: isArabic ? 'الإشعارات' : 'Notifications',
                  onTap: () => _showNotificationsSettings(context, isDark)),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: isArabic ? 'أخرى' : 'Other',
            items: [
              _SettingsItem(
                  icon: Icons.help,
                  title: isArabic ? 'المساعدة' : 'Help & Support',
                  onTap: () => context.pushNamed('help-support')),
              _SettingsItem(
                  icon: Icons.privacy_tip,
                  title: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                  onTap: () => context.pushNamed('privacy-policy')),
              _SettingsItem(
                  icon: Icons.logout,
                  title: isArabic ? 'تسجيل الخروج' : 'Logout',
                  onTap: () => _logout(context),
                  isDestructive: true),
            ],
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title,
      required List<_SettingsItem> items,
      required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon,
                        color: item.isDestructive
                            ? AppColors.error
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)),
                    title: Text(item.title,
                        style: TextStyle(
                            color: item.isDestructive
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight))),
                    trailing: Icon(Icons.chevron_right,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1)
                    Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsItem(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.isDestructive = false});
}
