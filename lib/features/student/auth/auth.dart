/// Auth Feature Exports
library auth;

// ============ Domain ============
export 'domain/entities/user_entity.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/logout_usecase.dart';
export 'domain/usecases/get_current_user_usecase.dart';
export 'domain/usecases/forgot_password_usecase.dart';
export 'domain/usecases/update_interests_usecase.dart';
export 'domain/usecases/login_with_google_usecase.dart';

// ============ Data ============
export 'data/models/user_model.dart';
export 'data/datasources/auth_remote_data_source.dart';
export 'data/datasources/auth_local_data_source.dart';
export 'data/repositories/auth_repository_impl.dart';

// ============ Presentation ============
export 'presentation/cubit/auth_cubit.dart';
export 'presentation/cubit/auth_state.dart';
export 'presentation/cubit/interests_cubit.dart';
export 'presentation/cubit/interests_state.dart';
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/forgot_password_screen.dart';
export 'presentation/screens/interests_selection_screen.dart';
