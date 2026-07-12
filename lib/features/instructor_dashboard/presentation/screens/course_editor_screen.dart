// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/attachments_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/basic_info_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/course_edit_menu.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/course_editor_dialogs.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/curriculum_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/pricing_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/settings_step.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/course_editor/stepper_header.dart';

/// Course Editor Screen
class CourseEditorScreen extends StatefulWidget {
  final String? courseId;

  const CourseEditorScreen({super.key, this.courseId});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.i(
        '📝 [CourseEditorScreen] initState - courseId: ${widget.courseId}');
    final cubit = context.read<CourseEditorCubit>();
    if (widget.courseId != null) {
      AppLogger.i('📝 [CourseEditorScreen] Editing existing course');
      cubit.initEditCourse(widget.courseId!);
    } else {
      AppLogger.i('📝 [CourseEditorScreen] Creating new course');
      cubit.initNewCourse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.courseId != null
                  ? 'dashboard.instructor.edit_course'.tr()
                  : 'dashboard.instructor.create_course'.tr(),
              style: const TextStyle(fontSize: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            actions: _buildAppBarActions(context, state),
          ),
          body: state.isLoading && state.currentStep == 0
              ? const Center(child: CircularProgressIndicator())
              : widget.courseId != null
                  ? CourseEditMenu(
                      state: state,
                      isDark: isDark,
                    )
                  : Column(
                      children: [
                        CourseEditorStepperHeader(
                          state: state,
                          isDark: isDark,
                        ),
                        Expanded(
                          child: _buildStepContent(state),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    CourseEditorState state,
  ) {
    if (MediaQuery.of(context).size.width > 600) {
      return [
        TextButton(
          onPressed:
              state.isLoading ? null : () => showSaveDraftDialog(context),
          child: Text('course_editor.save_draft'.tr()),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: state.isLoading ? null : () => showPublishDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: Text('course_editor.publish'.tr()),
        ),
        const SizedBox(width: 16),
      ];
    }

    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'draft') {
            showSaveDraftDialog(context);
          } else if (value == 'publish') {
            showPublishDialog(context);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'draft',
            enabled: !state.isLoading,
            child: Row(
              children: [
                const Icon(Icons.save_outlined, size: 20),
                const SizedBox(width: 12),
                Text('course_editor.save_draft'.tr()),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'publish',
            enabled: !state.isLoading,
            child: Row(
              children: [
                const Icon(Icons.publish, size: 20),
                const SizedBox(width: 12),
                Text('course_editor.publish'.tr()),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildStepContent(CourseEditorState state) {
    switch (state.currentStep) {
      case 0:
        return const BasicInfoStep();
      case 1:
        return const CurriculumStep();
      case 2:
        return const PricingStep();
      case 3:
        return const AttachmentsStep();
      case 4:
        return const SettingsStep();
      default:
        return const BasicInfoStep();
    }
  }
}
