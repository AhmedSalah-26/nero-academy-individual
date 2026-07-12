import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/note_entity.dart';

/// Notes Tab Widget
class NotesTab extends StatelessWidget {
  final List<NoteEntity> notes;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onAddNote;
  final ValueChanged<NoteEntity> onEditNote;
  final ValueChanged<NoteEntity> onDeleteNote;
  final ValueChanged<NoteEntity> onJumpToTimestamp;

  const NotesTab({
    super.key,
    required this.notes,
    required this.isLoading,
    required this.isDark,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onJumpToTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState.section();
    }

    return Column(
      children: [
        // Add note button
        _buildAddNoteButton(),
        // Notes list
        Expanded(
          child: notes.isEmpty ? _buildEmptyState() : _buildNotesList(),
        ),
      ],
    );
  }

  Widget _buildAddNoteButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onAddNote,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'course_player.add_note'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      type: EmptyStateType.notes,
      title: 'course_player.no_notes'.tr(),
      message: 'course_player.no_notes_desc'.tr(),
      compact: true,
    );
  }

  Widget _buildNotesList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _NoteCard(
          note: notes[index],
          isDark: isDark,
          onEdit: () => onEditNote(notes[index]),
          onDelete: () => onDeleteNote(notes[index]),
          onJumpToTimestamp: () => onJumpToTimestamp(notes[index]),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteEntity note;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onJumpToTimestamp;

  const _NoteCard({
    required this.note,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onJumpToTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onJumpToTimestamp,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${'course_player.at'.tr()} ${note.formattedTimestamp}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Note content
          Text(
            note.content,
            style: TextStyle(
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
