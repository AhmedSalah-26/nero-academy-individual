import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/note_entity.dart';

/// Notes State
class NotesState extends Equatable {
  final StateStatus status;
  final Failure? failure;
  final String? lessonId;
  final String? userId;
  final List<NoteEntity> notes;
  final bool isAdding;
  final bool isUpdating;
  final bool isDeleting;
  final String? updatingNoteId;
  final String? deletingNoteId;
  final String? addError;

  const NotesState({
    this.status = StateStatus.initial,
    this.failure,
    this.lessonId,
    this.userId,
    this.notes = const [],
    this.isAdding = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.updatingNoteId,
    this.deletingNoteId,
    this.addError,
  });

  bool get isLoading => status == StateStatus.loading;
  bool get isError => status == StateStatus.error;
  bool get isSuccess => status == StateStatus.success;
  bool get isEmpty => notes.isEmpty;
  String? get errorMessage => failure?.message;

  NotesState copyWith({
    StateStatus? status,
    Failure? failure,
    String? lessonId,
    String? userId,
    List<NoteEntity>? notes,
    bool? isAdding,
    bool? isUpdating,
    bool? isDeleting,
    String? updatingNoteId,
    String? deletingNoteId,
    String? addError,
    bool clearAddError = false,
  }) {
    return NotesState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      lessonId: lessonId ?? this.lessonId,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      isAdding: isAdding ?? this.isAdding,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      updatingNoteId: updatingNoteId ?? this.updatingNoteId,
      deletingNoteId: deletingNoteId ?? this.deletingNoteId,
      addError: clearAddError ? null : (addError ?? this.addError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        failure,
        lessonId,
        userId,
        notes,
        isAdding,
        isUpdating,
        isDeleting,
        updatingNoteId,
        deletingNoteId,
        addError,
      ];
}
