import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/network_info.dart';
import '../services/lesson_history_service.dart';
import '../services/supabase_service.dart';
import '../services/video_player_notifier_service.dart';
// Auth Feature
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/login_with_google_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/send_phone_otp_usecase.dart';
import '../../features/auth/domain/usecases/update_interests_usecase.dart';
import '../../features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/interests_cubit.dart';
// Home Feature
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_banners_usecase.dart';
import '../../features/home/domain/usecases/get_categories_usecase.dart';
import '../../features/home/domain/usecases/get_featured_courses_usecase.dart';
import '../../features/home/domain/usecases/get_flash_sale_courses_usecase.dart';
import '../../features/home/domain/usecases/get_new_courses_usecase.dart';
import '../../features/home/domain/usecases/get_popular_courses_usecase.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
// Course Search Feature
import '../../features/course_search/data/datasources/course_search_local_data_source.dart';
import '../../features/course_search/data/datasources/course_search_remote_data_source.dart';
import '../../features/course_search/data/repositories/course_search_repository_impl.dart';
import '../../features/course_search/domain/repositories/course_search_repository.dart';
import '../../features/course_search/domain/usecases/get_categories_usecase.dart'
    as search;
import '../../features/course_search/domain/usecases/get_recent_searches_usecase.dart';
import '../../features/course_search/domain/usecases/save_recent_search_usecase.dart';
import '../../features/course_search/domain/usecases/search_courses_usecase.dart';
import '../../features/course_search/presentation/cubit/course_search_cubit.dart';
// Course Details Feature
import '../../features/course_details/data/datasources/course_details_remote_data_source.dart';
import '../../features/course_details/data/datasources/course_details_local_data_source.dart';
import '../../features/course_details/data/repositories/course_details_repository_impl.dart';
import '../../features/course_details/domain/repositories/course_details_repository.dart';
import '../../features/course_details/domain/usecases/get_course_details_usecase.dart';
import '../../features/course_details/domain/usecases/get_course_reviews_usecase.dart';
import '../../features/course_details/domain/usecases/enroll_free_course_usecase.dart';
import '../../features/course_details/presentation/cubit/course_details_cubit.dart';
// Cart Feature
import '../../features/cart/data/datasources/cart_remote_data_source.dart';
import '../../features/cart/data/datasources/cart_local_data_source.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/get_cart_usecase.dart';
import '../../features/cart/domain/usecases/add_to_cart_usecase.dart';
import '../../features/cart/domain/usecases/remove_from_cart_usecase.dart';
import '../../features/cart/domain/usecases/apply_coupon_usecase.dart';
import '../../features/cart/domain/usecases/remove_coupon_usecase.dart';
import '../../features/cart/domain/usecases/checkout_usecase.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/cart/presentation/cubit/checkout_cubit.dart';
// My Learning Feature
import '../../features/my_learning/data/datasources/my_learning_remote_data_source.dart';
import '../../features/my_learning/data/datasources/my_learning_local_data_source.dart';
import '../../features/my_learning/data/repositories/my_learning_repository_impl.dart';
import '../../features/my_learning/domain/repositories/my_learning_repository.dart';
import '../../features/my_learning/domain/usecases/get_enrollments_usecase.dart';
import '../../features/my_learning/domain/usecases/get_continue_learning_usecase.dart';
import '../../features/my_learning/presentation/cubit/my_learning_cubit.dart';
// Course Player Feature
import '../../features/course_player/data/datasources/course_player_remote_data_source.dart';
import '../../features/course_player/data/datasources/course_player_local_data_source.dart';
import '../../features/course_player/data/repositories/course_player_repository_impl.dart';
import '../../features/course_player/domain/repositories/course_player_repository.dart';
import '../../features/course_player/domain/usecases/get_course_content_usecase.dart';
import '../../features/course_player/domain/usecases/get_lesson_usecase.dart';
import '../../features/course_player/domain/usecases/update_lesson_progress_usecase.dart';
import '../../features/course_player/domain/usecases/mark_lesson_complete_usecase.dart';
import '../../features/course_player/domain/usecases/get_notes_usecase.dart';
import '../../features/course_player/domain/usecases/add_note_usecase.dart';
import '../../features/course_player/domain/usecases/delete_note_usecase.dart';
import '../../features/course_player/domain/usecases/get_bookmarks_usecase.dart';
import '../../features/course_player/domain/usecases/add_bookmark_usecase.dart';
import '../../features/course_player/domain/usecases/delete_bookmark_usecase.dart';
import '../../features/course_player/presentation/cubit/course_player_cubit.dart';
import '../../features/course_player/presentation/cubit/notes_cubit.dart';
// Quizzes Feature
import '../../features/quizzes/data/datasources/quizzes_remote_data_source.dart';
import '../../features/quizzes/data/datasources/quizzes_local_data_source.dart';
import '../../features/quizzes/data/repositories/quizzes_repository_impl.dart';
import '../../features/quizzes/domain/repositories/quizzes_repository.dart';
import '../../features/quizzes/domain/usecases/get_quiz_usecase.dart';
import '../../features/quizzes/domain/usecases/get_quiz_questions_usecase.dart';
import '../../features/quizzes/domain/usecases/get_quiz_attempts_usecase.dart';
import '../../features/quizzes/domain/usecases/start_quiz_attempt_usecase.dart';
import '../../features/quizzes/domain/usecases/submit_quiz_usecase.dart';
import '../../features/quizzes/presentation/cubit/quiz_cubit.dart';

