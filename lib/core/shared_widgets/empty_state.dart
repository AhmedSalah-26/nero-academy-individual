import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'app_button.dart';

/// Empty State Type
enum EmptyStateType {
  courses,
  cart,
  wishlist,
  search,
  notifications,
  certificates,
  myLearning,
  instructors,
  reviews,
  qa,
  generic,
  lessons,
  notes,
  bookmarks,
  attachments,
  announcements,
  quizzes,
  forum,
}

/// Unified Empty State Widget with beautiful illustrations
class EmptyState extends StatefulWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customIcon;
  final bool showAnimation;
  final bool compact;

  const EmptyState({
    super.key,
    this.type = EmptyStateType.generic,
    this.title,
    this.message,
    this.icon,
    this.actionText,
    this.onAction,
    this.customIcon,
    this.showAnimation = true,
    this.compact = false,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    if (widget.showAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig(Theme.of(context).colorScheme.primary);

    if (widget.compact) {
      return _buildCompact(isDark, config);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: widget.customIcon ?? _buildIllustration(isDark, config),
              ),
              const SizedBox(height: 32),
              Text(
                widget.title ?? config.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.message ?? config.message,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.onAction != null) ...[
                const SizedBox(height: 28),
                AppButton(
                  text: widget.actionText ?? config.actionText,
                  onPressed: widget.onAction!,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.medium,
                  icon: config.actionIcon,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(bool isDark, _EmptyStateConfig config) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSimpleIcon(isDark, config),
          const SizedBox(height: 16),
          Text(
            widget.title ?? config.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            widget.message ?? config.message,
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleIcon(bool isDark, _EmptyStateConfig config) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.icon ?? config.icon,
        size: 32,
        color: config.color,
      ),
    );
  }

  Widget _buildIllustration(bool isDark, _EmptyStateConfig config) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circles
          Positioned(
            top: 10,
            left: 10,
            child: _buildCircle(80, config.color.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: _buildCircle(60, config.color.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 40,
            right: 30,
            child: _buildCircle(30, config.color.withValues(alpha: 0.1)),
          ),
          // Main icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  config.color.withValues(alpha: 0.15),
                  config.color.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: config.color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              widget.icon ?? config.icon,
              size: 56,
              color: config.color,
            ),
          ),
          // Decorative elements
          Positioned(
            top: 30,
            left: 40,
            child: _buildDot(8, config.color.withValues(alpha: 0.4)),
          ),
          Positioned(
            bottom: 40,
            left: 30,
            child: _buildDot(6, config.color.withValues(alpha: 0.3)),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: _buildDot(10, config.color.withValues(alpha: 0.5)),
          ),
          Positioned(
            bottom: 30,
            right: 40,
            child: _buildDot(5, config.color.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  _EmptyStateConfig _getConfig(Color primary) {
    switch (widget.type) {
      case EmptyStateType.courses:
        return _EmptyStateConfig(
          icon: Icons.school_rounded,
          title: 'empty.courses_title'.tr(),
          message: 'empty.courses_message'.tr(),
          actionText: 'empty.browse_courses'.tr(),
          actionIcon: Icons.explore_rounded,
          color: primary,
        );
      case EmptyStateType.cart:
        return _EmptyStateConfig(
          icon: Icons.shopping_cart_rounded,
          title: 'empty.cart_title'.tr(),
          message: 'empty.cart_message'.tr(),
          actionText: 'empty.browse_courses'.tr(),
          actionIcon: Icons.explore_rounded,
          color: primary,
        );
      case EmptyStateType.wishlist:
        return _EmptyStateConfig(
          icon: Icons.favorite_rounded,
          title: 'empty.wishlist_title'.tr(),
          message: 'empty.wishlist_message'.tr(),
          actionText: 'empty.explore_courses'.tr(),
          actionIcon: Icons.explore_rounded,
          color: primary,
        );
      case EmptyStateType.search:
        return _EmptyStateConfig(
          icon: Icons.search_off_rounded,
          title: 'empty.search_title'.tr(),
          message: 'empty.search_message'.tr(),
          actionText: 'empty.clear_filters'.tr(),
          actionIcon: Icons.filter_alt_off_rounded,
          color: primary,
        );
      case EmptyStateType.notifications:
        return _EmptyStateConfig(
          icon: Icons.notifications_none_rounded,
          title: 'empty.notifications_title'.tr(),
          message: 'empty.notifications_message'.tr(),
          actionText: 'empty.refresh'.tr(),
          actionIcon: Icons.refresh_rounded,
          color: primary,
        );
      case EmptyStateType.certificates:
        return _EmptyStateConfig(
          icon: Icons.workspace_premium_rounded,
          title: 'empty.certificates_title'.tr(),
          message: 'empty.certificates_message'.tr(),
          actionText: 'empty.start_learning'.tr(),
          actionIcon: Icons.play_arrow_rounded,
          color: primary,
        );
      case EmptyStateType.myLearning:
        return _EmptyStateConfig(
          icon: Icons.menu_book_rounded,
          title: 'empty.my_learning_title'.tr(),
          message: 'empty.my_learning_message'.tr(),
          actionText: 'empty.browse_courses'.tr(),
          actionIcon: Icons.explore_rounded,
          color: primary,
        );
      case EmptyStateType.instructors:
        return _EmptyStateConfig(
          icon: Icons.person_search_rounded,
          title: 'empty.instructors_title'.tr(),
          message: 'empty.instructors_message'.tr(),
          actionText: 'empty.clear_filters'.tr(),
          actionIcon: Icons.filter_alt_off_rounded,
          color: primary,
        );
      case EmptyStateType.reviews:
        return _EmptyStateConfig(
          icon: Icons.rate_review_rounded,
          title: 'empty.reviews_title'.tr(),
          message: 'empty.reviews_message'.tr(),
          actionText: 'empty.write_review'.tr(),
          actionIcon: Icons.edit_rounded,
          color: primary,
        );
      case EmptyStateType.qa:
        return _EmptyStateConfig(
          icon: Icons.question_answer_rounded,
          title: 'empty.qa_title'.tr(),
          message: 'empty.qa_message'.tr(),
          actionText: 'empty.ask_question'.tr(),
          actionIcon: Icons.add_comment_rounded,
          color: primary,
        );
      case EmptyStateType.generic:
        return _EmptyStateConfig(
          icon: Icons.inbox_rounded,
          title: 'empty.generic_title'.tr(),
          message: 'empty.generic_message'.tr(),
          actionText: 'empty.go_back'.tr(),
          actionIcon: Icons.arrow_back_rounded,
          color: primary,
        );
      case EmptyStateType.lessons:
        return _EmptyStateConfig(
          icon: Icons.play_lesson_rounded,
          title: 'empty.lessons_title'.tr(),
          message: 'empty.lessons_message'.tr(),
          actionText: 'empty.go_back'.tr(),
          actionIcon: Icons.arrow_back_rounded,
          color: primary,
        );
      case EmptyStateType.notes:
        return _EmptyStateConfig(
          icon: Icons.note_alt_rounded,
          title: 'empty.notes_title'.tr(),
          message: 'empty.notes_message'.tr(),
          actionText: 'empty.add_note'.tr(),
          actionIcon: Icons.add_rounded,
          color: primary,
        );
      case EmptyStateType.bookmarks:
        return _EmptyStateConfig(
          icon: Icons.bookmark_rounded,
          title: 'empty.bookmarks_title'.tr(),
          message: 'empty.bookmarks_message'.tr(),
          actionText: 'empty.go_back'.tr(),
          actionIcon: Icons.arrow_back_rounded,
          color: primary,
        );
      case EmptyStateType.attachments:
        return _EmptyStateConfig(
          icon: Icons.attach_file_rounded,
          title: 'empty.attachments_title'.tr(),
          message: 'empty.attachments_message'.tr(),
          actionText: 'empty.go_back'.tr(),
          actionIcon: Icons.arrow_back_rounded,
          color: primary,
        );
      case EmptyStateType.announcements:
        return _EmptyStateConfig(
          icon: Icons.campaign_rounded,
          title: 'empty.announcements_title'.tr(),
          message: 'empty.announcements_message'.tr(),
          actionText: 'empty.go_back'.tr(),
          actionIcon: Icons.arrow_back_rounded,
          color: primary,
        );
      case EmptyStateType.quizzes:
        return _EmptyStateConfig(
          icon: Icons.quiz_rounded,
          title: 'empty.quizzes_title'.tr(),
          message: 'empty.quizzes_message'.tr(),
          actionText: 'empty.go_back'.tr(),
          actionIcon: Icons.arrow_back_rounded,
          color: primary,
        );
      case EmptyStateType.forum:
        return _EmptyStateConfig(
          icon: Icons.forum_rounded,
          title: 'empty.forum_title'.tr(),
          message: 'empty.forum_message'.tr(),
          actionText: 'empty.start_conversation'.tr(),
          actionIcon: Icons.chat_rounded,
          color: primary,
        );
    }
  }
}

class _EmptyStateConfig {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final IconData actionIcon;
  final Color color;

  _EmptyStateConfig({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.actionIcon,
    required this.color,
  });
}

/// Courses Empty State - Specialized for courses list
class CoursesEmptyState extends StatelessWidget {
  final VoidCallback? onBrowse;

  const CoursesEmptyState({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      type: EmptyStateType.courses,
      onAction: onBrowse,
    );
  }
}

/// Search Empty State with query
class SearchEmptyState extends StatelessWidget {
  final String? query;
  final VoidCallback? onClearFilters;

  const SearchEmptyState({
    super.key,
    this.query,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      type: EmptyStateType.search,
      message: query != null
          ? 'empty.search_no_results_for'.tr(args: [query!])
          : null,
      onAction: onClearFilters,
    );
  }
}
