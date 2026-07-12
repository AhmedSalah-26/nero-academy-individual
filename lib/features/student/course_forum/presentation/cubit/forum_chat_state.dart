import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';

class ForumChatState extends Equatable {
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final List<ConversationMessage> messages;
  final int updateTimestamp;

  const ForumChatState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.messages = const [],
    this.updateTimestamp = 0,
  });

  bool get isEmpty => messages.isEmpty && !isLoading;

  ForumChatState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    List<ConversationMessage>? messages,
    bool forceUpdate = false,
  }) {
    return ForumChatState(
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
