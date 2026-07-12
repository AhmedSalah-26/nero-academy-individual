import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Auth Tab Switcher - Toggle between Login and Sign Up
class AuthTabSwitcher extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const AuthTabSwitcher({
    super.key,
    required this.isLogin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.grey800.withValues(alpha: 0.5)
            : AppColors.grey200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Subtracting padding to avoid overflow
          final totalWidth = constraints.maxWidth;
          final pillWidth = totalWidth / 2;

          return Stack(
            children: [
              // Sliding background pill
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                alignment: isLogin
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Container(
                  width: pillWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey700 : AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
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
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.grey400
                                      : AppColors.grey500),
                              fontFamily: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontFamily,
                            ),
                            child: const Text('تسجيل الدخول'),
                          ),
                        ),
                      ),
                    ),
                    // Sign Up Tab
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
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.grey400
                                      : AppColors.grey500),
                              fontFamily: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontFamily,
                            ),
                            child: const Text('إنشاء حساب'),
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
