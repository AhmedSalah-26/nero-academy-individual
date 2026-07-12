import 'package:flutter/material.dart';
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

  const ProfileCard({
    super.key,
    required this.child,
    required this.isDark,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? AppColors.borderDark
                  : AppColors.primary.withValues(alpha: 0.14)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.08 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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

  const ProfileMetaItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.isDark,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c =
        color ?? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);
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
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          const Icon(Icons.school_outlined, color: AppColors.primary, size: 28),
    );
  }
}

/// Progress linear bar
class ProfileProgressBar extends StatelessWidget {
  final double progress;
  final double height;

  const ProfileProgressBar(
      {super.key, required this.progress, this.height = 8});

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

  const ProfileSectionTitle(
      {super.key, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
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
    return SliverAppBar(
      expandedHeight: 118,
      toolbarHeight: 58,
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      foregroundColor: isDark ? AppColors.white : AppColors.textMainLight,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: IconButton(
          icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      title: Text(isArabic ? 'ملف التعلم' : 'Learning Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          )),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          height: 44,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: TabBar(
            controller: tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            dividerColor: Colors.transparent,
            labelColor: AppColors.white,
            unselectedLabelColor:
                isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: isArabic ? 'نظرة عامة' : 'Overview'),
              Tab(text: isArabic ? 'الكورسات' : 'Courses'),
              Tab(text: isArabic ? 'الاختبارات' : 'Quizzes'),
            ],
          ),
        ),
      ),
    );
  }
}
