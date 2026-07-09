import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';

/// Shared small UI components for student profile screens

/// Progress color helper
Color profileProgressColor(double v) {
  if (v >= 80) return AppColors.success;
  if (v >= 50) return AppColors.info;
  if (v >= 25) return AppColors.warning;
  return AppColors.error;
}

/// Gradient card wrapper
class ProfileCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? borderColor;

  const ProfileCard({super.key, required this.child, required this.isDark, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: child,
    );
  }
}

/// Stat mini-card
class ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const ProfileStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Meta info item (icon + label)
class ProfileMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;

  const ProfileMetaItem({super.key, required this.icon, required this.label, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: c)),
      ],
    );
  }
}

/// Course thumbnail placeholder
class CourseThumbnailPlaceholder extends StatelessWidget {
  final double size;
  const CourseThumbnailPlaceholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 28),
    );
  }
}

/// Progress linear bar
class ProfileProgressBar extends StatelessWidget {
  final double progress;
  final double height;

  const ProfileProgressBar({super.key, required this.progress, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final color = profileProgressColor(progress);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress / 100,
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Section title
class ProfileSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const ProfileSectionTitle({super.key, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ));
  }
}

/// Sliver app bar header for student profile
class StudentProfileSliverHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final TabController tabController;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onBack;

  const StudentProfileSliverHeader({
    super.key,
    required this.profile,
    required this.tabController,
    required this.isDark,
    required this.isArabic,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?['name'] as String? ?? '';
    final email = profile?['email'] as String? ?? '';
    final avatarUrl = profile?['avatar_url'] as String?;
    final joined = profile?['created_at'] != null
        ? DateFormat('yyyy/MM/dd').format(DateTime.parse(profile!['created_at'] as String))
        : null;

    return SliverAppBar(
      expandedHeight: 270,
      pinned: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      title: Text(isArabic ? 'ملف التعلم' : 'Learning Profile',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primaryLight.withValues(alpha: 0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 38, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                if (joined != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 11, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(
                        (isArabic ? 'انضم: ' : 'Joined: ') + joined,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: tabController,
        indicatorColor: AppColors.primary,
        labelColor: isDark ? AppColors.textMainDark : AppColors.primary,
        unselectedLabelColor: AppColors.grey500,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: isArabic ? 'نظرة عامة' : 'Overview'),
          Tab(text: isArabic ? 'الكورسات' : 'Courses'),
          Tab(text: isArabic ? 'الاختبارات' : 'Quizzes'),
        ],
      ),
    );
  }
}
