import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../core/services/user_role_service.dart';
import '../../../../core/shared_widgets/responsive_dialog.dart';
import '../../../../core/shared_widgets/error_state.dart';
import '../../../../core/shared_widgets/loading_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

/// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await context.read<ProfileCubit>().loadProfile(userId);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: 500, child: AppLoadingState()),
              );
            }
            if (state.isError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: _buildError(state, isDark),
                ),
              );
            }
            return _buildContent(state, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildError(ProfileState state, bool isDark) {
    return ErrorState(
      type: ErrorType.generic,
      message: state.errorMessage ?? 'errors.unknown'.tr(),
      onRetry: _loadProfile,
    );
  }

  Widget _buildContent(ProfileState state, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(state, isDark),
          const SizedBox(height: 24),
          _buildStats(state, isDark),
          const SizedBox(height: 24),
          _buildMenuSection(isDark),
          const SizedBox(height: 24),
          _buildLogoutButton(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileState state, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          // Avatar with border
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: isDark
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: state.userAvatar != null
                  ? NetworkImage(state.userAvatar!)
                  : null,
              child: state.userAvatar == null
                  ? const Icon(Icons.person, size: 45, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            state.userName.firstTwoWords,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            state.userEmail,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ProfileState state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildStatItem(
                '${state.coursesCount}', 'profile.courses'.tr(), isDark),
            _buildStatDivider(isDark),
            _buildStatItem('${state.dayStreak}', 'profile.streak'.tr(), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? AppColors.grey700 : AppColors.grey200,
    );
  }

  Widget _buildMenuSection(bool isDark) {
    final isArabic = context.locale.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Dashboard links based on role
            FutureBuilder<String?>(
              future: UserRoleService.getCurrentUserRole(),
              builder: (context, snapshot) {
                final role = snapshot.data;
                if (role == 'instructor' || role == 'admin') {
                  return Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.school_outlined,
                        title: 'dashboard.instructor_dashboard'.tr(),
                        onTap: () => AppRouter.goToInstructorDashboard(context),
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                    ],
                  );
                }
                // Student learning profile
                if (role == 'student') {
                  return Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.analytics_outlined,
                        title: isArabic ? 'ملف التعلم' : 'Learning Profile',
                        onTap: () => AppRouter.goToStudentProfile(context),
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildMenuItem(
              icon: Icons.edit_outlined,
              title: 'profile.edit_profile'.tr(),
              onTap: () => AppRouter.goToEditProfile(context),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'settings.notifications'.tr(),
              onTap: () => AppRouter.goToNotifications(context),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Icons.menu_book_outlined,
              title: 'my_learning.my_learning'.tr(),
              onTap: () => AppRouter.goToMyLearning(context),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Icons.receipt_long_outlined,
              title: isArabic ? 'حالة الطلبات' : 'Orders Status',
              onTap: () => AppRouter.goToOrdersStatus(context),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Icons.forum_outlined,
              title: isArabic ? 'المنتديات' : 'Forums',
              onTap: () => context.pushNamed('forums-tab'),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Icons.favorite_outline,
              title: 'wishlist.wishlist'.tr(),
              onTap: () => context.pushNamed('wishlist'),
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'settings.settings'.tr(),
              onTap: () => AppRouter.goToSettings(context),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 52,
      color: isDark ? AppColors.grey700 : AppColors.grey100,
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(isDark),
          icon: const Icon(Icons.logout, color: AppColors.error),
          label: Text(
            'auth.logout'.tr(),
            style: const TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveAlertDialog(
        title: 'auth.logout'.tr(),
        content: 'profile.logout_confirm'.tr(),
        confirmText: 'auth.logout'.tr(),
        cancelText: 'common.cancel'.tr(),
        isDestructive: true,
        onConfirm: () {
          Navigator.pop(ctx);
          _logout();
        },
      ),
    );
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    await LogoutService.logout(context);
  }
}
