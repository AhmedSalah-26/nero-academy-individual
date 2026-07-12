import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

class HomeParentPortalSection extends StatelessWidget {
  final String locale;

  const HomeParentPortalSection({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isArabic = locale == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.family_restroom,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'بوابة ولي الأمر' : 'Parent Portal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic
                        ? 'تابع تقدم أبنائك ونتائجهم'
                        : 'Track your children\'s progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => context.push('/parent_entrance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isArabic ? 'دخول' : 'Enter'),
            ),
          ],
        ),
      ),
    );
  }
}
