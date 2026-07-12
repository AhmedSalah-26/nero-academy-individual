import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';

/// Admin Forum State
enum AdminForumStatus { initial, loading, success, error }

class AdminForumState {
  final AdminForumStatus status;
  final List<Map<String, dynamic>> conversations;
  final List<Map<String, dynamic>> messages;
  final String? selectedConversationId;
  final String errorMessage;
  final int currentPage;
  final bool hasMore;
  final String? searchQuery;
  final String? typeFilter; // null=all, 'single'=private, 'multi'=group

  const AdminForumState({
    this.status = AdminForumStatus.initial,
    this.conversations = const [],
    this.messages = const [],
    this.selectedConversationId,
    this.errorMessage = '',
    this.currentPage = 1,
    this.hasMore = true,
    this.searchQuery,
    this.typeFilter,
  });

  AdminForumState copyWith({
    AdminForumStatus? status,
    List<Map<String, dynamic>>? conversations,
    List<Map<String, dynamic>>? messages,
    String? selectedConversationId,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
    String? typeFilter,
    bool clearSelectedConversation = false,
    bool clearTypeFilter = false,
  }) {
    return AdminForumState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      selectedConversationId: clearSelectedConversation
          ? null
          : (selectedConversationId ?? this.selectedConversationId),
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }
}

/// Admin Forum Cubit
class AdminForumCubit extends Cubit<AdminForumState> {
  final AdminRepository _repository;

  AdminForumCubit(this._repository) : super(const AdminForumState());

  /// Load conversations list
  Future<void> loadConversations({
    String? search,
    String? typeFilter,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminForumStatus.loading,
        conversations: [],
        messages: [],
        currentPage: 1,
        hasMore: true,
        clearSelectedConversation: true,
        searchQuery: search,
        typeFilter: typeFilter,
        clearTypeFilter: typeFilter == null,
      ));
    } else {
      emit(state.copyWith(
        status: AdminForumStatus.loading,
        clearSelectedConversation: true,
      ));
    }

    try {
      final conversations = await _repository.getConversations(
        search: search,
        typeFilter: typeFilter,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminForumStatus.success,
        conversations: conversations,
        currentPage: 1,
        hasMore: conversations.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminForumStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more conversations (pagination)
  Future<void> loadMoreConversations() async {
    if (!state.hasMore || state.selectedConversationId != null) return;
    final nextPage = state.currentPage + 1;

    try {
      final conversations = await _repository.getConversations(
        search: state.searchQuery,
        typeFilter: state.typeFilter,
        page: nextPage,
      );
      emit(state.copyWith(
        conversations: [...state.conversations, ...conversations],
        currentPage: nextPage,
        hasMore: conversations.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminForumStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Select conversation and load messages
  Future<void> selectConversationAndLoadMessages(String conversationId) async {
    emit(state.copyWith(
      status: AdminForumStatus.loading,
      selectedConversationId: conversationId,
      messages: [],
      currentPage: 1,
    ));

    try {
      final messages =
          await _repository.getMessages(conversationId: conversationId);
      emit(state.copyWith(
        status: AdminForumStatus.success,
        messages: messages,
        hasMore: messages.length >= 50,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminForumStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Search messages in current conversation
  Future<void> searchMessages(String? search) async {
    if (state.selectedConversationId == null) return;

    emit(state.copyWith(
      status: AdminForumStatus.loading,
      searchQuery: search,
      messages: [],
      currentPage: 1,
    ));

    try {
      final messages = await _repository.getMessages(
        conversationId: state.selectedConversationId!,
        search: search,
      );
      emit(state.copyWith(
        status: AdminForumStatus.success,
        messages: messages,
        hasMore: messages.length >= 50,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminForumStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (!state.hasMore || state.selectedConversationId == null) return;
    final nextPage = state.currentPage + 1;

    try {
      final messages = await _repository.getMessages(
        conversationId: state.selectedConversationId!,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        messages: [...state.messages, ...messages],
        currentPage: nextPage,
        hasMore: messages.length >= 50,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminForumStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _repository.deleteMessage(messageId);
      emit(state.copyWith(
        messages: state.messages.where((m) => m['id'] != messageId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminForumStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Set type filter and reload
  void setTypeFilter(String? typeFilter) {
    loadConversations(
      search: state.searchQuery,
      typeFilter: typeFilter,
      refresh: true,
    );
  }
}
