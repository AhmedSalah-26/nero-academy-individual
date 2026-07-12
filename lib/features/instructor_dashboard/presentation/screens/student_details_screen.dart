import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/services/direct_chat_service.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/user_avatar.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_student_model.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/widgets/instructor_students/student_details_widgets.dart';

/// Student Details Screen - Full page with all profile fields
class StudentDetailsScreen extends StatelessWidget {
  final InstructorStudentModel student;
  final VoidCallback? onSendMessage;
  final VoidCallback? onViewEnrollments;
  final VoidCallback? onViewProgress;

  const StudentDetailsScreen({
    super.key,
    required this.student,
    this.onSendMessage,
    this.onViewEnrollments,
    this.onViewProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل الطالب' : 'Student Details'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(isDark, isArabic),
            const SizedBox(height: 24),
            _buildStatusBadges(isArabic),
            const SizedBox(height: 24),
            _buildActionButtons(context, isArabic),
            const SizedBox(height: 24),
            _buildStatsRow(isDark, isArabic),
            const SizedBox(height: 24),
            _buildContactSection(isDark, isArabic),
            const SizedBox(height: 24),
            _buildAccountSection(isDark, isArabic, dateFormat),
            const SizedBox(height: 24),
            _buildActivitySection(isDark, isArabic, dateFormat),
            const SizedBox(height: 24),
            if (student.interests.isNotEmpty) ...[
              _buildInterestsSection(isDark, isArabic),
              const SizedBox(height: 24),
            ],
            if (student.isBanned) ...[
              BanInfoSection(
                banReason: student.banReason,
                bannedUntil: student.bannedUntil,
                isDark: isDark,
                isArabic: isArabic,
                formatDate: (date) => dateFormat.format(date),
              ),
              const SizedBox(height: 24),
            ],
            StudentProgressSection(
              progress: student.totalProgress,
              isDark: isDark,
              isArabic: isArabic,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              UserAvatar(
                imageUrl: student.avatarUrl,
                name: student.name,
                size: AvatarSize.xl,
              ),
              if (!student.isActive || student.isBanned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: student.isBanned
                          ? AppColors.error
                          : AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      student.isBanned ? Icons.block : Icons.pause,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getRoleColor(student.role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getRoleColor(student.role).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    getRoleName(student.role, isArabic),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: getRoleColor(student.role),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadges(bool isArabic) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusBadge(
          icon: student.isActive ? Icons.check_circle : Icons.pause_circle,
          label: student.isActive
              ? (isArabic ? 'نشط' : 'Active')
              : (isArabic ? 'غير نشط' : 'Inactive'),
          color: student.isActive ? AppColors.success : AppColors.warning,
        ),
        if (student.isBanned)
          StatusBadge(
            icon: Icons.block,
            label: isArabic ? 'محظور' : 'Banned',
            color: AppColors.error,
          ),
        StatusBadge(
          icon: Icons.school_outlined,
          label:
              '${student.enrolledCoursesCount} ${isArabic ? 'كورس' : 'courses'}',
          color: AppColors.info,
        ),
        if (student.totalWatchTime != null && student.totalWatchTime! > 0)
          StatusBadge(
            icon: Icons.timer_outlined,
            label: student.formattedWatchTime,
            color: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: StudentActionButton(
            icon: Icons.message_outlined,
            label: isArabic ? 'رسالة' : 'Message',
            color: AppColors.primary,
            onTap: () async {
              try {
                final client = Supabase.instance.client;
                final currentUserId = client.auth.currentUser!.id;
                if (currentUserId == student.id) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isArabic
                          ? 'لا يمكنك مراسلة نفسك'
                          : 'You cannot message yourself'),
                    ),
                  );
                  return;
                }
                final conversationId =
                    await DirectChatService.getOrCreateSingleConversation(
                  supabase: client,
                  currentUserId: currentUserId,
                  otherUserId: student.id,
                );
                if (context.mounted) {
                  AppRouter.goToChat(
                    context,
                    conversationId: conversationId,
                    conversationTitle: student.name,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to open chat: $e')),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StudentActionButton(
            icon: Icons.school_outlined,
            label: isArabic ? 'التسجيلات' : 'Enrollments',
            color: AppColors.info,
            onTap: () => onViewEnrollments?.call(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StudentActionButton(
            icon: Icons.analytics_outlined,
            label: isArabic ? 'التقدم' : 'Progress',
            color: AppColors.success,
            onTap: () => onViewProgress?.call(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: StudentStatCard(
            icon: Icons.school_outlined,
            label: isArabic ? 'الكورسات المسجلة' : 'Enrolled',
            value: '${student.enrolledCoursesCount}',
            color: AppColors.info,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StudentStatCard(
            icon: Icons.check_circle_outline,
            label: isArabic ? 'مكتملة' : 'Completed',
            value: '${student.completedCoursesCount ?? 0}',
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StudentStatCard(
            icon: Icons.trending_up_rounded,
            label: isArabic ? 'التقدم' : 'Progress',
            value: '${student.totalProgress.toStringAsFixed(0)}%',
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(bool isDark, bool isArabic) {
    return DetailsSection(
      title: isArabic ? 'معلومات الاتصال' : 'Contact Information',
      icon: Icons.contact_mail_outlined,
      isDark: isDark,
      children: [
        InfoRow(
          icon: Icons.email_outlined,
          label: isArabic ? 'البريد الإلكتروني' : 'Email',
          value: student.email ?? (isArabic ? 'غير محدد' : 'N/A'),
          isDark: isDark,
          isArabic: isArabic,
          copyable: student.email != null,
        ),
        const Divider(height: 20),
        InfoRow(
          icon: Icons.phone_outlined,
          label: isArabic ? 'رقم الهاتف' : 'Phone',
          value: student.phone ?? (isArabic ? 'غير محدد' : 'N/A'),
          isDark: isDark,
          isArabic: isArabic,
          copyable: student.phone != null,
        ),
      ],
    );
  }

  Widget _buildAccountSection(
      bool isDark, bool isArabic, DateFormat dateFormat) {
    return DetailsSection(
      title: isArabic ? 'معلومات الحساب' : 'Account Information',
      icon: Icons.person_outline,
      isDark: isDark,
      children: [
        InfoRow(
          icon: Icons.badge_outlined,
          label: 'ID',
          value: student.id,
          isDark: isDark,
          isArabic: isArabic,
          copyable: true,
        ),
        const Divider(height: 20),
        InfoRow(
          icon: Icons.verified_user_outlined,
          label: isArabic ? 'نوع الحساب' : 'Role',
          value: getRoleName(student.role, isArabic),
          isDark: isDark,
          isArabic: isArabic,
        ),
        const Divider(height: 20),
        InfoRow(
          icon: Icons.calendar_today_outlined,
          label: isArabic ? 'تاريخ الانضمام' : 'Joined',
          value: student.createdAt != null
              ? dateFormat.format(student.createdAt!)
              : (isArabic ? 'غير محدد' : 'N/A'),
          isDark: isDark,
          isArabic: isArabic,
        ),
        const Divider(height: 20),
        InfoRow(
          icon: student.isActive
              ? Icons.check_circle_outline
              : Icons.pause_circle_outline,
          label: isArabic ? 'الحالة' : 'Status',
          value: student.isActive
              ? (isArabic ? 'نشط' : 'Active')
              : (isArabic ? 'غير نشط' : 'Inactive'),
          isDark: isDark,
          isArabic: isArabic,
          valueColor: student.isActive ? AppColors.success : AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildActivitySection(
      bool isDark, bool isArabic, DateFormat dateFormat) {
    return DetailsSection(
      title: isArabic ? 'النشاط' : 'Activity',
      icon: Icons.timeline_outlined,
      isDark: isDark,
      children: [
        InfoRow(
          icon: Icons.login_outlined,
          label: isArabic ? 'أول تسجيل' : 'First Enrolled',
          value: student.firstEnrolledAt != null
              ? dateFormat.format(student.firstEnrolledAt!)
              : (isArabic ? 'غير محدد' : 'N/A'),
          isDark: isDark,
          isArabic: isArabic,
        ),
        const Divider(height: 20),
        InfoRow(
          icon: Icons.history_outlined,
          label: isArabic ? 'آخر نشاط' : 'Last Activity',
          value: student.lastActivityAt != null
              ? dateFormat.format(student.lastActivityAt!)
              : (isArabic ? 'غير محدد' : 'N/A'),
          isDark: isDark,
          isArabic: isArabic,
        ),
        const Divider(height: 20),
        InfoRow(
          icon: Icons.timer_outlined,
          label: isArabic ? 'وقت المشاهدة' : 'Watch Time',
          value: student.formattedWatchTime,
          isDark: isDark,
          isArabic: isArabic,
        ),
        const Divider(height: 20),
        InfoRow(
          icon: Icons.update_outlined,
          label: isArabic ? 'آخر تحديث' : 'Last Updated',
          value: student.updatedAt != null
              ? dateFormat.format(student.updatedAt!)
              : (isArabic ? 'غير محدد' : 'N/A'),
          isDark: isDark,
          isArabic: isArabic,
        ),
      ],
    );
  }

  Widget _buildInterestsSection(bool isDark, bool isArabic) {
    return DetailsSection(
      title: isArabic ? 'الاهتمامات' : 'Interests',
      icon: Icons.interests_outlined,
      isDark: isDark,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              student.interests.map((i) => InterestTag(interest: i)).toList(),
        ),
      ],
    );
  }
}
