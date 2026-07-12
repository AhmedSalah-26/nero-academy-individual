import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

class SocialButton extends StatelessWidget {
  final Widget icon;
  final bool isDark;
  final VoidCallback? onTap;

  const SocialButton({
    super.key,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.grey700 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.network(
        'https://www.google.com/favicon.ico',
        errorBuilder: (_, __, ___) => const Icon(
          Icons.g_mobiledata_rounded,
          size: 28,
          color: Colors.red,
        ),
      ),
    );
  }
}

class FacebookIcon extends StatelessWidget {
  const FacebookIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
