/// Admin Dashboard Feature
///
/// Provides admin dashboard functionality for platform management.
library admin_dashboard;

// Data Layer
export 'data/datasources/admin_data_sources.dart';
export 'data/models/admin_models.dart';
export 'data/repositories/admin_repository_impl.dart';

// Domain Layer
export 'domain/entities/admin_entities.dart';
export 'domain/repositories/admin_repository.dart';

// Presentation Layer
export 'presentation/cubit/admin_cubits.dart';
export 'presentation/screens/admin_dashboard_screen.dart';
export 'presentation/screens/user_details_screen.dart';
export 'presentation/screens/ban_user_screen.dart';
export 'presentation/screens/category_editor_screen.dart';
export 'presentation/screens/coupon_editor_screen.dart';
export 'presentation/screens/course_details_screen.dart';
export 'presentation/screens/course_enrollments_screen.dart';
export 'presentation/screens/coupon_usage_screen.dart';
