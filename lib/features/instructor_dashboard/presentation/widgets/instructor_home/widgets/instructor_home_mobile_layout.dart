import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../domain/entities/instructor_entities.dart';
import '../../../cubit/instructor_dashboard_cubit.dart';

class InstructorHomeMobileLayout extends StatelessWidget {
  final InstructorDashboardState state;
  final bool isArabic;
  final Future<void> Function() onRefresh;
  final ValueChanged<int>? onNavigate;

  const InstructorHomeMobileLayout({
    super.key,
    required this.state,
    required this.isArabic,
    required this.onRefresh,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = state.stats;
    final authUser = sl<AuthCubit>().state.user;
    final supabaseUser = Supabase.instance.client.auth.currentUser;

    final fallbackName = isArabic ? 'المدرس' : 'Instructor';
    final rawName = authUser?.name ??
        supabaseUser?.userMetadata?['name']?.toString() ??
        supabaseUser?.email?.split('@').first;

    final avatarUrl = authUser?.avatarUrl ??
        supabaseUser?.userMetadata?['avatar_url']?.toString();

    final topGradient = isDark
        ? const [Color(0xFF2D2438), Color(0xFF191022)]
        : const [AppColors.primaryDark, AppColors.primary];

    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textMain = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: topGradient,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withValues(alpha: isDark ? 0.14 : 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _DashboardAvatar(
                        primaryAvatarUrl: avatarUrl,
                        borderColor: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'مرحبًا 👋' : 'Welcome 👋',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _DashboardDisplayName(
                              primaryName: rawName,
                              fallbackName: fallbackName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTopRating(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPrimaryAction(
                          label: isArabic ? 'كورساتي' : 'My Courses',
                          icon: Icons.school_rounded,
                          onTap: () => _navigateTo(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPrimaryAction(
                          label: isArabic ? 'التسجيلات' : 'Enrollments',
                          icon: Icons.assignment_ind_rounded,
                          onTap: () => _navigateTo(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
              child: _buildQuickActions(
                surface: surface,
                border: border,
                textMain: textMain,
                textMuted: textMuted,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSectionTitle(
                title: isArabic ? 'نظرة عامة' : 'Overview',
                textColor: textMain,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: state.isLoading
                  ? const StatsGrid(isLoading: true, stats: [])
                  : StatsGrid(stats: _buildLegacyStatsData(stats)),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSectionTitle(
                title: isArabic ? 'تحليلات التسجيل' : 'Enrollment Analytics',
                textColor: textMain,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: _buildAnalyticsCard(
                stats: stats,
                surface: surface,
                border: border,
                textMain: textMain,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<StatsCardData> _buildLegacyStatsData(InstructorDashboardStats stats) {
    return [
      StatsCardData(
        title: isArabic ? 'إجمالي الكورسات' : 'Total Courses',
        value: stats.totalCourses.toString(),
        icon: Icons.school_rounded,
        color: AppColors.primary,
        onTap: () => _navigateTo(1),
      ),
      StatsCardData(
        title: isArabic ? 'إجمالي الطلاب' : 'Total Students',
        value: stats.totalStudents.toString(),
        icon: Icons.people_rounded,
        color: AppColors.info,
        onTap: () => _navigateTo(2),
      ),
      StatsCardData(
        title: isArabic ? 'إجمالي الأرباح' : 'Total Earnings',
        value:
            '${stats.totalEarnings.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
        icon: Icons.attach_money_rounded,
        color: AppColors.success,
        onTap: () => _navigateTo(6), // Earnings = index 6
      ),
      StatsCardData(
        title: isArabic ? 'متوسط التقييم' : 'Average Rating',
        value: stats.averageRating.toStringAsFixed(1),
        icon: Icons.star_rounded,
        color: AppColors.warning,
        onTap: () => _navigateTo(10), // Reviews = index 10
      ),
      StatsCardData(
        title: isArabic ? 'الرصيد المتاح' : 'Available Balance',
        value:
            '${stats.availableBalance.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.warning,
        onTap: () => _navigateTo(6), // Earnings = index 6
      ),
      StatsCardData(
        title: isArabic ? 'أسئلة بدون إجابة' : 'Unanswered Q&A',
        value: stats.unansweredQuestions.toString(),
        icon: Icons.question_answer_rounded,
        color: AppColors.error,
        onTap: () => _navigateTo(9), // Q&A = index 9
      ),
    ];
  }

  Widget _buildTopRating() {
    final reviews = state.stats.totalReviews;
    final rating = state.stats.averageRating;
    return Row(
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, color: AppColors.ratingLight, size: 19),
        const SizedBox(width: 6),
        Text(
          '($reviews)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return FilledButton.icon(
      onPressed: onNavigate == null ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildQuickActions({
    required Color surface,
    required Color border,
    required Color textMain,
    required Color textMuted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _quickActionChip(
            label: isArabic ? 'الكوبونات' : 'Coupons',
            icon: Icons.local_offer_rounded,
            color: Colors.teal,
            onTap: () => _navigateTo(7), // Coupons = index 7
            textColor: textMain,
            bgColor: surface,
          ),
          _quickActionChip(
            label: isArabic ? 'الطلاب' : 'Students',
            icon: Icons.groups_rounded,
            color: AppColors.info,
            onTap: () => _navigateTo(2), // Students = index 2
            textColor: textMain,
            bgColor: surface,
          ),
          _quickActionChip(
            label: isArabic ? 'الأرباح' : 'Earnings',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
            onTap: () => _navigateTo(6), // Earnings = index 6
            textColor: textMain,
            bgColor: surface,
          ),
          _quickActionChip(
            label: isArabic ? 'الأسئلة' : 'Q&A',
            icon: Icons.question_answer_rounded,
            color: AppColors.error,
            onTap: () => _navigateTo(9), // Q&A = index 9
            textColor: textMain,
            bgColor: surface,
          ),
          _quickActionChip(
            label: isArabic ? 'التقييمات' : 'Reviews',
            icon: Icons.star_rounded,
            color: AppColors.warning,
            onTap: () => _navigateTo(10), // Reviews = index 10
            textColor: textMain,
            bgColor: surface,
          ),
          _quickActionChip(
            label: isArabic ? 'المنتديات' : 'Forums',
            icon: Icons.forum_rounded,
            color: AppColors.primary,
            onTap: () => _navigateTo(3), // Forums = index 3
            textColor: textMain,
            bgColor: surface,
          ),
          _quickActionChip(
            label: isArabic ? 'الاختبارات' : 'Quizzes',
            icon: Icons.quiz_rounded,
            color: AppColors.primaryDark,
            onTap: () => _navigateTo(8), // Quizzes = index 8
            textColor: textMain,
            bgColor: surface,
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color textColor,
    required Color bgColor,
  }) {
    return ActionChip(
      onPressed: onNavigate == null ? null : onTap,
      avatar: Icon(icon, size: 18, color: color),
      backgroundColor: bgColor,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      label: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required Color textColor,
  }) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required InstructorDashboardStats stats,
    required Color surface,
    required Color border,
    required Color textMain,
    required Color textMuted,
  }) {
    final totalEnrollments = stats.totalEnrollments.toDouble();
    final totalStudents = stats.totalStudents.toDouble();
    final enrollmentProgress = totalStudents > 0
        ? (totalEnrollments / (totalStudents * 2)).clamp(0.0, 1.0)
        : 0.0;

    final averageRating = stats.averageRating;
    final ratingProgress = (averageRating / 5.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _buildAnalyticsItem(
            label: isArabic ? 'عدد الطلاب' : 'Total Students',
            value: stats.totalStudents.toString(),
            progress: enrollmentProgress,
            color: AppColors.primary,
            textMain: textMain,
            textMuted: textMuted,
          ),
          const SizedBox(height: 14),
          _buildAnalyticsItem(
            label: isArabic ? 'متوسط التقييم' : 'Average Rating',
            value: averageRating.toStringAsFixed(1),
            progress: ratingProgress,
            color: AppColors.warning,
            textMain: textMain,
            textMuted: textMuted,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate == null ? null : () => _navigateTo(4),
                  icon: const Icon(Icons.assignment_ind_rounded, size: 18),
                  label: Text(isArabic ? 'التسجيلات' : 'Enrollments'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate == null ? null : () => _navigateTo(6), // Earnings = index 6
                  icon: const Icon(Icons.paid_rounded, size: 18),
                  label: Text(isArabic ? 'الأرباح' : 'Earnings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem({
    required String label,
    required String value,
    required double progress,
    required Color color,
    required Color textMain,
    required Color textMuted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: textMain,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: AppColors.grey200,
          ),
        ),
      ],
    );
  }

  void _navigateTo(int index) {
    if (onNavigate != null) {
      onNavigate!(index);
    }
  }
}

class _DashboardDisplayName extends StatefulWidget {
  final String? primaryName;
  final String fallbackName;
  final TextStyle style;

  const _DashboardDisplayName({
    required this.primaryName,
    required this.fallbackName,
    required this.style,
  });

  @override
  State<_DashboardDisplayName> createState() => _DashboardDisplayNameState();
}

class _DashboardDisplayNameState extends State<_DashboardDisplayName> {
  String? _resolvedName;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _resolvedName = _sanitize(widget.primaryName) ?? widget.fallbackName;
    _resolveBestName();
  }

  @override
  void didUpdateWidget(covariant _DashboardDisplayName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryName != widget.primaryName ||
        oldWidget.fallbackName != widget.fallbackName) {
      _resolvedName = _sanitize(widget.primaryName) ?? widget.fallbackName;
      _resolveBestName();
    }
  }

  String? _sanitize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _resolveBestName() async {
    if (_isResolving) return;
    _isResolving = true;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final teacher = await Supabase.instance.client
          .from('teachers')
          .select('display_name')
          .eq('profile_id', userId)
          .maybeSingle();
      final instructorDisplayName =
          _sanitize(teacher?['display_name'] as String?);
      if (instructorDisplayName != null) {
        if (!mounted) return;
        setState(() => _resolvedName = instructorDisplayName);
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      final profileName = _sanitize(profile?['name'] as String?);
      if (profileName != null && mounted) {
        setState(() => _resolvedName = profileName);
      }
    } catch (_) {
      // Keep best known local name.
    } finally {
      _isResolving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _resolvedName ?? widget.fallbackName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}

class _DashboardAvatar extends StatefulWidget {
  final String? primaryAvatarUrl;
  final Color borderColor;

  const _DashboardAvatar({
    required this.primaryAvatarUrl,
    required this.borderColor,
  });

  @override
  State<_DashboardAvatar> createState() => _DashboardAvatarState();
}

class _DashboardAvatarState extends State<_DashboardAvatar> {
  String? _resolvedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _resolvedAvatarUrl = _sanitize(widget.primaryAvatarUrl);
    if (_resolvedAvatarUrl == null) {
      _loadFallbackAvatar();
    }
  }

  @override
  void didUpdateWidget(covariant _DashboardAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPrimary = _sanitize(widget.primaryAvatarUrl);
    if (nextPrimary != _resolvedAvatarUrl) {
      _resolvedAvatarUrl = nextPrimary;
      if (_resolvedAvatarUrl == null) {
        _loadFallbackAvatar();
      }
    }
  }

  String? _sanitize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _loadFallbackAvatar() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final profileAvatar = _sanitize(profile?['avatar_url'] as String?);
      if (profileAvatar != null) {
        if (!mounted) return;
        setState(() => _resolvedAvatarUrl = profileAvatar);
        return;
      }

      final teacher = await Supabase.instance.client
          .from('teachers')
          .select('avatar_url')
          .eq('profile_id', userId)
          .maybeSingle();

      final instructorAvatar =
          _sanitize(teacher?['avatar_url'] as String?);
      if (instructorAvatar != null) {
        if (!mounted) return;
        setState(() => _resolvedAvatarUrl = instructorAvatar);
        return;
      }
    } catch (_) {
      // Keep placeholder avatar if profile image lookup fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = _resolvedAvatarUrl != null;
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.borderColor, width: 2),
      ),
      child: CircleAvatar(
        radius: 33,
        backgroundColor: AppColors.grey200,
        backgroundImage: hasAvatar ? NetworkImage(_resolvedAvatarUrl!) : null,
        child: hasAvatar
            ? null
            : const Icon(Icons.person_rounded, color: AppColors.grey600),
      ),
    );
  }
}
