import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../cubit/admin_users_cubit.dart';
import 'user_list_item.dart';

/// Admin Users Content
class AdminUsersContent extends StatefulWidget {
  const AdminUsersContent({super.key});

  @override
  State<AdminUsersContent> createState() => _AdminUsersContentState();
}

class _AdminUsersContentState extends State<AdminUsersContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminUsersCubit>().loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminUsersCubit>().loadMoreUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminUsersCubit, AdminUsersState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic, isDark),
            Expanded(child: _buildUsersList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminUsersState state,
    bool isArabic,
    bool isDark,
  ) {
    final roleOptions = [
      {
        'value': 'student',
        'label': 'Students',
        'labelAr': 'الطلاب',
        'icon': Icons.school_rounded
      },
      {
        'value': 'instructor',
        'label': 'Instructors',
        'labelAr': 'المدرسين',
        'icon': Icons.person_rounded
      },
      {
        'value': 'admin',
        'label': 'Admins',
        'labelAr': 'المسؤولين',
        'icon': Icons.admin_panel_settings_rounded
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DashboardSearchBar(
                  hintText: 'Search by name, email, or phone...',
                  hintTextAr: 'بحث بالاسم أو البريد أو الهاتف...',
                  onSearch: (query) {
                    context.read<AdminUsersCubit>().search(query);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: DropdownButton<int>(
                  value: state.currentRole.index,
                  underline: const SizedBox(),
                  items: roleOptions.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(entry.value['icon'] as IconData, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isArabic
                                ? entry.value['labelAr'] as String
                                : entry.value['label'] as String,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (index) {
                    if (index != null) {
                      context
                          .read<AdminUsersCubit>()
                          .changeRole(UserRole.values[index]);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    AdminUsersState state,
    bool isArabic,
  ) {
    if (state.isLoading && state.users.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا يوجد مستخدمين' : 'No users found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminUsersCubit>().loadUsers(
            role: state.currentRole,
            refresh: true,
          ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final user = state.users[index];
          return UserListItem(
            user: user,
            onBan: () => _showBanDialog(context, user.id),
            onUnban: () => context.read<AdminUsersCubit>().unbanUser(user.id),
            onView: () => _showUserDetailsDialog(context, user),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 48, height: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 150),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 200),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBanDialog(BuildContext context, String userId) {
    final user = context
        .read<AdminUsersCubit>()
        .state
        .users
        .firstWhere((u) => u.id == userId);

    AppRouter.goToBanUser(
      context,
      userId: userId,
      userName: user.displayName,
      onBan: (duration, reason) {
        context.read<AdminUsersCubit>().banUser(userId, duration, reason);
      },
    );
  }

  void _showUserDetailsDialog(BuildContext context, user) {
    AppRouter.goToUserDetails(
      context,
      userId: user.id,
      user: user,
      onUpdate: (updatedUser) {
        context.read<AdminUsersCubit>().updateUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم تحديث بيانات المستخدم'
                  : 'User updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onBan: () {
        Navigator.pop(context);
        _showBanDialog(context, user.id);
      },
      onUnban: () {
        context.read<AdminUsersCubit>().unbanUser(user.id);
      },
    );
  }
}
