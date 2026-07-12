import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectedTeacher {
  final String id;
  final String name;
  final String? avatarUrl;
  final TeacherThemeConfig theme;

  const SelectedTeacher({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.theme = const TeacherThemeConfig(),
  });

  factory SelectedTeacher.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final theme = _firstMap(json['teacher_themes']);

    return SelectedTeacher(
      id: json['id'] as String,
      name: (json['display_name'] as String?) ??
          (profile?['name'] as String?) ??
          'مدرس',
      avatarUrl: (json['avatar_url'] as String?) ??
          (profile?['avatar_url'] as String?),
      theme: TeacherThemeConfig.fromJson(theme ?? json),
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
}

class TeacherThemeConfig {
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? backgroundColor;
  final String? logoUrl;
  final String? welcomeText;

  const TeacherThemeConfig({
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.logoUrl,
    this.welcomeText,
  });

  factory TeacherThemeConfig.fromJson(Map<String, dynamic> json) {
    return TeacherThemeConfig(
      primaryColor: _parseColor(json['primary_color'] as String?),
      secondaryColor: _parseColor(json['secondary_color'] as String?),
      backgroundColor: _parseColor(json['background_color'] as String?),
      logoUrl: json['logo_url'] as String?,
      welcomeText: json['welcome_text'] as String?,
    );
  }

  bool get hasColors =>
      primaryColor != null || secondaryColor != null || backgroundColor != null;

  static Color? _parseColor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.replaceAll('#', '').trim();
    if (normalized.length != 6 && normalized.length != 8) return null;
    final colorValue = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    return colorValue == null ? null : Color(colorValue);
  }
}

class TeacherContextService {
  TeacherContextService._();

  static final TeacherContextService instance = TeacherContextService._();

  static const _selectedTeacherIdKey = 'nasaq_selected_teacher_id';
  static const _selectedTeacherNameKey = 'nasaq_selected_teacher_name';

  final ValueNotifier<SelectedTeacher?> selectedTeacher = ValueNotifier(null);

  SupabaseClient? _client;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init(SupabaseClient client) async {
    if (_isInitialized) return;
    _client = client;
    _prefs = await SharedPreferences.getInstance();
    _restoreCachedTeacher();
    _isInitialized = true;
  }

  Future<void> ensureInitialized(SupabaseClient client) => init(client);

  String? get selectedTeacherId => selectedTeacher.value?.id;

  bool hasCachedTeacher() {
    return _prefs?.getString(_selectedTeacherIdKey) != null;
  }

  Future<bool> hasSelectedTeacher(String studentId) async {
    if (selectedTeacher.value != null || hasCachedTeacher()) return true;

    final client = _client;
    if (client == null) return false;

    try {
      final response = await client
          .from('student_teacher_links')
          .select('teachers(id, display_name, avatar_url, teacher_themes(*))')
          .eq('student_id', studentId)
          .eq('is_active', true)
          .maybeSingle();

      final teacher = response?['teachers'] as Map<String, dynamic>?;
      if (teacher == null) return false;

      await _setSelectedTeacher(SelectedTeacher.fromJson(teacher));
      return true;
    } catch (_) {
      return hasCachedTeacher();
    }
  }

  Future<List<SelectedTeacher>> getAvailableTeachers() async {
    final client = _requireClient();
    final response = await client
        .from('teachers')
        .select(
            'id, display_name, avatar_url, profiles(name, avatar_url), teacher_themes(*)')
        .eq('is_active', true)
        .order('display_name', ascending: true);

    return (response as List)
        .map((json) => SelectedTeacher.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> selectTeacher({
    required String studentId,
    required SelectedTeacher teacher,
  }) async {
    final client = _requireClient();

    await client
        .from('student_teacher_links')
        .update({'is_active': false}).eq('student_id', studentId);

    await client.from('student_teacher_links').upsert({
      'student_id': studentId,
      'teacher_id': teacher.id,
      'is_active': true,
      'selected_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id,teacher_id');

    await client
        .from('profiles')
        .update({'active_teacher_id': teacher.id}).eq('id', studentId);

    await _setSelectedTeacher(teacher);
  }

  Future<void> clear() async {
    selectedTeacher.value = null;
    await _prefs?.remove(_selectedTeacherIdKey);
    await _prefs?.remove(_selectedTeacherNameKey);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('TeacherContextService is not initialized');
    }
    return client;
  }

  void _restoreCachedTeacher() {
    final id = _prefs?.getString(_selectedTeacherIdKey);
    if (id == null) return;
    selectedTeacher.value = SelectedTeacher(
      id: id,
      name: _prefs?.getString(_selectedTeacherNameKey) ?? 'مدرس',
    );
  }

  Future<void> _setSelectedTeacher(SelectedTeacher teacher) async {
    selectedTeacher.value = teacher;
    await _prefs?.setString(_selectedTeacherIdKey, teacher.id);
    await _prefs?.setString(_selectedTeacherNameKey, teacher.name);
  }
}
