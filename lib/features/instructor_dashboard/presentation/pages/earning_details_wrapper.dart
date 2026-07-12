import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_earning_model.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_course_model.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_courses_cubit.dart';
import 'earning_details_screen.dart';

/// Wrapper that fetches course data before showing details
class EarningDetailsWrapper extends StatefulWidget {
  final EarningsTransactionModel earning;

  const EarningDetailsWrapper({
    super.key,
    required this.earning,
  });

  @override
  State<EarningDetailsWrapper> createState() => _EarningDetailsWrapperState();
}

class _EarningDetailsWrapperState extends State<EarningDetailsWrapper> {
  InstructorCourseModel? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    if (widget.earning.courseId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final coursesCubit = context.read<InstructorCoursesCubit>();

      // Check if course is already in the state
      final existingCourse = coursesCubit.state.courses.firstWhere(
        (c) => c.id == widget.earning.courseId,
        orElse: () => throw Exception('Course not found'),
      );

      setState(() {
        _course = existingCourse;
        _isLoading = false;
      });
    } catch (e) {
      // Course not in state, just show without course data
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return EarningDetailsScreen(
      earning: widget.earning,
      course: _course,
    );
  }
}
