/// Quizzes Feature - Barrel Export
library quizzes;

// Data Layer
export 'data/datasources/quizzes_remote_data_source.dart';
export 'data/datasources/quizzes_local_data_source.dart';
export 'data/models/quiz_model.dart';
export 'data/models/quiz_question_model.dart';
export 'data/models/quiz_attempt_model.dart';
export 'data/repositories/quizzes_repository_impl.dart';

// Domain Layer
export 'domain/entities/quiz_entity.dart';
export 'domain/entities/quiz_question_entity.dart';
export 'domain/entities/quiz_attempt_entity.dart';
export 'domain/repositories/quizzes_repository.dart';
export 'domain/usecases/get_quiz_usecase.dart';
export 'domain/usecases/get_quiz_questions_usecase.dart';
export 'domain/usecases/start_quiz_attempt_usecase.dart';
export 'domain/usecases/submit_quiz_usecase.dart';
export 'domain/usecases/get_quiz_attempts_usecase.dart';

// Presentation Layer
export 'presentation/cubit/quiz_cubit.dart';
export 'presentation/cubit/quiz_state.dart';
export 'presentation/screens/quiz_info_screen.dart';
export 'presentation/screens/quiz_question_screen.dart';
export 'presentation/screens/quiz_results_screen.dart';
