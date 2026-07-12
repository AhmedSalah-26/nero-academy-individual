import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';
import 'package:lms_platform/features/student/course_forum/presentation/cubit/forums_list_cubit.dart';
import 'package:lms_platform/features/student/course_forum/presentation/cubit/forums_list_state.dart';

/// Forums List Screen - Shows all conversations (group + private)
class ForumsListScreen extends StatelessWidget {
  const ForumsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForumsListCubit(Supabase.instance.client)
        ..loadConversations(refresh: true),
      child: const _ForumsListView(),
    );
  }
}

class _ForumsListView extends StatefulWidget {
  const _ForumsListView();

  @override
  State<_ForumsListView> createState() => _ForumsListViewState();
}

class _ForumsListViewState extends State<_ForumsListView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: BlocBuilder<ForumsListCubit, ForumsListState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(context, state, isArabic, isDark),
                _buildForumFilterChips(context, state, isArabic, isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<ForumsListCubit>().loadConversations(
                            search: state.searchQuery,
                            typeFilter: state.typeFilter,
                            refresh: true,
                          );
                    },
                    child: _buildBody(context, state, isArabic, isDark),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ForumsListState state, bool isArabic, bool isDark) {
    final count = state.conversations.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DashboardSearchBar(
              hintText: 'Search conversations...',
              hintTextAr:
                  '\u0628\u062d\u062b \u0641\u064a \u0627\u0644\u0645\u062d\u0627\u062f\u062b\u0627\u062a...',
              initialValue: state.searchQuery,
              onSearch: (q) {
                context.read<ForumsListCubit>().loadConversations(
                      search: q.isEmpty ? null : q,
                      typeFilter: state.typeFilter,
                      refresh: true,
                    );
              },
            ),
          ),
          const SizedBox(width: 12),
          if (state.isInstructor)
            IconButton(
              tooltip: isArabic
                  ? '\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0645\u0646\u062a\u062f\u064a\u0627\u062a'
                  : 'Manage forums',
              onPressed: () async {
                await AppRouter.goToCourseForumsManagement(context);
                if (!context.mounted) return;
                await context
                    .read<ForumsListCubit>()
                    .loadConversations(refresh: true);
              },
              icon: const Icon(Icons.tune_rounded),
            ),
          Text(
            isArabic
                ? '$count \u0645\u062d\u0627\u062f\u062b\u0629'
                : '$count chats',
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

  Widget _buildForumFilterChips(
      BuildContext context, ForumsListState state, bool isArabic, bool isDark) {
    final selectedIndex =
        state.typeFilter == null ? 0 : (state.typeFilter == 'multi' ? 1 : 2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildForumTabItem(
            label: isArabic ? '\u0627\u0644\u0643\u0644' : 'All',
            isSelected: selectedIndex == 0,
            isDark: isDark,
            onTap: () => _setTypeFilter(context, null),
          ),
          const SizedBox(width: 12),
          _buildForumTabItem(
            label: isArabic ? '\u062c\u0645\u0627\u0639\u064a\u0629' : 'Groups',
            isSelected: selectedIndex == 1,
            isDark: isDark,
            onTap: () => _setTypeFilter(context, 'multi'),
          ),
          const SizedBox(width: 12),
          _buildForumTabItem(
            label: isArabic ? '\u062e\u0627\u0635\u0629' : 'Private',
            isSelected: selectedIndex == 2,
            isDark: isDark,
            onTap: () => _setTypeFilter(context, 'single'),
          ),
        ],
      ),
    );
  }

  void _setTypeFilter(BuildContext context, String? typeFilter) {
    HapticFeedback.lightImpact();
    context.read<ForumsListCubit>().setTypeFilter(typeFilter);
  }

  Widget _buildForumTabItem({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.grey700 : AppColors.grey200,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.white
                : (isDark ? AppColors.grey300 : AppColors.grey600),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFilterChips(
      BuildContext context, ForumsListState state, bool isArabic, bool isDark) {
    final selectedIndex =
        state.typeFilter == null ? 0 : (state.typeFilter == 'multi' ? 1 : 2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.grey800.withValues(alpha: 0.5)
            : AppColors.grey200,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / 3;

          final AlignmentDirectional alignment;
          if (selectedIndex == 0) {
            alignment = AlignmentDirectional.centerStart;
          } else if (selectedIndex == 1) {
            alignment = const AlignmentDirectional(0.0, 0.0);
          } else {
            alignment = AlignmentDirectional.centerEnd;
          }

          return Stack(
            children: [
              // Sliding Indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                alignment: alignment,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              // Buttons
              Positioned.fill(
                child: Row(
                  children: [
                    _buildTabItem(
                      label: isArabic ? 'الكل' : 'All',
                      isSelected: selectedIndex == 0,
                      isDark: isDark,
                      onTap: () =>
                          context.read<ForumsListCubit>().setTypeFilter(null),
                    ),
                    _buildTabItem(
                      label: isArabic ? 'جماعية' : 'Groups',
                      isSelected: selectedIndex == 1,
                      isDark: isDark,
                      onTap: () => context
                          .read<ForumsListCubit>()
                          .setTypeFilter('multi'),
                    ),
                    _buildTabItem(
                      label: isArabic ? 'خاصة' : 'Private',
                      isSelected: selectedIndex == 2,
                      isDark: isDark,
                      onTap: () => context
                          .read<ForumsListCubit>()
                          .setTypeFilter('single'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTabItem({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.grey400 : AppColors.grey600),
              fontFamily: 'Tajawal', // Using the app's Arabic font if available
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, ForumsListState state, bool isArabic, bool isDark) {
    if (state.status == ForumsListStatus.loading &&
        state.conversations.isEmpty) {
      return _buildConversationsLoadingShimmer(isDark);
    }

    if (state.status == ForumsListStatus.error) {
      return ErrorState(
        type: ErrorType.generic,
        message: state.errorMessage,
        onRetry: () =>
            context.read<ForumsListCubit>().loadConversations(refresh: true),
      );
    }

    final widgets = <Widget>[];

    if (state.conversations.isEmpty) {
      widgets.add(_buildEmptyConversations(isArabic));
    } else {
      for (var i = 0; i < state.conversations.length; i++) {
        final conversation = state.conversations[i];
        widgets.add(
          SlideFadeIn.fromBottom(
            delay: Duration(milliseconds: 80 * i),
            child:
                _buildConversationTile(context, conversation, isArabic, isDark),
          ),
        );
        if (i < state.conversations.length - 1) {
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: widgets,
    );
  }

  Widget _buildConversationsLoadingShimmer(bool isDark) {
    final baseColor =
        isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase;
    final highlightColor =
        isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: index < 8 ? 60 * index : 480),
          child: ShimmerEffect(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : AppColors.primary.withValues(alpha: 0.25),
                  width: isDark ? 1.5 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 180,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 10,
                        width: 42,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 18,
                        width: 62,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyConversations(bool isArabic) {
    return EmptyState(
      type: EmptyStateType.forum,
      compact: false,
      title: isArabic
          ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u062d\u0627\u062f\u062b\u0627\u062a \u0628\u0639\u062f'
          : 'No Conversations Yet',
    );
  }

  Widget _buildConversationTile(BuildContext context, Conversation conversation,
      bool isArabic, bool isDark) {
    final isGroup = conversation.type == ConversationType.multi;
    final title = conversation.displayTitle;
    final lastMessage = conversation.lastMessage;
    final lastMessageText = lastMessage?.messageText ?? '';
    final lastMessageTime = lastMessage?.createdAt;

    String timeStr = '';
    if (lastMessageTime != null) {
      try {
        final dt = lastMessageTime.toLocal();
        timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        AppRouter.goToChat(
          context,
          conversationId: conversation.id,
          conversationTitle: title,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.7)
                : AppColors.primary.withValues(alpha: 0.25),
            width: isDark ? 1.5 : 1.2,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail (Avatar)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: conversation.otherUserAvatar != null
                      ? Image.network(
                          conversation.otherUserAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            isGroup ? Icons.group : Icons.person,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        )
                      : Icon(
                          isGroup ? Icons.group : Icons.person,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with chevron
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.white
                                : AppColors.textMainLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Last Message
                  if (lastMessageText.isNotEmpty)
                    Text.rich(
                      TextSpan(
                        children: [
                          if (isGroup && lastMessage != null)
                            TextSpan(
                              text: '${lastMessage.userName}: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight,
                              ),
                            ),
                          TextSpan(
                            text: lastMessageText,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (lastMessageText.isEmpty)
                    Text(
                      isArabic ? 'لا توجد رسائل' : 'No messages',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Time & Badge
                  Row(
                    children: [
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? AppColors.grey400 : AppColors.grey500,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
                            color:
                                isGroup ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
