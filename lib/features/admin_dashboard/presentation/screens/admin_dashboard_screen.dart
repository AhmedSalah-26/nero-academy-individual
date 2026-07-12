import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_analytics/admin_analytics_content.dart';
import '../widgets/admin_courses/admin_courses_content.dart';
import '../widgets/admin_forum/admin_forum_content.dart';
import '../widgets/admin_home/admin_home_content.dart';
import '../widgets/admin_instructor_requests/admin_instructor_requests_content.dart';
import '../widgets/admin_qa/admin_qa_content.dart';
import '../widgets/admin_reviews/admin_reviews_content.dart';
import '../widgets/admin_users/admin_users_content.dart';

/// Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<DashboardNavItem> _navItems = [
    DashboardNavItem(
      label: 'Dashboard',
      labelAr: '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
      icon: Icons.dashboard_rounded,
    ),
    DashboardNavItem(
      label: 'Users',
      labelAr: '\u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645\u064a\u0646',
      icon: Icons.people_rounded,
    ),
    DashboardNavItem(
      label: 'Courses',
      labelAr: '\u0627\u0644\u0643\u0648\u0631\u0633\u0627\u062a',
      icon: Icons.school_rounded,
    ),
    DashboardNavItem(
      label: 'Reviews',
      labelAr: '\u0627\u0644\u062a\u0642\u064a\u064a\u0645\u0627\u062a',
      icon: Icons.star_rounded,
    ),
    DashboardNavItem(
      label: 'Q&A',
      labelAr: '\u0627\u0644\u0623\u0633\u0626\u0644\u0629',
      icon: Icons.question_answer_rounded,
    ),
    DashboardNavItem(
      label: 'Forums',
      labelAr: '\u0627\u0644\u0645\u0646\u062a\u062f\u064a\u0627\u062a',
      icon: Icons.forum_rounded,
    ),
    DashboardNavItem(
      label: 'Analytics',
      labelAr: '\u0627\u0644\u062a\u062d\u0644\u064a\u0644\u0627\u062a',
      icon: Icons.analytics_rounded,
    ),
    DashboardNavItem(
      label: 'Instructor Requests',
      labelAr:
          '\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u062f\u0631\u0633\u064a\u0646',
      icon: Icons.assignment_turned_in_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().loadAll();
  }

  Widget _buildContent() {
    return switch (_selectedIndex) {
      0 => AdminHomeContent(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        ),
      1 => const AdminUsersContent(),
      2 => const AdminCoursesContent(),
      3 => const AdminReviewsContent(),
      4 => const AdminQAContent(),
      5 => const AdminForumContent(),
      6 => const AdminAnalyticsContent(),
      7 => const AdminInstructorRequestsContent(),
      _ => const AdminHomeContent(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Admin Dashboard',
      titleAr:
          '\u0644\u0648\u062d\u0629 \u062a\u062d\u0643\u0645 \u0627\u0644\u0623\u062f\u0645\u0646',
      navItems: _navItems,
      selectedIndex: _selectedIndex,
      onNavItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      content: _buildContent(),
    );
  }
}
