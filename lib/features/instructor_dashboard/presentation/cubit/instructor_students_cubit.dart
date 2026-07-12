import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_student_model.dart';

part 'instructor_students_state.dart';

/// Instructor Students Cubit
class InstructorStudentsCubit extends Cubit<InstructorStudentsState> {
  final InstructorRepository _repository;

  InstructorStudentsCubit(this._repository)
      : super(const InstructorStudentsState());

  /// Load students
  Future<void> loadStudents(
      {String? courseId, String? search, bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
          status: InstructorStudentsStatus.loading,
          students: [],
          currentPage: 1,
          hasMore: true));
    } else {
      emit(state.copyWith(status: InstructorStudentsStatus.loading));
    }

    try {
      final students = await _repository.getStudents(
          courseId: courseId, search: search, page: 1);
      emit(state.copyWith(
        status: InstructorStudentsStatus.success,
        students: students,
        currentCourseId: courseId,
        searchQuery: search,
        currentPage: 1,
        hasMore: students.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorStudentsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Load more students
  Future<void> loadMoreStudents() async {
    if (!state.hasMore ||
        state.status == InstructorStudentsStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: InstructorStudentsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final students = await _repository.getStudents(
        courseId: state.currentCourseId,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        status: InstructorStudentsStatus.success,
        students: [...state.students, ...students],
        currentPage: nextPage,
        hasMore: students.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorStudentsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Search students
  void search(String query) {
    loadStudents(
        courseId: state.currentCourseId,
        search: query.isEmpty ? null : query,
        refresh: true);
  }

  /// Filter by course
  void filterByCourse(String? courseId) {
    loadStudents(courseId: courseId, search: state.searchQuery, refresh: true);
  }

  /// Get student enrollments
  Future<List<StudentEnrollmentDetail>> getStudentEnrollments(
      String studentId) async {
    try {
      return await _repository.getStudentEnrollments(studentId);
    } catch (e) {
      return [];
    }
  }

  /// Get student progress
  Future<List<StudentCourseProgress>> getStudentProgress(
      String studentId) async {
    try {
      return await _repository.getStudentProgress(studentId);
    } catch (e) {
      return [];
    }
  }

  /// Send message to student
  Future<bool> sendMessageToStudent(
      String studentId, String subject, String message) async {
    try {
      return await _repository.sendMessageToStudent(
          studentId, subject, message);
    } catch (e) {
      return false;
    }
  }

  // ============ ENROLLMENT MANAGEMENT ============

  /// Extend enrollment access
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days) async {
    try {
      return await _repository.extendEnrollmentAccess(enrollmentId, days);
    } catch (e) {
      return false;
    }
  }

  /// Reset enrollment progress
  Future<bool> resetEnrollmentProgress(String enrollmentId) async {
    try {
      return await _repository.resetEnrollmentProgress(enrollmentId);
    } catch (e) {
      return false;
    }
  }

  /// Update enrollment status
  Future<bool> updateEnrollmentStatus(
      String enrollmentId, String status) async {
    try {
      return await _repository.updateEnrollmentStatus(enrollmentId, status);
    } catch (e) {
      return false;
    }
  }

  /// Mark enrollment as completed
  Future<bool> markAsCompleted(String enrollmentId) async {
    try {
      return await _repository.markAsCompleted(enrollmentId);
    } catch (e) {
      return false;
    }
  }

  /// Enroll student in a course
  Future<bool> enrollStudent(String studentId, String courseId) async {
    try {
      final result = await _repository.enrollStudent(studentId, courseId);
      if (result) {
        loadStudents(refresh: true);
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Unenroll student from a course
  Future<bool> unenrollStudent(String enrollmentId) async {
    try {
      return await _repository.unenrollStudent(enrollmentId);
    } catch (e) {
      return false;
    }
  }

  /// Get available courses for student enrollment
  Future<List<AvailableCourseForEnrollment>> getAvailableCoursesForStudent(
      String studentId) async {
    try {
      return await _repository.getAvailableCoursesForStudent(studentId);
    } catch (e) {
      return [];
    }
  }
}
