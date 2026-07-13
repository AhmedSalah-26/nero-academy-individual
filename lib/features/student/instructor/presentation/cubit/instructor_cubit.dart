import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/instructor/data/datasources/instructor_remote_data_source.dart';
import 'instructor_state.dart';

class InstructorCubit extends Cubit<InstructorState> {
  final InstructorRemoteDataSource remoteDataSource;

  InstructorCubit({required this.remoteDataSource})
      : super(const InstructorState());

  Future<void> loadInstructor(String teacherId) async {
    emit(state.copyWith(status: InstructorStatus.loading));

    try {
      AppLogger.i('🎓 [InstructorCubit] Loading instructor: $teacherId');

      final instructor = await remoteDataSource.getInstructor(teacherId);

      if (instructor == null) {
        AppLogger.w('🎓 [InstructorCubit] Instructor not found');
        emit(state.copyWith(
          status: InstructorStatus.error,
          errorMessage: 'Instructor not found',
        ));
        return;
      }

      final courses = await remoteDataSource.getInstructorCourses(teacherId);

      AppLogger.success(
          '🎓 [InstructorCubit] Loaded ${courses.length} courses');

      emit(state.copyWith(
        status: InstructorStatus.loaded,
        instructor: instructor,
        courses: courses,
      ));
    } catch (e, stack) {
      AppLogger.e('🎓 [InstructorCubit] Error loading instructor', e, stack);
      emit(state.copyWith(
        status: InstructorStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
