import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/user_role_service.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/features/student/settings/presentation/cubit/settings_cubit.dart';
import 'package:lms_platform/features/student/settings/presentation/cubit/settings_state.dart';

/// Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await context.read<SettingsCubit>().loadSettings(userId);
    } else {
      context.read<SettingsCubit>().loadGuestSettings();
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadSettings();
  }

  bool get _isGuest => Supabase.instance.client.auth.currentUser == null;

  /// Get current language from EasyLocalization (source of truth)
  String get _currentLanguageCode => context.locale.languageCode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        title: Text(
          'settings.settings'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        leading: const AppBackButton(),
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: 500, child: AppLoadingState()),
              );
            }
            return _buildContent(state, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildContent(SettingsState state, bool isDark) {
    int sectionIndex = 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preferences Section
          SlideFadeIn.fromBottom(
            delay: Duration(milliseconds: 100 * sectionIndex++),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('settings.preferences'.tr(), isDark),
                const SizedBox(height: 12),
                _buildPreferencesCard(state, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Support Section
          SlideFadeIn.fromBottom(
            delay: Duration(milliseconds: 100 * sectionIndex++),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('settings.legal_support'.tr(), isDark),
                const SizedBox(height: 12),
                _buildSupportCard(isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_isGuest) ...[
            // Delete Account
            SlideFadeIn.fromBottom(
              delay: Duration(milliseconds: 100 * sectionIndex++),
              child: _buildDeleteAccountButton(isDark),
            ),
            const SizedBox(height: 24),
          ],
          // Version
          FadeIn(
            delay: Duration(milliseconds: 100 * sectionIndex++),
            child: Center(
              child: Text(
                'Version 2.4.0',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.grey600 : AppColors.grey400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.grey400 : AppColors.grey500,
      ),
    );
  }

  Widget _buildPreferencesCard(SettingsState state, bool isDark) {
    return Card(
      color: isDark ? AppColors.cardDark : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Language
          ExpansionTile(
            leading:
                const Icon(Icons.language, size: 22, color: AppColors.primary),
            title: Text(
              'settings.language'.tr(),
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildLanguageOption(
                        'en', 'English', _currentLanguageCode, isDark),
                    const SizedBox(height: 8),
                    _buildLanguageOption(
                        'ar', 'العربية', _currentLanguageCode, isDark),
                  ],
                ),
              ),
            ],
          ),
          // Dark Mode
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 22,
              color: AppColors.primary,
            ),
            title: Text(
              'settings.dark_mode'.tr(),
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            trailing: Switch(
              value: state.isDarkMode,
              onChanged: (v) => context.read<SettingsCubit>().toggleDarkMode(v),
              activeTrackColor: AppColors.primary,
            ),
          ),
          if (!_isGuest) ...[
            // Notifications
            ListTile(
              leading: const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: AppColors.primary,
              ),
              title: Text(
                'settings.notifications'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              trailing: Switch(
                value: state.notificationsEnabled,
                onChanged: (v) =>
                    context.read<SettingsCubit>().toggleNotifications(v),
                activeTrackColor: AppColors.primary,
              ),
            ),
            // Learning Profile for students
            FutureBuilder<String?>(
              future: UserRoleService.getCurrentUserRole(),
              builder: (context, snapshot) {
                final isArabic = context.locale.languageCode == 'ar';
                if (snapshot.data == 'student') {
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.school_outlined,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          isArabic ? 'تغيير المدرس' : 'Change Teacher',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? AppColors.grey600 : AppColors.grey400,
                        ),
                        onTap: () => AppRouter.goToSelectTeacher(context),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.analytics_outlined,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          isArabic ? 'ملف التعلم' : 'Learning Profile',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? AppColors.grey600 : AppColors.grey400,
                        ),
                        onTap: () => AppRouter.goToStudentProfile(context),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportCard(bool isDark) {
    return Column(
      children: [
        // Help Center - expandable card
        ExpandableCard(
          header: Row(
            children: [
              const Icon(Icons.help_outline,
                  size: 22, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'settings.help_center'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ),
            ],
          ),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'settings.help_center_description'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => AppRouter.goToHelpSupport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'common.learn_more'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          initiallyExpanded: false,
        ),
        const SizedBox(height: 8),
        // Privacy Policy - expandable card
        ExpandableCard(
          header: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 22, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'settings.privacy_policy'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ),
            ],
          ),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'settings.privacy_policy_description'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final Uri url = Uri.parse(
                        'https://AhmedSalah-26.github.io/shehabtech-privacy/');
                    if (!await launchUrl(url)) {
                      debugPrint('Could not launch $url');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'common.read_more'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          initiallyExpanded: false,
        ),
        const SizedBox(height: 8),
        // Terms of Service - expandable card
        ExpandableCard(
          header: Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 22, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'settings.terms_of_service'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ),
            ],
          ),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'settings.terms_of_service_description'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => AppRouter.goToTermsOfService(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'common.read_more'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          initiallyExpanded: false,
        ),
      ],
    );
  }

  Widget _buildDeleteAccountButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedButton(
        onPressed: () => _showDeleteAccountDialog(isDark),
        child: Text(
          'settings.delete_account'.tr(),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      String code, String name, String current, bool isDark) {
    final isSelected = code == current;
    return ListTile(
      onTap: () {
        context.read<SettingsCubit>().updateLanguage(code);
        context.setLocale(Locale(code));
      },
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
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

  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveAlertDialog(
        title: 'settings.delete_account'.tr(),
        content: 'settings.delete_warning'.tr(),
        confirmText: 'common.delete'.tr(),
        cancelText: 'common.cancel'.tr(),
        isDestructive: true,
        onConfirm: () {
          Navigator.pop(ctx);
          _deleteAccount();
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    HapticFeedback.heavyImpact();
    final success = await context.read<SettingsCubit>().deleteAccount();
    if (success && mounted) {
      AppRouter.goToLogin(context);
    }
  }
}
