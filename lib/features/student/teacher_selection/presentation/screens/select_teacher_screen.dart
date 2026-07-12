import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار المدرس')),
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length + (_errorMessage == null ? 1 : 2),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'اختر المدرس الذي تريد متابعة كورساته. يمكنك تغيير المدرس النشط لاحقا من حسابك.',
                  style: theme.textTheme.bodyMedium,
                );
              }

              if (_errorMessage != null && index == 1) {
                return Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }

              final teacherIndex = index - (_errorMessage == null ? 1 : 2);
              final teacher = teachers[teacherIndex];
              final isSaving = _savingTeacherId == teacher.id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: teacher.avatarUrl == null
                        ? null
                        : NetworkImage(teacher.avatarUrl!),
                    child: teacher.avatarUrl == null
                        ? const Icon(Icons.person_rounded)
                        : null,
                  ),
                  title: Text(teacher.name),
                  subtitle: teacher.theme.welcomeText == null
                      ? null
                      : Text(teacher.theme.welcomeText!),
                  trailing: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: isSaving ? null : () => _selectTeacher(teacher),
                ),
              );
            },
          );
        },
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
