// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/loading_state.dart';
import '../../../../core/shared_widgets/error_state.dart';
import '../widgets/student_profile_widgets.dart';
import '../widgets/student_profile_tabs.dart';

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

      final results = await Future.wait([
        client.from('profiles').select('*').eq('id', userId).single(),
        client.from('enrollments').select('''
          id, enrolled_at, last_accessed_at, completed_at,
          progress_percentage, status,
          courses!inner(id, title_ar, title_en, thumbnail_url, total_lessons)
        ''').eq('user_id', userId).order('enrolled_at', ascending: false),
        client.from('quiz_attempts').select('''
          id, score, passed, started_at, completed_at, time_spent,
          quizzes!inner(id, title_ar, title_en, courses(title_ar, title_en))
        ''').eq('user_id', userId).order('completed_at', ascending: false),
      ]);

      final enrollments = (results[1] as List).cast<Map<String, dynamic>>();
      int totalL = 0, completedL = 0;
      for (final e in enrollments) {
        final total = ((e['courses'] as Map?)?['total_lessons'] as int?) ?? 0;
        final prog = (e['progress_percentage'] as num?)?.toDouble() ?? 0;
        totalL += total;
        completedL += (total * prog / 100).round();
      }

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _enrollments = enrollments;
          _quizAttempts = (results[2] as List).cast<Map<String, dynamic>>();
          _totalLessons = totalL;
          _completedLessons = completedL;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[StudentProfileScreen] Failed to load student profile data',
        e,
        stackTrace,
      );
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
                        watchSeconds:
                            _profile?['total_watch_time'] as int? ?? 0,
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
