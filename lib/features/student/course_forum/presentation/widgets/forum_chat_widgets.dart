import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';

/// Forum Chat Input Widget
class ForumChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onSend;

  const ForumChatInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.isDark,
    required this.isArabic,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTextField()),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.send, color: Colors.white, size: 20),
        onPressed: onSend,
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: 4,
        minLines: 1,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: isArabic ? 'اكتب رسالة...' : 'Type a message...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onSubmitted: (_) => onSend(),
      ),
    );
  }
}

/// Reply Preview Widget
class ReplyPreview extends StatelessWidget {
  final ConversationMessage message;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.isDark,
    required this.isArabic,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.userName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  message.messageText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }
}

/// Forum Search Bar Widget
class ForumSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isArabic;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const ForumSearchBar({
    super.key,
    required this.controller,
    required this.isDark,
    required this.isArabic,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GlassSearchBar(
              controller: controller,
              hintText: isArabic
                  ? '\u0628\u062d\u062b \u0641\u064a \u0627\u0644\u0631\u0633\u0627\u0626\u0644...'
                  : 'Search messages...',
              onChanged: onChanged,
              autofocus: true,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              height: 44,
              borderRadius: 12,
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLegacySearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText:
                      isArabic ? 'بحث في الرسائل...' : 'Search messages...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }
}

/// Forum Chat App Bar
class ForumChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String courseTitle;
  final bool isDark;
  final bool isArabic;
  final bool isSearching;
  final VoidCallback onSearchClose;
  final VoidCallback onSearchTap;

  const ForumChatAppBar({
    super.key,
    required this.courseTitle,
    required this.isDark,
    required this.isArabic,
    required this.isSearching,
    required this.onSearchClose,
    required this.onSearchTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              courseTitle,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
          onPressed: onSearchTap,
        ),
      ],
    );
  }
}

/// Date Divider Widget
class DateDivider extends StatelessWidget {
  final DateTime date;
  final bool isDark;
  final bool isArabic;

  const DateDivider({
    super.key,
    required this.date,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(),
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (_isSameDay(dateOnly, today)) {
      return isArabic ? 'اليوم' : 'Today';
    }
    if (_isSameDay(dateOnly, today.subtract(const Duration(days: 1)))) {
      return isArabic ? 'أمس' : 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
