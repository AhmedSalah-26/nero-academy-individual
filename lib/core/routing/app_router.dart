import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../di/injection_container.dart';
import '../services/app_logger.dart';
import '../services/user_role_service.dart';
import '../services/reports_service.dart';
import '../animations/page_transitions.dart';
import '../shared_widgets/report_screen.dart';
// Splash
import '../../features/splash/presentation/screens/splash_screen.dart';
// Notifications
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
// Categories
import '../../features/categories/presentation/screens/categories_screen.dart';
// Q&A
import '../../features/qa/presentation/screens/qa_screen.dart';
import '../../features/qa/presentation/screens/ask_question_screen.dart';
// Auth
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/interests_cubit.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/interests_selection_screen.dart';
// Main
import '../../features/main/presentation/screens/main_screen.dart';
// Home
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/courses_list_screen.dart';
import '../../features/home/domain/entities/course_entity.dart' as home;

// My Learning
import '../../features/my_learning/presentation/screens/my_learning_screen.dart';
// History
import '../../features/history/presentation/screens/history_screen.dart';
// Forums
import '../../features/course_forum/presentation/screens/forums_list_screen.dart';
import '../../features/course_forum/presentation/screens/forum_chat_screen.dart';
import '../../features/course_forum/presentation/screens/course_forums_management_screen.dart';

// Wishlist
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
// Profile
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/help_support_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/terms_of_service_screen.dart';
import '../../features/settings/presentation/cubit/profile_cubit.dart';
import '../../features/settings/presentation/screens/student_profile_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/students_progress_sheet_screen.dart';
// Course Search
import '../../features/course_search/presentation/cubit/course_search_cubit.dart';
import '../../features/course_search/presentation/screens/course_search_screen.dart';
import '../../features/course_search/presentation/screens/course_filter_screen.dart';
import '../../features/course_search/domain/entities/search_filter_entity.dart';
// Payments History / Orders Status
import '../../features/payments_history/presentation/screens/payments_history_screen.dart';
// Course Details
import '../../features/course_details/presentation/cubit/course_details_cubit.dart';
import '../../features/course_details/presentation/screens/course_details_screen.dart';
// Cart & Checkout
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/cart/presentation/cubit/checkout_cubit.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cart/presentation/screens/checkout_screen.dart';
import '../../features/cart/presentation/screens/payment_success_screen.dart';
import '../../features/cart/domain/entities/cart_entity.dart';
// Course Player
import '../../features/course_player/presentation/cubit/course_player_cubit.dart';
import '../../features/course_player/presentation/screens/course_player_screen.dart';
import '../../features/course_player/presentation/screens/attachment_preview_screen.dart';
// Quizzes
import '../../features/quizzes/presentation/cubit/quiz_cubit.dart';
import '../../features/quizzes/presentation/screens/quiz_info_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_question_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_results_screen.dart';

// Instructor Dashboard
import '../../features/instructor_dashboard/presentation/cubit/instructor_cubits.dart';
import '../../features/instructor_dashboard/presentation/screens/instructor_dashboard_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/course_editor_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/course_enrollments_screen.dart'
    as instructor_enrollments;
import '../../features/instructor_dashboard/presentation/screens/student_details_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/student_progress_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/send_message_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/student_enrollments_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/quiz_attempts_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/quiz_response_details_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/coupon_editor_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/earnings_history_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/quiz_editor_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/create_quiz_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/quiz_questions_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/quiz_preview_screen.dart';
import '../../features/instructor_dashboard/data/models/instructor_student_model.dart';
import '../../features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import '../../features/instructor_dashboard/presentation/screens/category_editor_screen.dart';
import '../../features/instructor_dashboard/presentation/screens/banner_editor_screen.dart';
import '../../features/instructor_dashboard/data/models/category_model.dart';
import '../../features/instructor_dashboard/data/models/banner_model.dart';

// Instructor
import '../../features/instructor/data/datasources/instructor_remote_data_source.dart';
import '../../features/instructor/presentation/cubit/instructor_cubit.dart';
import '../../features/instructor/presentation/screens/instructor_profile_screen.dart';

