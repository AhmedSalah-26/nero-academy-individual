// Course Player Feature - Barrel file

// ============ Domain ============
// Entities
export 'domain/entities/lesson_entity.dart';
export 'domain/entities/section_entity.dart';
export 'domain/entities/lesson_progress_entity.dart';
export 'domain/entities/note_entity.dart';
export 'domain/entities/bookmark_entity.dart';
export 'domain/entities/attachment_entity.dart';

// Repository
export 'domain/repositories/course_player_repository.dart';

// Use Cases
export 'domain/usecases/get_course_content_usecase.dart';
export 'domain/usecases/get_lesson_usecase.dart';
export 'domain/usecases/update_lesson_progress_usecase.dart';
export 'domain/usecases/mark_lesson_complete_usecase.dart';
export 'domain/usecases/get_notes_usecase.dart';
export 'domain/usecases/add_note_usecase.dart';
export 'domain/usecases/delete_note_usecase.dart';
export 'domain/usecases/get_bookmarks_usecase.dart';
export 'domain/usecases/add_bookmark_usecase.dart';
export 'domain/usecases/delete_bookmark_usecase.dart';

// ============ Data ============
// Models
export 'data/models/lesson_model.dart';
export 'data/models/section_model.dart';
export 'data/models/lesson_progress_model.dart';
export 'data/models/note_model.dart';
export 'data/models/bookmark_model.dart';
export 'data/models/attachment_model.dart';

// Data Sources
export 'data/datasources/course_player_remote_data_source.dart';
export 'data/datasources/course_player_local_data_source.dart';

// Repository Implementation
export 'data/repositories/course_player_repository_impl.dart';

// Services
export 'data/services/youtube_stream_service.dart';

// ============ Presentation ============
// Cubit
export 'presentation/cubit/course_player_cubit.dart';
export 'presentation/cubit/course_player_state.dart';
export 'presentation/cubit/notes_cubit.dart';
export 'presentation/cubit/notes_state.dart';

// Screens
export 'presentation/screens/course_player_screen.dart';

// Widgets
export 'presentation/widgets/course_player/video_player_section.dart';

export 'presentation/widgets/course_player/lesson_header.dart';
export 'presentation/widgets/course_player/content_tabs.dart';
export 'presentation/widgets/course_player/curriculum_list.dart';
export 'presentation/widgets/course_player/section_header.dart';
export 'presentation/widgets/course_player/lesson_item.dart';
export 'presentation/widgets/course_player/bottom_action_bar.dart';
export 'presentation/widgets/course_player/notes_tab.dart';
export 'presentation/widgets/course_player/bookmarks_tab.dart';
export 'presentation/widgets/course_player/qa_tab.dart';
