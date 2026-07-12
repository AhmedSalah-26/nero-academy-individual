import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/animations/animations.dart';
import '../../../../../core/theme/app_colors.dart';

class TeacherThemeSettingsContent extends StatefulWidget {
  const TeacherThemeSettingsContent({super.key});

  @override
  State<TeacherThemeSettingsContent> createState() =>
      _TeacherThemeSettingsContentState();
}

class _TeacherThemeSettingsContentState
    extends State<TeacherThemeSettingsContent> {
  static const _defaultPrimary = '#20E5DC';
  static const _defaultSecondary = '#117CFF';
  static const _defaultBackground = '#01060B';

  final _client = Supabase.instance.client;
  final _primaryController = TextEditingController(text: _defaultPrimary);
  final _secondaryController = TextEditingController(text: _defaultSecondary);
  final _backgroundController = TextEditingController(text: _defaultBackground);
  final _logoController = TextEditingController();
  final _welcomeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _teacherId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _backgroundController.dispose();
    _logoController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('No active user');

      final teacher = await _client
          .from('teachers')
          .select('id, teacher_themes(*)')
          .eq('profile_id', userId)
          .maybeSingle();

      if (teacher == null) throw Exception('Teacher profile was not found');

      _teacherId = teacher['id'] as String;
      final themeData = _firstMap(teacher['teacher_themes']);
      if (themeData != null) {
        _primaryController.text =
            themeData['primary_color'] as String? ?? _defaultPrimary;
        _secondaryController.text =
            themeData['secondary_color'] as String? ?? _defaultSecondary;
        _backgroundController.text =
            themeData['background_color'] as String? ?? _defaultBackground;
        _logoController.text = themeData['logo_url'] as String? ?? '';
        _welcomeController.text = themeData['welcome_text'] as String? ?? '';
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveTheme() async {
    final teacherId = _teacherId;
    if (teacherId == null) return;

    setState(() => _isSaving = true);
    try {
      await _client.from('teacher_themes').upsert({
        'teacher_id': teacherId,
        'primary_color': _normalizeColor(_primaryController.text),
        'secondary_color': _normalizeColor(_secondaryController.text),
        'background_color': _normalizeColor(_backgroundController.text),
        'logo_url': _emptyToNull(_logoController.text),
        'welcome_text': _emptyToNull(_welcomeController.text),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'teacher_id');

      if (!mounted) return;
      AnimatedSnackbar.showSuccess(context: context, message: 'تم حفظ الثيم');
    } catch (_) {
      if (!mounted) return;
      AnimatedSnackbar.showError(context: context, message: 'تعذر حفظ الثيم');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTheme,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('هوية المدرس', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'هذه الإعدادات تتحكم في ألوان تطبيق الطالب بعد اختيار هذا المدرس.',
          style: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 16),
        _ThemePreview(
          primary: _parseColor(_primaryController.text),
          secondary: _parseColor(_secondaryController.text),
          background: _parseColor(_backgroundController.text),
        ),
        const SizedBox(height: 16),
        _Field(controller: _primaryController, label: 'اللون الأساسي'),
        _Field(controller: _secondaryController, label: 'اللون الثانوي'),
        _Field(controller: _backgroundController, label: 'لون الخلفية'),
        _Field(controller: _logoController, label: 'رابط الشعار'),
        _Field(
          controller: _welcomeController,
          label: 'نص الترحيب',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveTheme,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('حفظ الثيم'),
        ),
      ],
    );
  }

  static Map<String, dynamic>? _firstMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  static String _normalizeColor(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('#') ? trimmed : '#$trimmed';
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Color _parseColor(String value) {
    final normalized = value.replaceAll('#', '').trim();
    final parsed = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    return parsed == null ? AppColors.primary : Color(parsed);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color background;

  const _ThemePreview({
    required this.primary,
    required this.secondary,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 12, width: 150, color: primary),
                const SizedBox(height: 8),
                Container(height: 10, width: 100, color: secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
