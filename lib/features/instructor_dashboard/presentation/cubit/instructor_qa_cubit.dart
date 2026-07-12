import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_question_model.dart';

part 'instructor_qa_state.dart';

/// Instructor Q&A Cubit
class InstructorQACubit extends Cubit<InstructorQAState> {
  final InstructorRepository _repository;

  InstructorQACubit(this._repository) : super(const InstructorQAState());

  /// Load questions
  Future<void> loadQuestions(
      {QAStatus? status, String? courseId, bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
          status: InstructorQAStatus.loading,
          questions: [],
          currentPage: 1,
          hasMore: true));
    } else {
      emit(state.copyWith(status: InstructorQAStatus.loading));
    }

    try {
      final questions = await _repository.getQuestions(
          status: status, courseId: courseId, page: 1);
      emit(state.copyWith(
        status: InstructorQAStatus.success,
        questions: questions,
        currentStatus: status ?? QAStatus.all,
        currentCourseId: courseId,
        currentPage: 1,
        hasMore: questions.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorQAStatus.error, errorMessage: e.toString()));
    }
  }

  /// Load more questions
  Future<void> loadMoreQuestions() async {
    if (!state.hasMore || state.status == InstructorQAStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: InstructorQAStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final questions = await _repository.getQuestions(
        status: state.currentStatus,
        courseId: state.currentCourseId,
        page: nextPage,
      );
      emit(state.copyWith(
        status: InstructorQAStatus.success,
        questions: [...state.questions, ...questions],
        currentPage: nextPage,
        hasMore: questions.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorQAStatus.error, errorMessage: e.toString()));
    }
  }

  /// Answer question
  Future<void> answerQuestion(String questionId, String answer) async {
    emit(state.copyWith(actionStatus: InstructorQAStatus.loading));
    try {
      await _repository.answerQuestion(questionId, answer);
      await loadQuestions(
          status: state.currentStatus,
          courseId: state.currentCourseId,
          refresh: true);
      emit(state.copyWith(actionStatus: InstructorQAStatus.success));
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorQAStatus.error, errorMessage: e.toString()));
    }
  }

  /// Change status filter
  void changeStatus(QAStatus status) {
    if (status != state.currentStatus) {
      loadQuestions(
          status: status, courseId: state.currentCourseId, refresh: true);
    }
  }

  /// Filter by course
  void filterByCourse(String? courseId) {
    loadQuestions(
        status: state.currentStatus, courseId: courseId, refresh: true);
  }

  /// Update answer
  Future<void> updateAnswer(String answerId, String newContent) async {
    emit(state.copyWith(actionStatus: InstructorQAStatus.loading));
    try {
      await _repository.updateAnswer(answerId, newContent);
      await loadQuestions(
          status: state.currentStatus,
          courseId: state.currentCourseId,
          refresh: true);
      emit(state.copyWith(actionStatus: InstructorQAStatus.success));
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorQAStatus.error, errorMessage: e.toString()));
    }
  }

  /// Delete answer
  Future<void> deleteAnswer(String answerId) async {
    emit(state.copyWith(actionStatus: InstructorQAStatus.loading));
    try {
      await _repository.deleteAnswer(answerId);
      await loadQuestions(
          status: state.currentStatus,
          courseId: state.currentCourseId,
          refresh: true);
      emit(state.copyWith(actionStatus: InstructorQAStatus.success));
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorQAStatus.error, errorMessage: e.toString()));
    }
  }

  /// Hide question
  Future<void> hideQuestion(String questionId) async {
    emit(state.copyWith(actionStatus: InstructorQAStatus.loading));
    try {
      await _repository.hideQuestion(questionId);
      await loadQuestions(
          status: state.currentStatus,
          courseId: state.currentCourseId,
          refresh: true);
      emit(state.copyWith(actionStatus: InstructorQAStatus.success));
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorQAStatus.error, errorMessage: e.toString()));
    }
  }

  /// Pin question
  Future<void> pinQuestion(String questionId, bool isPinned) async {
    emit(state.copyWith(actionStatus: InstructorQAStatus.loading));
    try {
      await _repository.pinQuestion(questionId, isPinned);
      await loadQuestions(
          status: state.currentStatus,
          courseId: state.currentCourseId,
          refresh: true);
      emit(state.copyWith(actionStatus: InstructorQAStatus.success));
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorQAStatus.error, errorMessage: e.toString()));
    }
  }
}
