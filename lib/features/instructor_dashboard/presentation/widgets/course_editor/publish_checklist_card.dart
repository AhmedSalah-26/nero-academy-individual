import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Displays a checklist of required fields with a progress bar.
class PublishChecklistCard extends StatelessWidget {
  const PublishChecklistCard({
    super.key,
    required this.state,
    required this.isArabic,
    required this.isDark,
  });

  final CourseEditorState state;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final checks = [
      _CheckItem(
        title: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
        isComplete: state.titleAr.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
        isComplete: state.titleEn.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'الوصف (عربي)' : 'Description (Arabic)',
        isComplete: state.descriptionAr.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'الوصف (إنجليزي)' : 'Description (English)',
        isComplete: state.descriptionEn.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'التصنيف' : 'Category',
        isComplete: state.categoryId != null,
      ),
      _CheckItem(
        title: isArabic ? 'الأقسام' : 'Sections',
        isComplete: state.sections.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'الدروس' : 'Lessons',
        isComplete: state.sections.any((s) => s.lessons.isNotEmpty),
      ),
    ];

    final completedCount = checks.where((c) => c.isComplete).length;
    final progress = completedCount / checks.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'قائمة التحقق للنشر' : 'Publish Checklist',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress == 1
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$completedCount/${checks.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: progress == 1 ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? AppColors.borderDark : AppColors.grey200,
            valueColor: AlwaysStoppedAnimation(
              progress == 1 ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(height: 20),
          ...checks.map((check) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      check.isComplete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: check.isComplete
                          ? AppColors.success
                          : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      check.title,
                      style: TextStyle(
                        color: check.isComplete
                            ? (isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight)
                            : Colors.grey[500],
                        decoration: check.isComplete
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CheckItem {
  final String title;
  final bool isComplete;
  const _CheckItem({required this.title, required this.isComplete});
}
