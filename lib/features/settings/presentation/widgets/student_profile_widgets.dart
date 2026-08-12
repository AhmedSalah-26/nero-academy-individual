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

  const ProfileCard(
      {super.key, required this.child, required this.isDark, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary
                .withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: color.withValues(alpha: isDark ? 0.32 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary
                .withValues(alpha: isDark ? 0.06 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface.withValues(alpha: 0.65);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: c)),
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
    final theme = Theme.of(context);
    return Text(title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ));
  }
}

/// Sliver app bar header for student profile
class StudentProfileSliverHeader extends StatelessWidget {
  final TabController tabController;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onBack;

  const StudentProfileSliverHeader({
    super.key,
    required this.tabController,
    required this.isDark,
    required this.isArabic,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isDark ? AppColors.primaryOnDark : AppColors.primary;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: theme.scaffoldBackgroundColor,
      foregroundColor: theme.colorScheme.onSurface,
      leading:
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      title: Text(
        isArabic ? 'ملف التعلم' : 'Learning Profile',
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          height: 48,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.65),
            ),
          ),
          child: TabBar(
            controller: tabController,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: isDark ? AppColors.backgroundDark : AppColors.white,
            unselectedLabelColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.62),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