/// App Router - Centralized routing configuration
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),

      // ==================== Splash Screen ====================
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ==================== Auth Routes ====================
      // Singleton cubits from GetIt must use BlocProvider.value to avoid
      // automatic close on route dispose.
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => BlocProvider.value(
          value: sl<AuthCubit>()..checkAuthStatus(),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => BlocProvider.value(
          value: sl<AuthCubit>(),
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/interests',
        name: 'interests',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<InterestsCubit>(),
          child: const InterestsSelectionScreen(),
        ),
      ),

      // ==================== Main App with StatefulShellRoute ====================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home tab (index 0)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // My Learning tab (index 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-learning',
                name: 'my-learning',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MyLearningScreen(),
                ),
              ),
            ],
          ),
          // Forums tab (index 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/forums-tab',
                name: 'forums-tab',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ForumsListScreen(),
                ),
              ),
            ],
          ),
          // Profile tab (index 4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ==================== Routes outside shell (full screen) ====================

      // Courses List (See All)
      GoRoute(
        path: '/courses-list',
        name: 'courses-list',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final title = extra?['title'] as String? ?? 'Courses';
          final courses = extra?['courses'] as List<home.CourseEntity>? ?? [];
          return BlocProvider.value(
            value: sl<WishlistCubit>(),
            child: CoursesListScreen(title: title, courses: courses),
          );
        },
      ),

      // Course Search
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          final categoryId = state.uri.queryParameters['category'];
          return BlocProvider(
            create: (_) {
              final cubit = sl<CourseSearchCubit>()..init();
              if (query != null && query.isNotEmpty) {
                cubit.search(query);
              } else if (categoryId != null) {
                cubit.applyFilters(
                  SearchFilterEntity(categoryIds: [categoryId]),
                );
              }
              return cubit;
            },
            child: const CourseSearchScreen(),
          );
        },
      ),

      // Categories
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesScreen(),
      ),

      // History (moved from nav bar to push route)
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),

      // Orders Status (Payments History)
      GoRoute(
        path: '/orders-status',
        name: 'orders-status',
        builder: (context, state) => const PaymentsHistoryScreen(),
      ),

      // Wishlist (moved from nav bar)
      GoRoute(
        path: '/wishlist',
        name: 'wishlist',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<WishlistCubit>()),
            BlocProvider.value(value: sl<CartCubit>()),
          ],
          child: const WishlistScreen(),
        ),
      ),

      // Q&A
      GoRoute(
        path: '/qa/:courseId',
        name: 'qa',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final lessonId = state.uri.queryParameters['lesson'];
          return QAScreen(courseId: courseId, lessonId: lessonId);
        },
      ),

      // Ask Question
      GoRoute(
        path: '/qa/:courseId/ask',
        name: 'ask-question',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final lessonId = state.uri.queryParameters['lesson'];
          final extra = state.extra as Map<String, dynamic>?;
          return AskQuestionScreen(
            courseId: courseId,
            lessonId: lessonId,
            onQuestionPosted: extra?['onQuestionPosted'] as VoidCallback?,
          );
        },
      ),

      // Course Filter
      GoRoute(
        path: '/search/filter',
        name: 'course-filter',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CourseFilterScreen(
            initialFilter: extra?['initialFilter'] as SearchFilterEntity? ??
                const SearchFilterEntity(),
            categories:
                extra?['categories'] as List<Map<String, dynamic>>? ?? [],
          );
        },
      ),

      // Instructor Profile
      GoRoute(
        path: '/instructor/profile/:instructorId',
        name: 'instructor-profile',
        builder: (context, state) {
          final instructorId = state.pathParameters['instructorId']!;
          final returnCourseId = state.uri.queryParameters['returnCourseId'];
          final fallbackLocation =
              returnCourseId == null ? '/home' : '/course/$returnCourseId';
          return BlocProvider(
            create: (_) => InstructorCubit(
              remoteDataSource: InstructorRemoteDataSourceImpl(sl()),
            )..loadInstructor(instructorId),
            child: InstructorProfileScreen(
              instructorId: instructorId,
              fallbackLocation: fallbackLocation,
            ),
          );
        },
      ),

      // Course Details
      GoRoute(
        path: '/course/:courseId',
        name: 'course-details',
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final userId = Supabase.instance.client.auth.currentUser?.id;
          return AnimatedPageTransitions.sharedAxis<void>(
            key: state.pageKey,
            name: 'course-details',
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => sl<CourseDetailsCubit>()
                    ..loadCourseDetails(courseId, userId: userId),
                ),
                BlocProvider.value(value: sl<WishlistCubit>()),
                BlocProvider.value(value: sl<CartCubit>()),
              ],
              child: CourseDetailsScreen(courseId: courseId),
            ),
          );
        },
      ),

      // Cart
      GoRoute(
        path: '/cart',
        name: 'cart',
        pageBuilder: (context, state) => AnimatedPageTransitions.slide<void>(
          key: state.pageKey,
          name: 'cart',
          direction: SlideDirection.up,
          child: BlocProvider.value(
            value: sl<CartCubit>(),
            child: const CartScreen(),
          ),
        ),
      ),

      // Checkout
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        pageBuilder: (context, state) {
          final cart = state.extra as CartEntity?;
          if (cart == null) {
            return AnimatedPageTransitions.slide<void>(
              key: state.pageKey,
              name: 'checkout',
              child: BlocProvider.value(
                value: sl<CartCubit>(),
                child: const CartScreen(),
              ),
            );
          }
          return AnimatedPageTransitions.slide<void>(
            key: state.pageKey,
            name: 'checkout',
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<CheckoutCubit>()),
                BlocProvider.value(value: sl<CartCubit>()),
              ],
              child: CheckoutScreen(cart: cart),
            ),
          );
        },
      ),

      // Payment Success
      GoRoute(
        path: '/payment-success',
        name: 'payment-success',
        pageBuilder: (context, state) {
          final orderId = state.extra as String? ?? '';
          return AnimatedPageTransitions.scale<void>(
            key: state.pageKey,
            name: 'payment-success',
            child: PaymentSuccessScreen(orderId: orderId),
          );
        },
      ),

      // Course Player
      GoRoute(
        path: '/learn/:courseId',
        name: 'course-player',
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final enrollmentId = state.uri.queryParameters['enrollment'] ?? '';
          final courseTitle = state.uri.queryParameters['title'] ?? '';
          final lessonId = state.uri.queryParameters['lesson'];
          final instructorId = state.uri.queryParameters['instructorId'];
          final instructorName = state.uri.queryParameters['instructor'];
          final instructorAvatar = state.uri.queryParameters['avatar'];

          return AnimatedPageTransitions.fade<void>(
            key: state.pageKey,
            name: 'course-player',
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<CoursePlayerCubit>()),
                BlocProvider.value(value: sl<WishlistCubit>()),
              ],
              child: CoursePlayerScreen(
                courseId: courseId,
                enrollmentId: enrollmentId,
                courseTitle: courseTitle,
                initialLessonId: lessonId,
                instructorId: instructorId,
                instructorName: instructorName,
                instructorAvatar: instructorAvatar,
              ),
            ),
          );
        },
      ),

      // Chat (Forum / Direct)
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ForumChatScreen(
            conversationId: conversationId,
            conversationTitle: extra?['conversationTitle'] as String? ?? '',
          );
        },
      ),

      GoRoute(
        path: '/forums-management',
        name: 'forums-management',
        builder: (context, state) => const CourseForumsManagementScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => BlocProvider.value(
          value: sl<SettingsCubit>(),
          child: const SettingsScreen(),
        ),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => BlocProvider.value(
          value: sl<NotificationsCubit>(),
          child: const NotificationsScreen(),
        ),
      ),

      // Help Support
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),

      // Edit Profile
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => BlocProvider.value(
          value: sl<ProfileCubit>(),
          child: const EditProfileScreen(),
        ),
      ),

      // Terms of Service
      GoRoute(
        path: '/terms-of-service',
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      // Student Profile
      GoRoute(
        path: '/student-profile',
        name: 'student-profile',
        builder: (context, state) => const StudentProfileScreen(),
      ),

      // Quiz Info
      GoRoute(
        path: '/quiz/:quizId',
        name: 'quiz-info',
        builder: (context, state) {
          final quizId = state.pathParameters['quizId']!;
          final enrollmentId = state.uri.queryParameters['enrollment'] ?? '';
          final courseTitle = state.uri.queryParameters['title'];
          final courseId = state.uri.queryParameters['courseId'];
          final lessonId = state.uri.queryParameters['lesson'];
          final instructorId = state.uri.queryParameters['instructorId'];
          final instructorName = state.uri.queryParameters['instructor'];
          final instructorAvatar = state.uri.queryParameters['avatar'];
          return BlocProvider(
            create: (_) => sl<QuizCubit>()
              ..loadQuiz(quizId: quizId, enrollmentId: enrollmentId),
            child: QuizInfoScreen(
              quizId: quizId,
              enrollmentId: enrollmentId,
              courseTitle: courseTitle,
              courseId: courseId,
              lessonId: lessonId,
              instructorId: instructorId,
              instructorName: instructorName,
              instructorAvatar: instructorAvatar,
            ),
          );
        },
      ),

      // Quiz Questions
      GoRoute(
        path: '/quiz/:quizId/questions',
        name: 'quiz-questions',
        builder: (context, state) {
          final quizId = state.pathParameters['quizId']!;
          final enrollmentId = state.uri.queryParameters['enrollment'] ?? '';
          final courseTitle = state.uri.queryParameters['title'];
          final courseId = state.uri.queryParameters['courseId'];
          final lessonId = state.uri.queryParameters['lesson'];
          final instructorId = state.uri.queryParameters['instructorId'];
          final instructorName = state.uri.queryParameters['instructor'];
          final instructorAvatar = state.uri.queryParameters['avatar'];
          return BlocProvider(
            create: (_) => sl<QuizCubit>(),
            child: QuizQuestionScreen(
              quizId: quizId,
              enrollmentId: enrollmentId,
              courseTitle: courseTitle,
              courseId: courseId,
              lessonId: lessonId,
              instructorId: instructorId,
              instructorName: instructorName,
              instructorAvatar: instructorAvatar,
            ),
          );
        },
      ),

      // Quiz Results
      GoRoute(
        path: '/quiz/:quizId/results',
        name: 'quiz-results',
        builder: (context, state) {
          final quizId = state.pathParameters['quizId']!;
          final enrollmentId = state.uri.queryParameters['enrollment'] ?? '';
          final attemptId = state.uri.queryParameters['attemptId'];
          final courseTitle = state.uri.queryParameters['title'];
          final courseId = state.uri.queryParameters['courseId'];
          final lessonId = state.uri.queryParameters['lesson'];
          final instructorId = state.uri.queryParameters['instructorId'];
          final instructorName = state.uri.queryParameters['instructor'];
          final instructorAvatar = state.uri.queryParameters['avatar'];
          return BlocProvider(
            create: (_) => sl<QuizCubit>()
              ..loadResults(
                quizId: quizId,
                enrollmentId: enrollmentId,
                attemptId: attemptId,
              ),
            child: QuizResultsScreen(
              quizId: quizId,
              enrollmentId: enrollmentId,
              courseTitle: courseTitle,
              courseId: courseId,
              lessonId: lessonId,
              instructorId: instructorId,
              instructorName: instructorName,
              instructorAvatar: instructorAvatar,
            ),
          );
        },
      ),

      // Attachment Preview
      GoRoute(
        path: '/attachment-preview',
        name: 'attachment-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final url = extra?['url'] as String? ?? '';
          final title = extra?['title'] as String? ?? 'Preview';
          return AttachmentPreviewScreen(url: url, title: title);
        },
      ),

      // Instructor Dashboard
      GoRoute(
        path: '/instructor',
        name: 'instructor-dashboard',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<InstructorDashboardCubit>()),
            BlocProvider(create: (_) => sl<InstructorCoursesCubit>()),
            BlocProvider(create: (_) => sl<InstructorStudentsCubit>()),
            BlocProvider(create: (_) => sl<InstructorEnrollmentsCubit>()),
            BlocProvider(create: (_) => sl<InstructorEarningsCubit>()),
            BlocProvider(create: (_) => sl<InstructorQACubit>()),
            BlocProvider(create: (_) => sl<InstructorReviewsCubit>()),
            BlocProvider(create: (_) => sl<InstructorCouponsCubit>()),
            BlocProvider(create: (_) => sl<InstructorQuizzesCubit>()),
            BlocProvider(create: (_) => sl<InstructorCategoriesCubit>()),
            BlocProvider(create: (_) => sl<InstructorBannersCubit>()),
          ],
          child: const InstructorDashboardScreen(),
        ),
      ),

      // Course Editor - New Course
      GoRoute(
        path: '/instructor/course/new',
        name: 'course-editor-new',
        builder: (context, state) {
          AppLogger.i('🛣️ [Router] Building CourseEditorScreen (new)');
          return BlocProvider(
            create: (_) {
              AppLogger.i('🛣️ [Router] Creating CourseEditorCubit');
              return sl<CourseEditorCubit>();
            },
            child: const CourseEditorScreen(),
          );
        },
      ),

      // Course Editor - Edit Course
      GoRoute(
        path: '/instructor/course/:courseId/edit',
        name: 'course-editor-edit',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          AppLogger.i(
              '🛣️ [Router] Building CourseEditorScreen (edit): $courseId');
          return BlocProvider(
            create: (_) {
              AppLogger.i('🛣️ [Router] Creating CourseEditorCubit for edit');
              return sl<CourseEditorCubit>();
            },
            child: CourseEditorScreen(courseId: courseId),
          );
        },
      ),

      // Course Enrollments - View enrolled students
      GoRoute(
        path: '/instructor/course/:courseId/enrollments',
        name: 'course-enrollments',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final courseTitle = extra?['courseTitle'] as String? ?? 'Course';
          AppLogger.i(
              '🛣️ [Router] Building InstructorCourseEnrollmentsScreen: $courseId');
          return instructor_enrollments.InstructorCourseEnrollmentsScreen(
            courseId: courseId,
            courseTitle: courseTitle,
          );
        },
      ),

      // Student Details
      GoRoute(
        path: '/instructor/student/:studentId',
        name: 'student-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final student = extra?['student'] as InstructorStudentModel?;
          if (student == null) {
            return const Scaffold(
              body: Center(child: Text('Student not found')),
            );
          }
          return StudentDetailsScreen(
            student: student,
            onSendMessage: extra?['onSendMessage'] as VoidCallback?,
            onViewEnrollments: extra?['onViewEnrollments'] as VoidCallback?,
            onViewProgress: extra?['onViewProgress'] as VoidCallback?,
          );
        },
      ),

      // Report Screen
      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final targetType = extra?['targetType'] as ReportTargetType?;
          final targetId = extra?['targetId'] as String?;
          if (targetType == null || targetId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid report data')),
            );
          }
          return ReportScreen(
            targetType: targetType,
            targetId: targetId,
            targetTitle: extra?['targetTitle'] as String?,
            onReportSubmitted: extra?['onReportSubmitted'] as VoidCallback?,
            reviewerId: extra?['reviewerId'] as String?,
            reviewComment: extra?['reviewComment'] as String?,
            reviewRating: extra?['reviewRating'] as int?,
          );
        },
      ),

      // Student Progress
      GoRoute(
        path: '/instructor/student/:studentId/progress',
        name: 'student-progress',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final studentName = extra?['studentName'] as String? ?? '';
          final progressList =
              extra?['progressList'] as List<StudentCourseProgress>? ?? [];
          return StudentProgressScreen(
            studentName: studentName,
            progressList: progressList,
          );
        },
      ),

      // Send Message
      GoRoute(
        path: '/instructor/student/:studentId/message',
        name: 'send-message',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final studentName = extra?['studentName'] as String? ?? '';
          final studentEmail = extra?['studentEmail'] as String?;
          final onSend = extra?['onSend'] as Function(String, String)?;
          if (onSend == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid message data')),
            );
          }
          return SendMessageScreen(
            studentName: studentName,
            studentEmail: studentEmail,
            onSend: onSend,
          );
        },
      ),

      // Student Enrollments
      GoRoute(
        path: '/instructor/student/:studentId/enrollments',
        name: 'student-enrollments',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid enrollment data')),
            );
          }
          return StudentEnrollmentsScreen(
            studentId: extra['studentId'] as String? ?? '',
            studentName: extra['studentName'] as String? ?? '',
            enrollments:
                extra['enrollments'] as List<StudentEnrollmentDetail>? ?? [],
            onExtendAccess:
                extra['onExtendAccess'] as Future<bool> Function(String, int),
            onResetProgress:
                extra['onResetProgress'] as Future<bool> Function(String),
            onUpdateStatus: extra['onUpdateStatus'] as Future<bool> Function(
                String, String),
            onUnenroll: extra['onUnenroll'] as Future<bool> Function(String),
            onEnrollInCourse:
                extra['onEnrollInCourse'] as Future<bool> Function(String),
            availableCourses: extra['availableCourses']
                    as List<AvailableCourseForEnrollment>? ??
                [],
            onRefreshEnrollments: extra['onRefreshEnrollments']
                as Future<List<StudentEnrollmentDetail>> Function(),
            onRefreshAvailableCourses: extra['onRefreshAvailableCourses']
                as Future<List<AvailableCourseForEnrollment>> Function(),
          );
        },
      ),

      // Quiz Attempts
      GoRoute(
        path: '/instructor/quiz/:quizId/attempts',
        name: 'quiz-attempts',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid quiz data')),
            );
          }
          return QuizAttemptsScreen(
            quizId: extra['quizId'] as String? ?? '',
            quizTitle: extra['quizTitle'] as String? ?? '',
            attempts: extra['attempts'] as List<Map<String, dynamic>>? ?? [],
          );
        },
      ),

      // Quiz Response Details
      GoRoute(
        path: '/instructor/quiz/:quizId/response/:attemptId',
        name: 'quiz-response-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid response data')),
            );
          }
          return QuizResponseDetailsScreen(
            studentName: extra['studentName'] as String? ?? 'Unknown',
            studentEmail: extra['studentEmail'] as String?,
            score: (extra['score'] as num?)?.toDouble() ?? 0,
            passed: extra['passed'] as bool? ?? false,
            completedAt: extra['completedAt'] as DateTime?,
            timeTaken: extra['timeTaken'] as int? ?? 0,
            answers: extra['answers'] as List<QuizAnswerDetail>? ?? [],
          );
        },
      ),

      // Coupon Editor
      GoRoute(
        path: '/instructor/coupon/edit',
        name: 'coupon-editor',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid coupon data')),
            );
          }
          return CouponEditorScreen(
            coupon: extra['coupon'] as InstructorCouponModel?,
            onSave:
                extra['onSave'] as Future<bool> Function(Map<String, dynamic>),
          );
        },
      ),

      // Earnings History
      GoRoute(
        path: '/instructor/earnings/history',
        name: 'earnings-history',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<InstructorEarningsCubit>(),
          child: const EarningsHistoryScreen(),
        ),
      ),

      // Students Progress Sheet
      GoRoute(
        path: '/instructor/students-progress-sheet',
        name: 'students-progress-sheet',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return StudentsProgressSheetScreen(
            courseId: extra?['courseId'] as String?,
            courseTitle: extra?['courseTitle'] as String?,
          );
        },
      ),

      // Quiz Editor
      GoRoute(
        path: '/instructor/quiz/:quizId/edit',
        name: 'quiz-editor',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid quiz data')),
            );
          }
          return QuizEditorScreen(
            quiz: extra['quiz'] as InstructorQuizModel?,
            onSave:
                extra['onSave'] as Future<bool> Function(Map<String, dynamic>),
          );
        },
      ),

      // Create Quiz
      GoRoute(
        path: '/instructor/quiz/create',
        name: 'create-quiz',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final cubit = extra?['cubit'] as InstructorQuizzesCubit? ??
              sl<InstructorQuizzesCubit>();
          return BlocProvider.value(
            value: cubit,
            child: CreateQuizScreen(cubit: cubit),
          );
        },
      ),

      // Quiz Questions Management
      GoRoute(
        path: '/instructor/quiz/:quizId/questions',
        name: 'instructor-quiz-questions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid quiz data')),
            );
          }
          return QuizQuestionsScreen(
            quiz: extra['quiz'] as InstructorQuizModel,
            cubit: extra['cubit'] as InstructorQuizzesCubit,
          );
        },
      ),

      // Quiz Preview
      GoRoute(
        path: '/instructor/quiz/:quizId/preview',
        name: 'quiz-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid quiz data')),
            );
          }
          return QuizPreviewScreen(
            quizId: extra['quizId'] as String,
            quizTitle: extra['quizTitle'] as String,
            questions: extra['questions'] as List<Map<String, dynamic>>,
            timeLimit: extra['timeLimit'] as int?,
          );
        },
      ),

      // Category Editor
      GoRoute(
        path: '/instructor/category-editor',
        name: 'category-editor',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid category data')),
            );
          }
          return CategoryEditorScreen(
            category: extra['category'] as CategoryModel?,
            onSave: extra['onSave'] as void Function(dynamic),
          );
        },
      ),

      // Banner Editor
      GoRoute(
        path: '/instructor/banner-editor',
        name: 'banner-editor',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid banner data')),
            );
          }
          return BannerEditorScreen(
            banner: extra['banner'] as BannerModel?,
            onSave: extra['onSave'] as Future<void> Function(BannerCreateDto),
          );
        },
      ),
    ],
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final path = state.uri.path;

      // Instructor workspace access control. Public instructor profiles live
      // under /instructor/profile/:instructorId and remain publicly reachable.
      final isInstructorWorkspace =
          path == '/instructor' || path.startsWith('/instructor/');
      final isPublicInstructorProfile = path.startsWith('/instructor/profile/');
      if (isInstructorWorkspace && !isPublicInstructorProfile) {
        if (user == null) {
          return '/login';
        }
        // Check if user is instructor or admin from database
        final isInstructor = await UserRoleService.isInstructor();
        if (!isInstructor) {
          return '/home';
        }
      }

      return null;
    },
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );

  // ==================== Navigation Helpers ====================

  static void goToLogin(BuildContext context) => context.goNamed('login');
  static void goToHome(BuildContext context) => context.goNamed('home');

  static void goToCoursesList(
    BuildContext context, {
    required String title,
    required List<home.CourseEntity> courses,
  }) {
    context
        .pushNamed('courses-list', extra: {'title': title, 'courses': courses});
  }

  static void goToCourseDetails(BuildContext context, String courseId) {
    context.pushNamed('course-details', pathParameters: {'courseId': courseId});
  }

  static void goToSearch(BuildContext context,
      {String? query, String? categoryId}) {
    final queryParams = <String, String>{};
    if (query != null) queryParams['q'] = query;
    if (categoryId != null) queryParams['category'] = categoryId;
    context.pushNamed('search', queryParameters: queryParams);
  }

  static void goToCart(BuildContext context) => context.pushNamed('cart');

  static void goToCheckout(BuildContext context, CartEntity cart) {
    context.pushNamed('checkout', extra: cart);
  }

  static void goToPaymentSuccess(BuildContext context, String orderId) {
    context.goNamed('payment-success', extra: orderId);
  }

  static void goToMyLearning(BuildContext context) =>
      context.goNamed('my-learning');
  static void goToWishlist(BuildContext context) => context.goNamed('wishlist');
  static void goToProfile(BuildContext context) => context.goNamed('profile');

  static void goToCoursePlayer(
    BuildContext context, {
    required String courseId,
    required String enrollmentId,
    required String courseTitle,
    String? lessonId,
    String? instructorId,
    String? instructorName,
    String? instructorAvatar,
  }) {
    final queryParams = <String, String>{
      'enrollment': enrollmentId,
      'title': courseTitle,
    };
    if (lessonId != null) queryParams['lesson'] = lessonId;
    if (instructorId != null) queryParams['instructorId'] = instructorId;
    if (instructorName != null) queryParams['instructor'] = instructorName;
    if (instructorAvatar != null) queryParams['avatar'] = instructorAvatar;

    context.pushNamed('course-player',
        pathParameters: {'courseId': courseId}, queryParameters: queryParams);
  }

  static void goToCoursePlayerSimple(BuildContext context, String courseId) {
    context.pushNamed('course-player',
        pathParameters: {'courseId': courseId},
        queryParameters: {'enrollment': '', 'title': ''});
  }

  static void goToChat(
    BuildContext context, {
    required String conversationId,
    required String conversationTitle,
  }) {
    context.pushNamed('chat', pathParameters: {
      'conversationId': conversationId,
    }, extra: {
      'conversationTitle': conversationTitle,
    });
  }

  static void goToForumsList(BuildContext context) =>
      context.pushNamed('forums-tab');

  static Future<void> goToCourseForumsManagement(BuildContext context) {
    return context.pushNamed('forums-management');
  }

  static void goToHistory(BuildContext context) => context.pushNamed('history');

  static void goToOrdersStatus(BuildContext context) =>
      context.pushNamed('orders-status');

  static void goToSettings(BuildContext context) =>
      context.pushNamed('settings');
  static void goToHelpSupport(BuildContext context) =>
      context.pushNamed('help-support');
  static void goToEditProfile(BuildContext context) =>
      context.pushNamed('edit-profile');
  static void goToTermsOfService(BuildContext context) =>
      context.pushNamed('terms-of-service');

  static void goToQuiz(BuildContext context,
      {required String quizId,
      required String enrollmentId,
      String? courseTitle}) {
    final queryParams = <String, String>{'enrollment': enrollmentId};
    if (courseTitle != null) queryParams['title'] = courseTitle;
    context.pushNamed('quiz-info',
        pathParameters: {'quizId': quizId}, queryParameters: queryParams);
  }

  static void goToQuizQuestions(BuildContext context,
      {required String quizId, required String enrollmentId}) {
    context.pushNamed('quiz-questions',
        pathParameters: {'quizId': quizId},
        queryParameters: {'enrollment': enrollmentId});
  }

  static void goToQuizResults(BuildContext context,
      {required String quizId, required String enrollmentId}) {
    context.pushNamed('quiz-results',
        pathParameters: {'quizId': quizId},
        queryParameters: {'enrollment': enrollmentId});
  }

  static void goToNotifications(BuildContext context) =>
      context.pushNamed('notifications');
  static void goToCategories(BuildContext context) =>
      context.pushNamed('categories');

  static void goToInstructorDashboard(BuildContext context) =>
      context.pushNamed('instructor-dashboard');

  static void goToQA(BuildContext context, String courseId,
      {String? lessonId}) {
    final queryParams = <String, String>{};
    if (lessonId != null) queryParams['lesson'] = lessonId;
    context.pushNamed('qa',
        pathParameters: {'courseId': courseId}, queryParameters: queryParams);
  }

  static void goToAskQuestion(
    BuildContext context, {
    required String courseId,
    String? lessonId,
    VoidCallback? onQuestionPosted,
  }) {
    final queryParams = <String, String>{};
    if (lessonId != null) queryParams['lesson'] = lessonId;
    context.pushNamed('ask-question',
        pathParameters: {'courseId': courseId},
        queryParameters: queryParams,
        extra: {'onQuestionPosted': onQuestionPosted});
  }

  static Future<SearchFilterEntity?> goToCourseFilter(
    BuildContext context, {
    required SearchFilterEntity initialFilter,
    required List<Map<String, dynamic>> categories,
  }) {
    return context.pushNamed<SearchFilterEntity>('course-filter', extra: {
      'initialFilter': initialFilter,
      'categories': categories,
    });
  }

  static void goToStudentDetails(
    BuildContext context, {
    required InstructorStudentModel student,
    VoidCallback? onSendMessage,
    VoidCallback? onViewEnrollments,
    VoidCallback? onViewProgress,
  }) {
    context.pushNamed('student-details', pathParameters: {
      'studentId': student.id
    }, extra: {
      'student': student,
      'onSendMessage': onSendMessage,
      'onViewEnrollments': onViewEnrollments,
      'onViewProgress': onViewProgress,
    });
  }

  static void goToReport(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? targetTitle,
    VoidCallback? onReportSubmitted,
    String? reviewerId,
    String? reviewComment,
    int? reviewRating,
  }) {
    context.pushNamed('report', extra: {
      'targetType': targetType,
      'targetId': targetId,
      'targetTitle': targetTitle,
      'onReportSubmitted': onReportSubmitted,
      'reviewerId': reviewerId,
      'reviewComment': reviewComment,
      'reviewRating': reviewRating,
    });
  }

  static void goToStudentProgress(
    BuildContext context, {
    required String studentId,
    required String studentName,
    required List<StudentCourseProgress> progressList,
  }) {
    context.pushNamed('student-progress', pathParameters: {
      'studentId': studentId
    }, extra: {
      'studentName': studentName,
      'progressList': progressList,
    });
  }

  static void goToSendMessage(
    BuildContext context, {
    required String studentId,
    required String studentName,
    String? studentEmail,
    required Function(String, String) onSend,
  }) {
    context.pushNamed('send-message', pathParameters: {
      'studentId': studentId
    }, extra: {
      'studentName': studentName,
      'studentEmail': studentEmail,
      'onSend': onSend,
    });
  }

  static void goToStudentEnrollments(
    BuildContext context, {
    required String studentId,
    required String studentName,
    required List<StudentEnrollmentDetail> enrollments,
    required Future<bool> Function(String, int) onExtendAccess,
    required Future<bool> Function(String) onResetProgress,
    required Future<bool> Function(String, String) onUpdateStatus,
    required Future<bool> Function(String) onUnenroll,
    required Future<bool> Function(String) onEnrollInCourse,
    required List<AvailableCourseForEnrollment> availableCourses,
    required Future<List<StudentEnrollmentDetail>> Function()
        onRefreshEnrollments,
    required Future<List<AvailableCourseForEnrollment>> Function()
        onRefreshAvailableCourses,
  }) {
    context.pushNamed('student-enrollments', pathParameters: {
      'studentId': studentId
    }, extra: {
      'studentId': studentId,
      'studentName': studentName,
      'enrollments': enrollments,
      'onExtendAccess': onExtendAccess,
      'onResetProgress': onResetProgress,
      'onUpdateStatus': onUpdateStatus,
      'onUnenroll': onUnenroll,
      'onEnrollInCourse': onEnrollInCourse,
      'availableCourses': availableCourses,
      'onRefreshEnrollments': onRefreshEnrollments,
      'onRefreshAvailableCourses': onRefreshAvailableCourses,
    });
  }

  static void goToQuizAttempts(
    BuildContext context, {
    required String quizId,
    required String quizTitle,
    required List<Map<String, dynamic>> attempts,
  }) {
    context.pushNamed('quiz-attempts', pathParameters: {
      'quizId': quizId
    }, extra: {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'attempts': attempts,
    });
  }

  static void goToQuizResponseDetails(
    BuildContext context, {
    required String quizId,
    required String attemptId,
    required String studentName,
    String? studentEmail,
    required double score,
    required bool passed,
    DateTime? completedAt,
    required int timeTaken,
    required List<QuizAnswerDetail> answers,
  }) {
    context.pushNamed('quiz-response-details', pathParameters: {
      'quizId': quizId,
      'attemptId': attemptId,
    }, extra: {
      'studentName': studentName,
      'studentEmail': studentEmail,
      'score': score,
      'passed': passed,
      'completedAt': completedAt,
      'timeTaken': timeTaken,
      'answers': answers,
    });
  }

  static void goToCouponEditor(
    BuildContext context, {
    InstructorCouponModel? coupon,
    required Future<bool> Function(Map<String, dynamic>) onSave,
  }) {
    context.pushNamed('coupon-editor', extra: {
      'coupon': coupon,
      'onSave': onSave,
    });
  }

  static void goToEarningsHistory(BuildContext context) {
    context.pushNamed('earnings-history');
  }

  static void goToQuizEditor(
    BuildContext context, {
    required String quizId,
    InstructorQuizModel? quiz,
    required Future<bool> Function(Map<String, dynamic>) onSave,
  }) {
    context.pushNamed('quiz-editor', pathParameters: {
      'quizId': quizId
    }, extra: {
      'quiz': quiz,
      'onSave': onSave,
    });
  }

  static Future<T?> goToCreateQuiz<T>(
    BuildContext context, {
    InstructorQuizzesCubit? cubit,
  }) {
    return context.pushNamed<T>(
      'create-quiz',
      extra: cubit == null ? null : {'cubit': cubit},
    );
  }

  static void goToManageQuizQuestions(
    BuildContext context, {
    required String quizId,
    required InstructorQuizModel quiz,
    required InstructorQuizzesCubit cubit,
  }) {
    context.pushNamed('instructor-quiz-questions', pathParameters: {
      'quizId': quizId
    }, extra: {
      'quiz': quiz,
      'cubit': cubit,
    });
  }

  static void goToQuizPreview(
    BuildContext context, {
    required String quizId,
    required String quizTitle,
    required List<Map<String, dynamic>> questions,
    int? timeLimit,
  }) {
    context.pushNamed('quiz-preview', pathParameters: {
      'quizId': quizId
    }, extra: {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'questions': questions,
      'timeLimit': timeLimit,
    });
  }

  static void goToCategoryEditor(
    BuildContext context, {
    CategoryModel? category,
    required void Function(dynamic) onSave,
  }) {
    context.pushNamed('category-editor', extra: {
      'category': category,
      'onSave': onSave,
    });
  }

  static void goToBannerEditor(
    BuildContext context, {
    BannerModel? banner,
    required Future<void> Function(BannerCreateDto) onSave,
  }) {
    context.pushNamed('banner-editor', extra: {
      'banner': banner,
      'onSave': onSave,
    });
  }

  static void goToStudentProfile(BuildContext context) {
    context.pushNamed('student-profile');
  }

  static void goToStudentsProgressSheet(BuildContext context, {String? courseId, String? courseTitle}) {
    context.pushNamed('students-progress-sheet', extra: {
      'courseId': courseId,
      'courseTitle': courseTitle,
    });
  }

  static void goToInstructor(BuildContext context, String instructorId) {
    context.pushNamed('instructor-profile',
        pathParameters: {'instructorId': instructorId});
  }

  static void pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    context.go('/home');
  }
}

class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page not found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error?.toString() ?? 'Unknown error',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home')),
          ],
        ),
      ),
    );
  }
}
