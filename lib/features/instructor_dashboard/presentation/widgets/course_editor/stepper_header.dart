import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Horizontal stepper shown at the top of the course creation flow.
class CourseEditorStepperHeader extends StatelessWidget {
  const CourseEditorStepperHeader({
    super.key,
    required this.state,
    required this.isDark,
  });

  final CourseEditorState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final steps = [
      isArabic ? 'المعلومات الأساسية' : 'Basic Info',
      isArabic ? 'المحتوى' : 'Curriculum',
      isArabic ? 'التسعير' : 'Pricing',
      isArabic ? 'الإعدادات' : 'Settings',
      isArabic ? 'المرفقات' : 'Attachments',
    ];

    steps.add(steps.removeAt(3));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(steps.length, (index) {
            final isActive = index == state.currentStep;
            final isCompleted = index < state.currentStep;

            return GestureDetector(
              onTap: () => context.read<CourseEditorCubit>().setStep(index),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : isCompleted
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.cardDark
                                  : AppColors.grey200),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    steps[index],
                    style: TextStyle(
                      color: isActive
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (index < steps.length - 1) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 30,
                      height: 2,
                      color: isCompleted
                          ? AppColors.success
                          : (isDark ? AppColors.borderDark : AppColors.grey300),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
