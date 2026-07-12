/// Settings Feature - Barrel Export
library settings;

// Domain
export 'domain/entities/settings_entity.dart';
export 'domain/entities/user_profile_entity.dart';
export 'domain/repositories/settings_repository.dart';
export 'domain/usecases/get_settings_usecase.dart';
export 'domain/usecases/update_settings_usecase.dart';
export 'domain/usecases/get_user_profile_usecase.dart';
export 'domain/usecases/update_user_profile_usecase.dart';

// Data
export 'data/models/settings_model.dart';
export 'data/models/user_profile_model.dart';
export 'data/datasources/settings_remote_data_source.dart';
export 'data/datasources/settings_local_data_source.dart';
export 'data/repositories/settings_repository_impl.dart';

// Presentation
export 'presentation/cubit/settings_cubit.dart';
export 'presentation/cubit/settings_state.dart';
export 'presentation/cubit/profile_cubit.dart';
export 'presentation/cubit/profile_state.dart';
export 'presentation/screens/settings_screen.dart';
export 'presentation/screens/profile_screen.dart';
export 'presentation/screens/help_support_screen.dart';

// Widgets - Help & Support
export 'presentation/widgets/help_support/help_search_bar.dart';
export 'presentation/widgets/help_support/help_topics_grid.dart';
export 'presentation/widgets/help_support/help_faq_section.dart';
export 'presentation/widgets/help_support/help_contact_section.dart';
