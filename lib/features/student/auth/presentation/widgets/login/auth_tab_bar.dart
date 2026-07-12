import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

class AuthTabBar extends StatelessWidget {
  final bool isLogin;
  final String loginLabel;
  final String registerLabel;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const AuthTabBar({
    super.key,
    required this.isLogin,
    required this.loginLabel,
    required this.registerLabel,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Premium theme-tailored background colors (no boring greys!)
    final trackColor = isDark
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.06);

    final borderColor = isDark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final pillWidth = totalWidth / 2;

          return Stack(
            children: [
              // Sliding background pill
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack, // Playful premium bounce
                alignment: isLogin
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Container(
                  width: pillWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // Content (Interactive Tab Buttons)
              Positioned.fill(
                child: Row(
                  children: [
                    // Login Tab
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(true),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isLogin
                                  ? (isDark
                                      ? AppColors.primaryOnDark
                                      : AppColors.primary)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                              fontFamily: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontFamily,
                            ),
                            child: Text(loginLabel),
                          ),
                        ),
                      ),
                    ),
                    // Register Tab
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(false),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !isLogin
                                  ? (isDark
                                      ? AppColors.primaryOnDark
                                      : AppColors.primary)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                              fontFamily: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontFamily,
                            ),
                            child: Text(registerLabel),
                          ),
                        ),
                      ),
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
}
