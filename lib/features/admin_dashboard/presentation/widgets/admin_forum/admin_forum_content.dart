import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/error_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/admin_forum_cubit.dart';

/// Admin Forum Content - Lists conversations and allows navigation into them
class AdminForumContent extends StatefulWidget {
  const AdminForumContent({super.key});

  @override
  State<AdminForumContent> createState() => _AdminForumContentState();
}

class _AdminForumContentState extends State<AdminForumContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminForumCubit>().loadConversations(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminForumCubit>().loadMoreConversations();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return BlocBuilder<AdminForumCubit, AdminForumState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic, isDark),
            _buildFilterChips(context, state, isArabic, isDark),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(context, state, isArabic, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, AdminForumState state, bool isArabic, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DashboardSearchBar(
              hintText: 'Search conversations...',
              hintTextAr: 'بحث في المحادثات...',
              onSearch: (q) {
                context.read<AdminForumCubit>().loadConversations(
                      search: q.isEmpty ? null : q,
                      typeFilter: state.typeFilter,
                      refresh: true,
                    );
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${state.conversations.length} ${isArabic ? "محادثة" : "chats"}',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, AdminForumState state, bool isArabic, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(
            context,
            label: isArabic ? 'الكل' : 'All',
            isSelected: state.typeFilter == null,
            isDark: isDark,
            onTap: () => context.read<AdminForumCubit>().setTypeFilter(null),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: isArabic ? 'جماعية' : 'Groups',
            isSelected: state.typeFilter == 'multi',
            isDark: isDark,
            onTap: () => context.read<AdminForumCubit>().setTypeFilter('multi'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: isArabic ? 'خاصة' : 'Private',
            isSelected: state.typeFilter == 'single',
            isDark: isDark,
            onTap: () =>
                context.read<AdminForumCubit>().setTypeFilter('single'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AdminForumState state, bool isArabic, bool isDark) {
    if (state.status == AdminForumStatus.loading &&
        state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AdminForumStatus.error) {
      return ErrorState(
        type: ErrorType.server,
        message: state.errorMessage,
        onRetry: () =>
            context.read<AdminForumCubit>().loadConversations(refresh: true),
      );
    }

    if (state.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined,
                size: 48,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا توجد محادثات' : 'No conversations found'),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final conv = state.conversations[index];
        return _buildConversationTile(context, conv, isArabic, isDark);
      },
    );
  }

  Widget _buildConversationTile(BuildContext context, Map<String, dynamic> conv,
      bool isArabic, bool isDark) {
    final isGroup = conv['type'] == 'multi';
    final title = conv['title'] as String? ?? (isArabic ? 'محادثة' : 'Chat');
    final createdAt = conv['created_at'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            isGroup ? Icons.group : Icons.person,
            color: AppColors.primary,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          createdAt.isNotEmpty ? createdAt.substring(0, 10) : '',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isGroup
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isGroup
                ? (isArabic ? 'جماعية' : 'Group')
                : (isArabic ? 'خاصة' : 'Private'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGroup ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
        onTap: () {
          AppRouter.goToChat(
            context,
            conversationId: conv['id'] as String,
            conversationTitle: title,
          );
        },
      ),
    );
  }
}
