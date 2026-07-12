import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Quick Action Item Model
class QuickActionItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });
}

/// Quick Actions FAB with expandable menu
class QuickActionsFab extends StatefulWidget {
  final List<QuickActionItem> actions;
  final IconData mainIcon;
  final IconData closeIcon;

  const QuickActionsFab({
    super.key,
    required this.actions,
    this.mainIcon = Icons.add_rounded,
    this.closeIcon = Icons.close_rounded,
  });

  @override
  State<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends State<QuickActionsFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action Items
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final delay = (widget.actions.length - index - 1) * 0.1;

          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final progress = Curves.easeOutBack.transform(
                (_expandAnimation.value - delay).clamp(0.0, 1.0) /
                    (1.0 - delay).clamp(0.01, 1.0),
              );

              return IgnorePointer(
                ignoring: !_isExpanded,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - progress)),
                  child: Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActionItem(
                action: action,
                isDark: isDark,
                onTap: () {
                  _toggle();
                  action.onTap();
                },
              ),
            ),
          );
        }),
        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.primary,
          elevation: 4,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: _isExpanded ? 0.125 : 0,
            child: Icon(
              _isExpanded ? widget.closeIcon : widget.mainIcon,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final QuickActionItem action;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionItem({
    required this.action,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              action.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon Button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              action.icon,
              color: AppColors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple Single FAB
class SimpleFab extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const SimpleFab({
    super.key,
    required this.icon,
    this.label,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? AppColors.primary;

    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        backgroundColor: color,
        elevation: 4,
        icon: Icon(icon, color: AppColors.white),
        label: Text(
          label!,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      backgroundColor: color,
      elevation: 4,
      child: Icon(icon, color: AppColors.white),
    );
  }
}
