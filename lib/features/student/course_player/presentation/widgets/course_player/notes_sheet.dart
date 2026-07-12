import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/note_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/repositories/course_player_repository.dart';

/// Notes Bottom Sheet Widget
class NotesSheet extends StatelessWidget {
  final bool isDark;
  final String lessonId;
  final String enrollmentId;
  final int currentPosition;
  final CoursePlayerRepository repository;
  final VoidCallback onRefresh;

  const NotesSheet({
    super.key,
    required this.isDark,
    required this.lessonId,
    required this.enrollmentId,
    required this.currentPosition,
    required this.repository,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NoteEntity>>(
      future: _loadNotes(),
      builder: (context, snapshot) {
        return Column(
          children: [
            _buildHandle(),
            _buildHeader(context),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(context, snapshot),
            ),
            _buildAddButton(context),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<List<NoteEntity>> _loadNotes() async {
    AppLogger.i('📝 [NotesSheet] Loading notes...');
    final result = await repository.getNotesByEnrollment(
      lessonId: lessonId,
      enrollmentId: enrollmentId,
    );
    return result.fold(
      (failure) {
        AppLogger.e('[NotesSheet] Failed: ${failure.message}');
        return [];
      },
      (notes) {
        AppLogger.success('[NotesSheet] Loaded ${notes.length} notes');
        return notes;
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey600 : AppColors.grey300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'course_player.notes'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.add),
        label: Text('course_player.add_note'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<NoteEntity>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const AppLoadingState.section();
    }

    final notes = snapshot.data ?? [];
    if (notes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notes.length,
      itemBuilder: (_, index) => _buildNoteItem(context, notes[index]),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        type: EmptyStateType.notes,
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, NoteEntity note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      note.formattedTimestamp,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _deleteNote(context, note.id),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            style: TextStyle(
              color: isDark ? AppColors.white : AppColors.textMainLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context, String noteId) async {
    AppLogger.i('📝 [NotesSheet] Deleting note: $noteId');
    final result = await repository.deleteNote(noteId: noteId);
    result.fold(
      (failure) =>
          AppLogger.e('[NotesSheet] Failed to delete: ${failure.message}'),
      (_) {
        AppLogger.success('[NotesSheet] Note deleted');
        Navigator.of(context).pop();
        onRefresh();
      },
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveDialog(
        title: Text('course_player.add_note'.tr()),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'course_player.note_hint'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                AppLogger.i('📝 [NotesSheet] Saving note...');
                final result = await repository.addNoteByEnrollment(
                  lessonId: lessonId,
                  enrollmentId: enrollmentId,
                  content: controller.text,
                  timestampSeconds: currentPosition,
                );
                result.fold(
                  (failure) =>
                      AppLogger.e('[NotesSheet] Failed: ${failure.message}'),
                  (_) {
                    AppLogger.success('[NotesSheet] Note saved');
                    Navigator.pop(ctx);
                    onRefresh();
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }
}
