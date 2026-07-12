// Course Details Feature - Barrel file
// Domain
export 'domain/entities/course_details_entity.dart';
export 'domain/entities/instructor_entity.dart';
export 'domain/entities/section_entity.dart';
export 'domain/entities/lesson_entity.dart';
export 'domain/entities/review_entity.dart';
export 'domain/repositories/course_details_repository.dart';
export 'domain/usecases/get_course_details_usecase.dart';
export 'domain/usecases/get_course_reviews_usecase.dart';
export 'domain/usecases/toggle_wishlist_usecase.dart';

// Data
export 'data/models/course_details_model.dart';
export 'data/models/instructor_model.dart';
export 'data/models/section_model.dart';
export 'data/models/lesson_model.dart';
export 'data/models/review_model.dart';
export 'data/datasources/course_details_remote_data_source.dart';
export 'data/datasources/course_details_local_data_source.dart';
export 'data/repositories/course_details_repository_impl.dart';

// Presentation
export 'presentation/cubit/course_details_cubit.dart';
export 'presentation/cubit/course_details_state.dart';
export 'presentation/screens/course_details_screen.dart';
export 'presentation/widgets/course_details/course_hero_section.dart';
export 'presentation/widgets/course_details/course_info_section.dart';
export 'presentation/widgets/course_details/instructor_card.dart';
export 'presentation/widgets/course_details/course_stats_grid.dart';
export 'presentation/widgets/course_details/what_you_learn_section.dart';
export 'presentation/widgets/course_details/curriculum_section.dart';
export 'presentation/widgets/course_details/reviews_section.dart';
export 'presentation/widgets/course_details/bottom_price_bar.dart';