// Wishlist Feature
import '../../features/wishlist/data/datasources/wishlist_remote_data_source.dart';
import '../../features/wishlist/data/datasources/wishlist_local_data_source.dart';
import '../../features/wishlist/data/repositories/wishlist_repository_impl.dart';
import '../../features/wishlist/domain/repositories/wishlist_repository.dart';
import '../../features/wishlist/domain/usecases/get_wishlist_usecase.dart';
import '../../features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import '../../features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import '../../features/wishlist/domain/usecases/toggle_wishlist_usecase.dart'
    as wishlist;
import '../../features/wishlist/presentation/cubit/wishlist_cubit.dart';

// Settings Feature
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/cubit/profile_cubit.dart';
// Admin Dashboard Feature
import '../../features/admin_dashboard/data/datasources/admin_courses_data_source.dart';
import '../../features/admin_dashboard/data/datasources/admin_stats_data_source.dart';
import '../../features/admin_dashboard/data/datasources/admin_users_data_source.dart';
import '../../features/admin_dashboard/data/repositories/admin_repository_impl.dart';
import '../../features/admin_dashboard/domain/repositories/admin_repository.dart';
import '../../features/admin_dashboard/presentation/cubit/admin_cubits.dart';
// Instructor Dashboard Feature
import '../../features/instructor_dashboard/data/datasources/instructor_data_sources.dart';
import '../../features/instructor_dashboard/data/repositories/instructor_repository_impl.dart';
import '../../features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import '../../features/instructor_dashboard/presentation/cubit/instructor_cubits.dart';
// Notifications Feature
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
// Payments History Feature
import '../../features/payments_history/data/datasources/payments_remote_data_source.dart';
import '../../features/payments_history/data/repositories/payments_repository_impl.dart';
import '../../features/payments_history/domain/repositories/payments_repository.dart';
import '../../features/payments_history/domain/usecases/get_user_payments_usecase.dart';
import '../../features/payments_history/presentation/cubit/payments_history_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ============ External ============
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Connectivity());

  // Register Supabase client - use SupabaseServiceImpl to handle initialization
  sl.registerLazySingleton(() => SupabaseServiceImpl.instance.client);

  // ============ Core ============
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => LessonHistoryService(sl()));
  sl.registerLazySingleton(() => VideoPlayerNotifierService());

  // ============ Auth Feature ============
  _initAuth();

  // ============ Home Feature ============
  _initHome();

  // ============ Course Search Feature ============
  _initCourseSearch();

  // ============ Course Details Feature ============
  _initCourseDetails();

  // ============ Cart Feature ============
  _initCart();

  // ============ My Learning Feature ============
  _initMyLearning();

  // ============ Course Player Feature ============
  _initCoursePlayer();

  // ============ Quizzes Feature ============
  _initQuizzes();

  // ============ Wishlist Feature ============
  _initWishlist();

  // ============ Settings Feature ============
  _initSettings();

  // ============ Admin Dashboard Feature ============
  _initAdminDashboard();

  // ============ Instructor Dashboard Feature ============
  _initInstructorDashboard();

  // ============ Notifications Feature ============
  _initNotifications();

  // ============ Payments History Feature ============
  _initPaymentsHistory();
}

