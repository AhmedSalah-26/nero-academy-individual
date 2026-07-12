/// Course Search Feature - Barrel File
library course_search;

// Data Layer
export 'data/datasources/course_search_local_data_source.dart';
export 'data/datasources/course_search_remote_data_source.dart';
export 'data/models/course_model.dart';
export 'data/models/search_filter_model.dart';
export 'data/repositories/course_search_repository_impl.dart';

// Domain Layer
export 'domain/entities/course_entity.dart';
export 'domain/entities/search_filter_entity.dart';
export 'domain/repositories/course_search_repository.dart';
export 'domain/usecases/search_courses_usecase.dart';
export 'domain/usecases/get_categories_usecase.dart';
export 'domain/usecases/get_recent_searches_usecase.dart';
export 'domain/usecases/save_recent_search_usecase.dart';

// Presentation Layer
export 'presentation/cubit/course_search_cubit.dart';
export 'presentation/cubit/course_search_state.dart';
export 'presentation/screens/course_search_screen.dart';
