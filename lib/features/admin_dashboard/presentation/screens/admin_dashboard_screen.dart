import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_analytics/admin_analytics_content.dart';
import '../widgets/admin_courses/admin_courses_content.dart';
import '../widgets/admin_home/admin_home_content.dart';
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
      label: 'Analytics',
      labelAr: '\u0627\u0644\u062a\u062d\u0644\u064a\u0644\u0627\u062a',
      icon: Icons.analytics_rounded,
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
      3 => const AdminAnalyticsContent(),
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
