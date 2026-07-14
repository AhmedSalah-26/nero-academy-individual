import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lms_platform/features/admin_dashboard/data/datasources/admin_teacher_subscriptions_data_source.dart';
import 'package:lms_platform/features/admin_dashboard/data/models/admin_teacher_subscription_model.dart';

part 'admin_teacher_subscriptions_state.dart';

class AdminTeacherSubscriptionsCubit
    extends Cubit<AdminTeacherSubscriptionsState> {
  final AdminTeacherSubscriptionsDataSource _dataSource;

  AdminTeacherSubscriptionsCubit(this._dataSource)
      : super(const AdminTeacherSubscriptionsState());

  Future<void> loadTeachers({String? search, bool refresh = false}) async {
    emit(state.copyWith(
      status: AdminTeacherSubscriptionsStatus.loading,
      teachers: refresh ? [] : state.teachers,
      searchQuery: search,
      currentPage: 1,
      hasMore: true,
    ));

    try {
      final teachers = await _dataSource.getTeachers(search: search);
      emit(state.copyWith(
        status: AdminTeacherSubscriptionsStatus.success,
        teachers: teachers,
        selectedTeacherId: state.selectedTeacherId ??
            (teachers.isEmpty ? null : teachers.first.teacherId),
        currentPage: 1,
        hasMore: teachers.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminTeacherSubscriptionsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadMoreTeachers() async {
    if (!state.hasMore ||
        state.status == AdminTeacherSubscriptionsStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: AdminTeacherSubscriptionsStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final teachers = await _dataSource.getTeachers(
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        status: AdminTeacherSubscriptionsStatus.success,
        teachers: [...state.teachers, ...teachers],
        currentPage: nextPage,
        hasMore: teachers.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminTeacherSubscriptionsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectTeacher(String teacherId) {
    emit(state.copyWith(selectedTeacherId: teacherId));
  }

  Future<void> createSubscription(TeacherSubscriptionUpsertDto dto) async {
    await _runAction(() => _dataSource.createSubscription(dto));
  }

  Future<void> extendSubscription({
    required TeacherSubscriptionModel subscription,
    required int days,
    String? notes,
  }) async {
    await _runAction(
      () => _dataSource.extendSubscription(
        subscription: subscription,
        days: days,
        notes: notes,
      ),
    );
  }

  Future<void> cancelSubscription(String subscriptionId,
      {String? notes}) async {
    await _runAction(
      () => _dataSource.cancelSubscription(subscriptionId, notes: notes),
    );
  }

  Future<void> reactivateSubscription(String subscriptionId) async {
    await _runAction(() => _dataSource.reactivateSubscription(subscriptionId));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    emit(state.copyWith(actionStatus: AdminTeacherSubscriptionsStatus.loading));
    try {
      await action();
      await loadTeachers(search: state.searchQuery, refresh: true);
      emit(state.copyWith(
        actionStatus: AdminTeacherSubscriptionsStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminTeacherSubscriptionsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
