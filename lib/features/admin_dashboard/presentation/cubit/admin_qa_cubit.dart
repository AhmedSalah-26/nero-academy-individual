import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';

/// Admin Q&A State
enum AdminQAStatus { initial, loading, success, error }

class AdminQAState {
  final AdminQAStatus status;
  final List<Map<String, dynamic>> questions;
  final String errorMessage;
  final int currentPage;
  final bool hasMore;
  final String? courseFilter;
  final bool? answeredFilter;
  final String? searchQuery;

  const AdminQAState({
    this.status = AdminQAStatus.initial,
    this.questions = const [],
    this.errorMessage = '',
    this.currentPage = 1,
    this.hasMore = true,
    this.courseFilter,
    this.answeredFilter,
    this.searchQuery,
  });

  AdminQAState copyWith({
    AdminQAStatus? status,
    List<Map<String, dynamic>>? questions,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    String? courseFilter,
    bool? answeredFilter,
    String? searchQuery,
  }) {
    return AdminQAState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      courseFilter: courseFilter ?? this.courseFilter,
      answeredFilter: answeredFilter ?? this.answeredFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Admin Q&A Cubit
class AdminQACubit extends Cubit<AdminQAState> {
  final AdminRepository _repository;

  AdminQACubit(this._repository) : super(const AdminQAState());

  Future<void> loadQuestions({
    String? courseId,
    bool? isAnswered,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminQAStatus.loading,
        questions: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: AdminQAStatus.loading));
    }

    try {
      final questions = await _repository.getAllQuestions(
        courseId: courseId,
        isAnswered: isAnswered,
        search: search,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminQAStatus.success,
        questions: questions,
        courseFilter: courseId,
        answeredFilter: isAnswered,
        searchQuery: search,
        currentPage: 1,
        hasMore: questions.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminQAStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore) return;
    final nextPage = state.currentPage + 1;

    try {
      final questions = await _repository.getAllQuestions(
        courseId: state.courseFilter,
        isAnswered: state.answeredFilter,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        questions: [...state.questions, ...questions],
        currentPage: nextPage,
        hasMore: questions.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminQAStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _repository.deleteQuestion(questionId);
      emit(state.copyWith(
        questions: state.questions.where((q) => q['id'] != questionId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminQAStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteAnswer(String answerId) async {
    try {
      await _repository.deleteAnswer(answerId);
      // Refresh to reflect the change
      await loadQuestions(
        courseId: state.courseFilter,
        isAnswered: state.answeredFilter,
        search: state.searchQuery,
        refresh: true,
      );
    } catch (e) {
      emit(state.copyWith(
        status: AdminQAStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> hideQuestion(String questionId) async {
    try {
      await _repository.hideQuestion(questionId);
      emit(state.copyWith(
        questions: state.questions.map((q) {
          if (q['id'] == questionId) {
            return {...q, 'is_hidden': true};
          }
          return q;
        }).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminQAStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> unhideQuestion(String questionId) async {
    try {
      await _repository.unhideQuestion(questionId);
      emit(state.copyWith(
        questions: state.questions.map((q) {
          if (q['id'] == questionId) {
            return {...q, 'is_hidden': false};
          }
          return q;
        }).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminQAStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
