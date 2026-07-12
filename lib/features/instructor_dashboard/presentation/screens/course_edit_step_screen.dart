import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/basic_info_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/curriculum_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/pricing_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/settings_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/attachments_step.dart';

class CourseEditStepScreen extends StatefulWidget {
  final int stepIndex;

  const CourseEditStepScreen({
    super.key,
    required this.stepIndex,
  });

  @override
  State<CourseEditStepScreen> createState() => _CourseEditStepScreenState();
}

class _CourseEditStepScreenState extends State<CourseEditStepScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure cubit step matches our editing step so that inner widgets behave correctly
    Future.microtask(() {
      if (mounted) {
        context.read<CourseEditorCubit>().setStep(widget.stepIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    String title = '';
    Widget body = const SizedBox.shrink();

    switch (widget.stepIndex) {
      case 0:
        title = isArabic ? 'تعديل المعلومات' : 'Edit Basic Info';
        body = const BasicInfoStep();
        break;
      case 1:
        title = isArabic ? 'تعديل المحتوى' : 'Edit Curriculum';
        body = const CurriculumStep();
        break;
      case 2:
        title = isArabic ? 'تعديل التسعير' : 'Edit Pricing';
        body = const PricingStep();
        break;
      case 3:
        title = isArabic ? 'تعديل الإعدادات' : 'Edit Settings';
        body = const SettingsStep();
        break;
      case 4:
        title = isArabic ? 'تعديل المرفقات' : 'Edit Attachments';
        body = const AttachmentsStep();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _saveCurrentStep(context, isArabic, widget.stepIndex),
              icon: const Icon(Icons.save),
              label: Text(
                isArabic ? 'حفظ التعديلات' : 'Save Changes',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<CourseEditorCubit, CourseEditorState>(
        builder: (context, state) {
          if (state.isLoading &&
              state.sections.isEmpty &&
              state.titleAr.isEmpty) {
            return const AppLoadingState();
          }
          return body;
        },
      ),
    );
  }

  Future<void> _saveCurrentStep(
      BuildContext context, bool isArabic, int stepIndex) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isArabic ? 'جاري الحفظ...' : 'Saving...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final cubit = context.read<CourseEditorCubit>();
    bool success = false;

    switch (stepIndex) {
      case 0:
        success = await cubit.saveBasicInfoOnly();
        break;
      case 1:
        success = await cubit.saveCurriculumOnly();
        break;
      case 2:
        success = await cubit.savePricingOnly();
        break;
      case 3:
        success = await cubit.saveSettingsOnly();
        break;
      case 4:
        success = await cubit.saveAttachmentsOnly();
        break;
    }

    if (!context.mounted) return;

    Navigator.pop(context); // Close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (isArabic
                ? 'تم حفظ التعديلات بنجاح'
                : 'Changes saved successfully')
            : (isArabic ? 'فشل في الحفظ' : 'Failed to save changes')),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
    if (success) {
      Navigator.pop(context); // Go back to the edit menu screen
    }
  }
}
