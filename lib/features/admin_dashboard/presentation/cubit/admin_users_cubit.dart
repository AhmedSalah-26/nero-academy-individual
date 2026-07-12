import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/models/admin_user_model.dart';

part 'admin_users_state.dart';

/// Admin Users Cubit
class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminRepository _repository;

  AdminUsersCubit(this._repository) : super(const AdminUsersState());

  /// Load users by role
  Future<void> loadUsers({
    UserRole role = UserRole.student,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminUsersStatus.loading,
        users: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: AdminUsersStatus.loading));
    }

    try {
      final users = await _repository.getUsers(
        role: role,
        search: search,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminUsersStatus.success,
        users: users,
        currentRole: role,
        searchQuery: search,
        currentPage: 1,
        hasMore: users.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more users (pagination)
  Future<void> loadMoreUsers() async {
    if (!state.hasMore || state.status == AdminUsersStatus.loadingMore) return;

    emit(state.copyWith(status: AdminUsersStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final users = await _repository.getUsers(
        role: state.currentRole,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        status: AdminUsersStatus.success,
        users: [...state.users, ...users],
        currentPage: nextPage,
        hasMore: users.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Ban user
  Future<void> banUser(
      String userId, BanDuration duration, String reason) async {
    emit(state.copyWith(actionStatus: AdminUsersStatus.loading));
    try {
      await _repository.banUser(userId, duration, reason);
      // Refresh the list
      await loadUsers(
          role: state.currentRole, search: state.searchQuery, refresh: true);
      emit(state.copyWith(actionStatus: AdminUsersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Unban user
  Future<void> unbanUser(String userId) async {
    emit(state.copyWith(actionStatus: AdminUsersStatus.loading));
    try {
      await _repository.unbanUser(userId);
      // Refresh the list
      await loadUsers(
          role: state.currentRole, search: state.searchQuery, refresh: true);
      emit(state.copyWith(actionStatus: AdminUsersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Update user
  Future<void> updateUser(AdminUserModel user) async {
    emit(state.copyWith(actionStatus: AdminUsersStatus.loading));
    try {
      await _repository.updateUser(
        user.id,
        UserUpdateDto(
          name: user.name,
          phone: user.phone,
          role: user.role,
          headlineAr: user.headlineAr,
          headlineEn: user.headlineEn,
          bioAr: user.bioAr,
          bioEn: user.bioEn,
          expertise: user.expertise,
          interests: user.interests,
          isActive: user.isActive,
          isVerifiedInstructor: user.isVerifiedInstructor,
        ),
      );
      // Refresh the list
      await loadUsers(
          role: state.currentRole, search: state.searchQuery, refresh: true);
      emit(state.copyWith(actionStatus: AdminUsersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete user (soft delete / deactivate)
  Future<void> deleteUser(String userId) async {
    emit(state.copyWith(actionStatus: AdminUsersStatus.loading));
    try {
      await _repository.deleteUser(userId);
      await loadUsers(
          role: state.currentRole, search: state.searchQuery, refresh: true);
      emit(state.copyWith(actionStatus: AdminUsersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Change user role
  Future<void> changeUserRole(String userId, String newRole) async {
    emit(state.copyWith(actionStatus: AdminUsersStatus.loading));
    try {
      await _repository.changeUserRole(userId, newRole);
      await loadUsers(
          role: state.currentRole, search: state.searchQuery, refresh: true);
      emit(state.copyWith(actionStatus: AdminUsersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Send notification to user
  Future<void> sendNotificationToUser({
    required String userId,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
  }) async {
    emit(state.copyWith(actionStatus: AdminUsersStatus.loading));
    try {
      await _repository.sendNotification(
        userId: userId,
        titleAr: titleAr,
        titleEn: titleEn,
        bodyAr: bodyAr,
        bodyEn: bodyEn,
      );
      emit(state.copyWith(actionStatus: AdminUsersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Broadcast notification to all users of a role
  Future<void> broadcastNotification({
    required String role,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
  }) async {
    emit(state.copyWith(actionStatus: AdminUsersStatus.loading));
    try {
      await _repository.broadcastNotification(
        role: role,
        titleAr: titleAr,
        titleEn: titleEn,
        bodyAr: bodyAr,
        bodyEn: bodyEn,
      );
      emit(state.copyWith(actionStatus: AdminUsersStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminUsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Change role tab
  void changeRole(UserRole role) {
    if (role != state.currentRole) {
      loadUsers(role: role, refresh: true);
    }
  }

  /// Search users
  void search(String query) {
    loadUsers(
        role: state.currentRole,
        search: query.isEmpty ? null : query,
        refresh: true);
  }
}
