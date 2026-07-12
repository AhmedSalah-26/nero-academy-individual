import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Social Links Widget
class InstructorSocialLinks extends StatelessWidget {
  final String? website;
  final String? linkedin;
  final String? twitter;
  final String? youtube;
  final String? github;
  final bool isDark;

  const InstructorSocialLinks({
    super.key,
    this.website,
    this.linkedin,
    this.twitter,
    this.youtube,
    this.github,
    required this.isDark,
  });

  bool get hasAnyLink =>
      website != null ||
      linkedin != null ||
      twitter != null ||
      youtube != null ||
      github != null;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyLink) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (website != null)
          _SocialButton(
            icon: Icons.language_rounded,
            color: AppColors.primary,
            url: website!,
            isDark: isDark,
          ),
        if (linkedin != null)
          _SocialButton(
            icon: Icons.work_rounded,
            color: const Color(0xFF0A66C2),
            url: linkedin!,
            isDark: isDark,
          ),
        if (twitter != null)
          _SocialButton(
            icon: Icons.alternate_email_rounded,
            color: const Color(0xFF1DA1F2),
            url: twitter!,
            isDark: isDark,
          ),
        if (youtube != null)
          _SocialButton(
            icon: Icons.play_circle_filled_rounded,
            color: const Color(0xFFFF0000),
            url: youtube!,
            isDark: isDark,
          ),
        if (github != null)
          _SocialButton(
            icon: Icons.code_rounded,
            color: isDark ? AppColors.white : const Color(0xFF333333),
            url: github!,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String url;
  final bool isDark;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
      ),
    );
  }
}
