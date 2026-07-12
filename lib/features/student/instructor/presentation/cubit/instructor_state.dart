import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/student/instructor/domain/entities/instructor_entity.dart';
import 'package:lms_platform/features/student/instructor/domain/entities/instructor_course_entity.dart';

enum InstructorStatus { initial, loading, loaded, error }

class InstructorState extends Equatable {
  final InstructorStatus status;
  final InstructorEntity? instructor;
  final List<InstructorCourseEntity> courses;
  final String? errorMessage;

  const InstructorState({
    this.status = InstructorStatus.initial,
    this.instructor,
    this.courses = const [],
    this.errorMessage,
  });

  bool get isLoading => status == InstructorStatus.loading;
  bool get isLoaded => status == InstructorStatus.loaded;
  bool get isError => status == InstructorStatus.error;

  InstructorState copyWith({
    InstructorStatus? status,
    InstructorEntity? instructor,
    List<InstructorCourseEntity>? courses,
    String? errorMessage,
  }) {
    return InstructorState(
      status: status ?? this.status,
      instructor: instructor ?? this.instructor,
      courses: courses ?? this.courses,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, instructor, courses, errorMessage];
}
