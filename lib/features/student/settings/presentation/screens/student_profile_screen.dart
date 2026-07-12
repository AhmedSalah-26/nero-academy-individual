// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/features/student/settings/presentation/widgets/student_profile_widgets.dart';
import 'package:lms_platform/features/student/settings/presentation/widgets/student_profile_tabs.dart';

/// Student Profile Screen - Full learning overview accessible from Settings
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _enrollments = [];
  List<Map<String, dynamic>> _quizAttempts = [];
  int _totalLessons = 0;
  int _completedLessons = 0;
  int _watchSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Profile (required - if this fails, show error)
      final profileRes = await client
          .from('profiles')
          .select('id, name, email, avatar_url, created_at, role')
          .eq('id', userId)
          .single();
      final profile = profileRes;

      // Enrollments (optional - simplified query without nested courses join)
      List<Map<String, dynamic>> enrollments = [];
      try {
        final enrollmentsRes = await client.from('enrollments').select('''
          id, enrolled_at, last_accessed_at, completed_at,
          progress_percentage, status, course_id, total_watch_time
        ''').eq('user_id', userId).order('enrolled_at', ascending: false);
        enrollments = (enrollmentsRes as List).cast<Map<String, dynamic>>();

        // Try to enrich enrollments with course data separately
        if (enrollments.isNotEmpty) {
          final courseIds = enrollments.map((e) => e['course_id']).toList();
          try {
            final coursesRes = await client
                .from('courses')
                .select('id, title_ar, title_en, thumbnail_url, total_lessons')
                .inFilter('id', courseIds);
            final courseMap = <String, Map<String, dynamic>>{};
            for (final c in (coursesRes as List)) {
              courseMap[c['id'] as String] = c as Map<String, dynamic>;
            }
            enrollments = enrollments.map((e) {
              return {
                ...e,
                'courses': courseMap[e['course_id'] as String] ?? {}
              };
            }).toList();
          } catch (_) {
            // Add empty courses to avoid null issues
            enrollments = enrollments
                .map((e) => {...e, 'courses': <String, dynamic>{}})
                .toList();
          }
        }
      } catch (_) {
        // Enrollments are optional
      }

      // Quiz attempts (optional)
      List<Map<String, dynamic>> quizAttempts = [];
      try {
        final quizRes = await client.from('quiz_attempts').select('''
          id, score, percentage, passed, started_at, completed_at, time_spent,
          quizzes(title_ar, title_en, courses(title_ar, title_en))
        ''').eq('user_id', userId).order('completed_at', ascending: false);
        quizAttempts = (quizRes as List).cast<Map<String, dynamic>>();
      } catch (_) {
        // Quiz attempts are optional
      }

      int totalL = 0, completedL = 0, watchSec = 0;
      for (final e in enrollments) {
        final total = ((e['courses'] as Map?)?['total_lessons'] as int?) ?? 0;
        final prog = (e['progress_percentage'] as num?)?.toDouble() ?? 0;
        totalL += total;
        completedL += (total * prog / 100).round();
        watchSec += (e['total_watch_time'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _enrollments = enrollments;
          _quizAttempts = quizAttempts;
          _totalLessons = totalL;
          _completedLessons = completedL;
          _watchSeconds = watchSec;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: _isLoading
          ? const AppLoadingState()
          : _error != null
              ? ErrorState(
                  type: ErrorType.generic, message: _error!, onRetry: _loadData)
              : NestedScrollView(
                  headerSliverBuilder: (_, __) => [
                    StudentProfileSliverHeader(
                      profile: _profile,
                      tabController: _tabController,
                      isDark: isDark,
                      isArabic: isArabic,
                      onBack: () => Navigator.pop(context),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      StudentOverviewTab(
                        enrollments: _enrollments,
                        quizAttempts: _quizAttempts,
                        totalLessons: _totalLessons,
                        completedLessons: _completedLessons,
                        watchSeconds: _watchSeconds,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      StudentCoursesTab(
                        enrollments: _enrollments,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                      StudentQuizzesTab(
                        quizAttempts: _quizAttempts,
                        isDark: isDark,
                        isArabic: isArabic,
                      ),
                    ],
                  ),
                ),
    );
  }
}
