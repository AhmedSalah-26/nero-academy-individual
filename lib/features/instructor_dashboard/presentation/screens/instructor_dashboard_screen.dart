import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/features/student/course_forum/presentation/screens/forums_list_screen.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_dashboard_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_home/instructor_home_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_courses/instructor_courses_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_students/instructor_students_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_enrollments/instructor_enrollments_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_earnings/instructor_earnings_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_qa/instructor_qa_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_reviews/instructor_reviews_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_coupons/instructor_coupons_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_quizzes/instructor_quizzes_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_settings/instructor_settings_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_settings/teacher_theme_settings_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_categories/instructor_categories_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_banners/instructor_banners_content.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_reports/instructor_reports_content.dart';
import 'manual_purchase_requests_screen.dart';

/// Instructor Dashboard Screen
class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  int _selectedIndex = 0;

  static const List<DashboardNavItem> _navItems = [
    DashboardNavItem(
      label: 'Dashboard',
      labelAr: 'الرئيسية',
      icon: Icons.dashboard_rounded,
    ),
    DashboardNavItem(
      label: 'My Courses',
      labelAr: 'كورساتي',
      icon: Icons.school_rounded,
    ),
    DashboardNavItem(
      label: 'Students',
      labelAr: 'الطلاب',
      icon: Icons.people_rounded,
    ),
    DashboardNavItem(
      label: 'Forums',
      labelAr: 'المنتديات',
      icon: Icons.forum_rounded,
    ),
    DashboardNavItem(
      label: 'Enrollments',
      labelAr: 'التسجيلات',
      icon: Icons.assignment_ind_rounded,
    ),
    DashboardNavItem(
      label: 'Purchase Requests',
      labelAr: 'طلبات الشراء',
      icon: Icons.fact_check_rounded,
    ),
    DashboardNavItem(
      label: 'Earnings',
      labelAr: 'الأرباح',
      icon: Icons.attach_money_rounded,
    ),
    DashboardNavItem(
      label: 'Coupons',
      labelAr: 'الكوبونات',
      icon: Icons.local_offer_rounded,
    ),
    DashboardNavItem(
      label: 'Quizzes',
      labelAr: 'الاختبارات',
      icon: Icons.quiz_rounded,
    ),
    DashboardNavItem(
      label: 'Q&A',
      labelAr: 'الأسئلة',
      icon: Icons.question_answer_rounded,
    ),
    DashboardNavItem(
      label: 'Reviews',
      labelAr: 'التقييمات',
      icon: Icons.star_rounded,
    ),
    DashboardNavItem(
      label: 'Reports',
      labelAr: 'البلاغات',
      icon: Icons.flag_rounded,
    ),
    DashboardNavItem(
      label: 'Categories',
      labelAr: 'التصنيفات',
      icon: Icons.category_rounded,
    ),
    DashboardNavItem(
      label: 'Banners',
      labelAr: 'البانرات',
      icon: Icons.image_rounded,
    ),
    DashboardNavItem(
      label: 'Theme',
      labelAr: 'الثيم',
      icon: Icons.palette_rounded,
    ),
    DashboardNavItem(
      label: 'Settings',
      labelAr: 'الإعدادات',
      icon: Icons.settings_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    context.read<InstructorDashboardCubit>().loadAll();
  }

  Widget _buildContent() {
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = InstructorHomeContent(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
        break;
      case 1:
        content = const InstructorCoursesContent();
        break;
      case 2:
        content = const InstructorStudentsContent();
        break;
      case 3:
        content = const ForumsListScreen();
        break;
      case 4:
        content = const InstructorEnrollmentsContent();
        break;
      case 5:
        content = const ManualPurchaseRequestsScreen();
        break;
      case 6:
        content = const InstructorEarningsContent();
        break;
      case 7:
        content = const InstructorCouponsContent();
        break;
      case 8:
        content = const InstructorQuizzesContent();
        break;
      case 9:
        content = const InstructorQAContent();
        break;
      case 10:
        content = const InstructorReviewsContent();
        break;
      case 11:
        content = const InstructorReportsContent();
        break;
      case 12:
        content = const InstructorCategoriesContent();
        break;
      case 13:
        content = const InstructorBannersContent();
        break;
      case 14:
        content = const TeacherThemeSettingsContent();
        break;
      case 15:
        content = const InstructorSettingsContent();
        break;
      default:
        content = const InstructorHomeContent();
    }

    return FadeIn(
      key: ValueKey(_selectedIndex),
      duration: const Duration(milliseconds: 300),
      child: content,
    );
  }

  String _getCurrentPageTitle(bool isArabic) {
    final item = _navItems[_selectedIndex];
    return isArabic ? item.labelAr : item.label;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: _getCurrentPageTitle(false),
      titleAr: _getCurrentPageTitle(true),
      navItems: _navItems,
      selectedIndex: _selectedIndex,
      onNavItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      content: _buildContent(),
    );
  }
}
