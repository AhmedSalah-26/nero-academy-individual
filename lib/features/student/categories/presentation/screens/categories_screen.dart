import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/animations/app_animations.dart';

/// Categories Screen - Browse courses by category
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'Categories',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return SlideFadeIn.up(
            delay: Duration(milliseconds: 50 * index),
            child: _CategoryCard(
              category: category,
              isDark: isDark,
              onTap: () => context.pushNamed(
                'search',
                queryParameters: {'category': category.id},
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                category.name,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Course count
              Text(
                '${category.courseCount} courses',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int courseCount;

  const _Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.courseCount,
  });
}

const _categories = [
  _Category(
    id: 'development',
    name: 'Development',
    icon: Icons.code_rounded,
    color: AppColors.primary,
    courseCount: 245,
  ),
  _Category(
    id: 'business',
    name: 'Business',
    icon: Icons.business_center_rounded,
    color: AppColors.success,
    courseCount: 189,
  ),
  _Category(
    id: 'design',
    name: 'Design',
    icon: Icons.palette_rounded,
    color: AppColors.warning,
    courseCount: 156,
  ),
  _Category(
    id: 'marketing',
    name: 'Marketing',
    icon: Icons.campaign_rounded,
    color: AppColors.error,
    courseCount: 98,
  ),
  _Category(
    id: 'it-software',
    name: 'IT & Software',
    icon: Icons.computer_rounded,
    color: AppColors.info,
    courseCount: 178,
  ),
  _Category(
    id: 'personal-dev',
    name: 'Personal Dev',
    icon: Icons.psychology_rounded,
    color: AppColors.primary,
    courseCount: 134,
  ),
  _Category(
    id: 'photography',
    name: 'Photography',
    icon: Icons.camera_alt_rounded,
    color: Color(0xFFEC4899),
    courseCount: 67,
  ),
  _Category(
    id: 'music',
    name: 'Music',
    icon: Icons.music_note_rounded,
    color: Color(0xFF14B8A6),
    courseCount: 45,
  ),
  _Category(
    id: 'health',
    name: 'Health & Fitness',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFF97316),
    courseCount: 89,
  ),
  _Category(
    id: 'language',
    name: 'Language',
    icon: Icons.translate_rounded,
    color: Color(0xFF6366F1),
    courseCount: 112,
  ),
];
