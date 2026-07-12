import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/student/direct_chat/domain/entities/direct_message_entity.dart';

class DirectChatState extends Equatable {
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final List<DirectMessage> messages;
  final int updateTimestamp;

  const DirectChatState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.messages = const [],
    this.updateTimestamp = 0,
  });

  bool get isEmpty => messages.isEmpty && !isLoading;

  DirectChatState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    List<DirectMessage>? messages,
    bool forceUpdate = false,
  }) {
    return DirectChatState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      messages: messages ?? this.messages,
      updateTimestamp: forceUpdate || messages != null
          ? DateTime.now().millisecondsSinceEpoch
          : updateTimestamp,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isError, errorMessage, messages, updateTimestamp];
}