void _initAuth() {
  // Cubits - AuthCubit as singleton to maintain state across navigation
  sl.registerLazySingleton(() => AuthCubit(
        loginUseCase: sl(),
        loginWithGoogleUseCase: sl(),
        registerUseCase: sl(),
        logoutUseCase: sl(),
        getCurrentUserUseCase: sl(),
        forgotPasswordUseCase: sl(),
        updateInterestsUseCase: sl(),
        sendPhoneOtpUseCase: sl(),
        verifyPhoneOtpUseCase: sl(),
      ));

  sl.registerFactory(() => InterestsCubit(
        updateInterestsUseCase: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdateInterestsUseCase(sl()));
  sl.registerLazySingleton(() => SendPhoneOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPhoneOtpUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl()));
}

void _initHome() {
  // Cubit
  sl.registerFactory(() => HomeCubit(
        getBannersUseCase: sl(),
        getCategoriesUseCase: sl(),
        getFeaturedCoursesUseCase: sl(),
        getPopularCoursesUseCase: sl(),
        getNewCoursesUseCase: sl(),
        getFlashSaleCoursesUseCase: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetBannersUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetFeaturedCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetPopularCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetNewCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetFlashSaleCoursesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(sl()));
}

void _initCourseSearch() {
  // Cubit
  sl.registerFactory(() => CourseSearchCubit(
        searchCoursesUseCase: sl(),
        getCategoriesUseCase: sl<search.GetCategoriesUseCase>(),
        getRecentSearchesUseCase: sl(),
        saveRecentSearchUseCase: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => SearchCoursesUseCase(sl()));
  sl.registerLazySingleton(() => search.GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentSearchesUseCase(sl()));
  sl.registerLazySingleton(() => SaveRecentSearchUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CourseSearchRepository>(
      () => CourseSearchRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data Sources
  sl.registerLazySingleton<CourseSearchRemoteDataSource>(
      () => CourseSearchRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<CourseSearchLocalDataSource>(
      () => CourseSearchLocalDataSourceImpl(sl()));
}

void _initCourseDetails() {
  // Cubit
  sl.registerFactory(() => CourseDetailsCubit(
        getCourseDetailsUseCase: sl(),
        getCourseReviewsUseCase: sl(),
        enrollFreeCourseUseCase: sl(),
        wishlistCubit: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetCourseDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetCourseReviewsUseCase(sl()));
  sl.registerLazySingleton(() => EnrollFreeCourseUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CourseDetailsRepository>(
      () => CourseDetailsRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data Sources
  sl.registerLazySingleton<CourseDetailsRemoteDataSource>(
      () => CourseDetailsRemoteDataSourceImpl(supabaseClient: sl()));
  sl.registerLazySingleton<CourseDetailsLocalDataSource>(
      () => CourseDetailsLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initCart() {
  // Cubits - CartCubit is singleton to share state across screens
  sl.registerLazySingleton(() => CartCubit(
        getCartUseCase: sl(),
        addToCartUseCase: sl(),
        removeFromCartUseCase: sl(),
        applyCouponUseCase: sl(),
        removeCouponUseCase: sl(),
        cartRepository: sl(),
      ));

  sl.registerFactory(() => CheckoutCubit(
        checkoutUseCase: sl(),
        cartRepository: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetCartUseCase(sl()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFromCartUseCase(sl()));
  sl.registerLazySingleton(() => ApplyCouponUseCase(sl()));
  sl.registerLazySingleton(() => RemoveCouponUseCase(sl()));
  sl.registerLazySingleton(() => CheckoutUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<CartRemoteDataSource>(
      () => CartRemoteDataSourceImpl(supabase: sl()));
  sl.registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initMyLearning() {
  // Cubit
  sl.registerFactory(() => MyLearningCubit(
        getEnrollmentsUseCase: sl(),
        getContinueLearningUseCase: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetEnrollmentsUseCase(sl()));
  sl.registerLazySingleton(() => GetContinueLearningUseCase(sl()));

  // Repository
  sl.registerLazySingleton<MyLearningRepository>(() => MyLearningRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<MyLearningRemoteDataSource>(
      () => MyLearningRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<MyLearningLocalDataSource>(
      () => MyLearningLocalDataSourceImpl(sl()));
}

void _initCoursePlayer() {
  // Cubits
  sl.registerFactory(() => CoursePlayerCubit(
        getCourseContentUseCase: sl(),
        getLessonUseCase: sl(),
        updateLessonProgressUseCase: sl(),
        markLessonCompleteUseCase: sl(),
        addBookmarkUseCase: sl(),
        deleteBookmarkUseCase: sl(),
        repository: sl(),
      ));

  sl.registerFactory(() => NotesCubit(
        getNotesUseCase: sl(),
        addNoteUseCase: sl(),
        deleteNoteUseCase: sl(),
        repository: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetCourseContentUseCase(sl()));
  sl.registerLazySingleton(() => GetLessonUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLessonProgressUseCase(sl()));
  sl.registerLazySingleton(() => MarkLessonCompleteUseCase(sl()));
  sl.registerLazySingleton(() => GetNotesUseCase(sl()));
  sl.registerLazySingleton(() => AddNoteUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNoteUseCase(sl()));
  sl.registerLazySingleton(() => GetBookmarksUseCase(sl()));
  sl.registerLazySingleton(() => AddBookmarkUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBookmarkUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CoursePlayerRepository>(
      () => CoursePlayerRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data Sources
  sl.registerLazySingleton<CoursePlayerRemoteDataSource>(
      () => CoursePlayerRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<CoursePlayerLocalDataSource>(
      () => CoursePlayerLocalDataSourceImpl(sl()));
}

void _initQuizzes() {
  // Cubit
  sl.registerFactory(() => QuizCubit(
        getQuizUseCase: sl(),
        getQuizQuestionsUseCase: sl(),
        getQuizAttemptsUseCase: sl(),
        getRemainingAttemptsUseCase: sl(),
        startQuizAttemptUseCase: sl(),
        submitQuizUseCase: sl(),
        localDataSource: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetQuizUseCase(sl()));
  sl.registerLazySingleton(() => GetQuizQuestionsUseCase(sl()));
  sl.registerLazySingleton(() => GetQuizAttemptsUseCase(sl()));
  sl.registerLazySingleton(() => GetRemainingAttemptsUseCase(sl()));
  sl.registerLazySingleton(() => StartQuizAttemptUseCase(sl()));
  sl.registerLazySingleton(() => SubmitQuizUseCase(sl()));

  // Repository
  sl.registerLazySingleton<QuizzesRepository>(() => QuizzesRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<QuizzesRemoteDataSource>(
      () => QuizzesRemoteDataSourceImpl(supabaseClient: sl()));
  sl.registerLazySingleton<QuizzesLocalDataSource>(
      () => QuizzesLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initWishlist() {
  // Cubit - Singleton to share state across screens
  sl.registerLazySingleton(() => WishlistCubit(
        getWishlistUseCase: sl(),
        addToWishlistUseCase: sl(),
        removeFromWishlistUseCase: sl(),
        toggleWishlistUseCase: sl(),
        wishlistRepository: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetWishlistUseCase(sl()));
  sl.registerLazySingleton(() => AddToWishlistUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFromWishlistUseCase(sl()));
  sl.registerLazySingleton(() => wishlist.ToggleWishlistUseCase(sl()));

  // Repository
  sl.registerLazySingleton<WishlistRepository>(() => WishlistRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<WishlistRemoteDataSource>(
      () => WishlistRemoteDataSourceImpl(supabase: sl()));
  sl.registerLazySingleton<WishlistLocalDataSource>(
      () => WishlistLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initSettings() {
  // Cubits - Singleton to share state across screens
  sl.registerLazySingleton(() => SettingsCubit(repository: sl()));
  sl.registerLazySingleton(() => ProfileCubit(repository: sl()));

  // Repository
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<SettingsRemoteDataSource>(
      () => SettingsRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(prefs: sl()));
}

void _initAdminDashboard() {
  // Data Sources - Register first as cubits depend on them
  sl.registerLazySingleton<AdminStatsDataSource>(
      () => AdminStatsDataSource(sl()));
  sl.registerLazySingleton<AdminUsersDataSource>(
      () => AdminUsersDataSource(sl()));
  sl.registerLazySingleton<AdminCoursesDataSource>(
      () => AdminCoursesDataSource(sl()));

  // Repository - Uses multiple data sources
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(
        statsDataSource: sl(),
        usersDataSource: sl(),
        coursesDataSource: sl(),
      ));

  // Cubits - Some use repository, some use data sources directly
  sl.registerFactory(() => AdminDashboardCubit(sl<AdminRepository>()));
  sl.registerFactory(() => AdminUsersCubit(sl<AdminRepository>()));
  sl.registerFactory(() => AdminCoursesCubit(sl<AdminRepository>()));
  sl.registerFactory(() => AdminAnalyticsCubit(sl<AdminRepository>()));
}

void _initInstructorDashboard() {
  // Data Sources - Register first as repository depends on them
  sl.registerLazySingleton<InstructorStatsDataSource>(
      () => InstructorStatsDataSource(sl()));
  sl.registerLazySingleton<InstructorCoursesDataSource>(
      () => InstructorCoursesDataSource(sl()));
  sl.registerLazySingleton<InstructorStudentsDataSource>(
      () => InstructorStudentsDataSource(sl()));
  sl.registerLazySingleton<InstructorEnrollmentsDataSource>(
      () => InstructorEnrollmentsDataSource(sl()));
  sl.registerLazySingleton<InstructorEarningsDataSource>(
      () => InstructorEarningsDataSource(sl()));
  sl.registerLazySingleton<InstructorQADataSource>(
      () => InstructorQADataSource(sl()));
  sl.registerLazySingleton<InstructorReviewsDataSource>(
      () => InstructorReviewsDataSource(sl()));
  sl.registerLazySingleton<InstructorCourseEditorDataSource>(
      () => InstructorCourseEditorDataSource(sl()));
  sl.registerLazySingleton<InstructorAnnouncementsDataSource>(
      () => InstructorAnnouncementsDataSource(sl()));

  // Repository - Uses multiple data sources
  sl.registerLazySingleton<InstructorRepository>(() => InstructorRepositoryImpl(
        client: sl(),
        statsDataSource: sl(),
        coursesDataSource: sl(),
        studentsDataSource: sl(),
        enrollmentsDataSource: sl(),
        earningsDataSource: sl(),
        qaDataSource: sl(),
        reviewsDataSource: sl(),
        courseEditorDataSource: sl(),
        announcementsDataSource: sl(),
      ));

  // Cubits
  sl.registerFactory(() => InstructorDashboardCubit(sl()));
  sl.registerFactory(() => InstructorCoursesCubit(sl()));
  sl.registerFactory(() => InstructorStudentsCubit(sl()));
  sl.registerFactory(() => InstructorEnrollmentsCubit(sl()));
  sl.registerFactory(() => InstructorEarningsCubit(sl()));
  sl.registerFactory(() => InstructorQACubit(sl()));
  sl.registerFactory(() => InstructorReviewsCubit(sl()));
  sl.registerFactory(() => CourseEditorCubit(sl()));
  sl.registerFactory(() => InstructorCouponsCubit(sl()));
  sl.registerFactory(() => InstructorQuizzesCubit(sl()));
  sl.registerFactory(() => InstructorAnnouncementsCubit(sl()));
  sl.registerFactory(() => InstructorCategoriesCubit(sl()));
  sl.registerFactory(() => InstructorBannersCubit(sl()));
}

void _initNotifications() {
  // Data Source
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSource(sl()));

  // Repository
  sl.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl()));

  // Cubit - Singleton to share state across screens
  sl.registerLazySingleton(() => NotificationsCubit(sl()));
}

void _initPaymentsHistory() {
  // Data Source
  sl.registerLazySingleton<PaymentsRemoteDataSource>(
      () => PaymentsRemoteDataSourceImpl(supabase: sl()));

  // Repository
  sl.registerLazySingleton<PaymentsRepository>(
      () => PaymentsRepositoryImpl(remoteDataSource: sl()));

  // Use Case
  sl.registerLazySingleton(() => GetUserPaymentsUseCase(sl()));

  // Cubit
  sl.registerFactory(() => PaymentsHistoryCubit(
        getUserPaymentsUseCase: sl(),
      ));
}
