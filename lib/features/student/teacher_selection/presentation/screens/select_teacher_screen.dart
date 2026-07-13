import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/teacher_context_service.dart';

class SelectTeacherScreen extends StatefulWidget {
  const SelectTeacherScreen({super.key});

  @override
  State<SelectTeacherScreen> createState() => _SelectTeacherScreenState();
}

class _SelectTeacherScreenState extends State<SelectTeacherScreen> {
  late Future<List<SelectedTeacher>> _teachersFuture;
  String? _savingTeacherId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _teachersFuture = TeacherContextService.instance.getAvailableTeachers();
  }

  Future<void> _selectTeacher(SelectedTeacher teacher) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      context.go('/login');
      return;
    }

    setState(() {
      _savingTeacherId = teacher.id;
      _errorMessage = null;
    });

    try {
      await TeacherContextService.instance.selectTeacher(
        studentId: userId,
        teacher: teacher,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingTeacherId = null;
        _errorMessage = 'تعذر اختيار المدرس. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('اختيار المدرس'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<SelectedTeacher>>(
        future: _teachersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageState(
              title: 'تعذر تحميل المدرسين',
              message: 'راجع اتصالك بالإنترنت ثم حاول مرة أخرى.',
              actionLabel: 'إعادة المحاولة',
              onAction: () {
                setState(() {
                  _teachersFuture =
                      TeacherContextService.instance.getAvailableTeachers();
                });
              },
            );
          }

          final teachers = snapshot.data ?? const <SelectedTeacher>[];
          if (teachers.isEmpty) {
            return const _MessageState(
              title: 'لا يوجد مدرسون متاحون',
              message: 'سيظهر المدرسون هنا بعد تفعيلهم من لوحة الأدمن.',
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'اختر المدرس الذي تريد متابعة كورساته. يمكنك تغيير المدرس النشط لاحقا من حسابك.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverGrid.builder(
                  itemCount: teachers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    final isSaving = _savingTeacherId == teacher.id;

                    return _TeacherChoiceCard(
                      teacher: teacher,
                      isSaving: isSaving,
                      isDark: isDark,
                      onTap: isSaving ? null : () => _selectTeacher(teacher),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherChoiceCard extends StatelessWidget {
  final SelectedTeacher teacher;
  final bool isSaving;
  final bool isDark;
  final VoidCallback? onTap;

  const _TeacherChoiceCard({
    required this.teacher,
    required this.isSaving,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = teacher.theme.primaryFor(isDark) ??
        Theme.of(context).colorScheme.primary;
    final cardColor = teacher.theme.cardFor(isDark) ??
        (isDark ? AppColors.cardDark : AppColors.white);
    final logoUrl = teacher.theme.logoFor(isDark) ?? teacher.avatarUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.14 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  color: primary.withValues(alpha: 0.12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (logoUrl != null && logoUrl.trim().isNotEmpty)
                        Image.network(
                          logoUrl.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _TeacherPlaceholder(color: primary),
                        )
                      else
                        _TeacherPlaceholder(color: primary),
                      if (isSaving)
                        Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              teacher.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherPlaceholder extends StatelessWidget {
  final Color color;

  const _TeacherPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_rounded,
          color: color,
          size: 34,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
