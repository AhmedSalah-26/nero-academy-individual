import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/course_player/domain/usecases/get_notes_usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/usecases/add_note_usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/usecases/delete_note_usecase.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';
import 'notes_state.dart';

/// Notes Cubit
class NotesCubit extends Cubit<NotesState> {
  final GetNotesUseCase getNotesUseCase;
  final AddNoteUseCase addNoteUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;
  final CoursePlayerRepository repository;

  NotesCubit({
    required this.getNotesUseCase,
    required this.addNoteUseCase,
    required this.deleteNoteUseCase,
    required this.repository,
  }) : super(const NotesState());

  /// Load notes for a lesson
  Future<void> loadNotes({
    required String lessonId,
    required String userId,
  }) async {
    AppLogger.i('📝 [Notes] Loading notes for lesson: $lessonId');
    emit(state.copyWith(
      status: StateStatus.loading,
      lessonId: lessonId,
      userId: userId,
    ));

    final result = await getNotesUseCase(
      GetNotesParams(lessonId: lessonId, userId: userId),
    );

    result.fold(
      (failure) {
        AppLogger.e('[Notes] Failed to load: ${failure.message}');
        emit(state.copyWith(status: StateStatus.error, failure: failure));
      },
      (notes) {
        AppLogger.success('[Notes] Loaded ${notes.length} notes');
        emit(state.copyWith(status: StateStatus.success, notes: notes));
      },
    );
  }

  /// Add a new note
  Future<void> addNote({
    required String content,
    required int timestampSeconds,
  }) async {
    if (state.lessonId == null || state.userId == null) return;
    if (state.isAdding) return;

    AppLogger.i('📝 [Notes] Adding note');
    emit(state.copyWith(isAdding: true));

    final result = await addNoteUseCase(
      AddNoteParams(
        lessonId: state.lessonId!,
        userId: state.userId!,
        content: content,
        timestampSeconds: timestampSeconds,
      ),
    );

    result.fold(
      (failure) {
        AppLogger.e('[Notes] Failed to add: ${failure.message}');
        emit(state.copyWith(isAdding: false, addError: failure.message));
      },
      (note) {
        AppLogger.success('[Notes] Note added');
        final updatedNotes = [...state.notes, note];
        updatedNotes
            .sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));
        emit(state.copyWith(isAdding: false, notes: updatedNotes));
      },
    );
  }

  /// Update a note
  Future<void> updateNote({
    required String noteId,
    required String content,
  }) async {
    if (state.isUpdating) return;

    AppLogger.i('📝 [Notes] Updating note: $noteId');
    emit(state.copyWith(isUpdating: true, updatingNoteId: noteId));

    final result =
        await repository.updateNote(noteId: noteId, content: content);

    result.fold(
      (failure) {
        AppLogger.e('[Notes] Failed to update: ${failure.message}');
        emit(state.copyWith(isUpdating: false, updatingNoteId: null));
      },
      (updatedNote) {
        AppLogger.success('[Notes] Note updated');
        final updatedNotes = state.notes.map((n) {
          return n.id == noteId ? updatedNote : n;
        }).toList();
        emit(state.copyWith(
          isUpdating: false,
          updatingNoteId: null,
          notes: updatedNotes,
        ));
      },
    );
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    if (state.isDeleting) return;

    AppLogger.i('📝 [Notes] Deleting note: $noteId');
    emit(state.copyWith(isDeleting: true, deletingNoteId: noteId));

    final result = await deleteNoteUseCase(DeleteNoteParams(noteId: noteId));

    result.fold(
      (failure) {
        AppLogger.e('[Notes] Failed to delete: ${failure.message}');
        emit(state.copyWith(isDeleting: false, deletingNoteId: null));
      },
      (_) {
        AppLogger.success('[Notes] Note deleted');
        final updatedNotes = state.notes.where((n) => n.id != noteId).toList();
        emit(state.copyWith(
          isDeleting: false,
          deletingNoteId: null,
          notes: updatedNotes,
        ));
      },
    );
  }

  /// Clear add error
  void clearAddError() {
    emit(state.copyWith(clearAddError: true));
  }
}
