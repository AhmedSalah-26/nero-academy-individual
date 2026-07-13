import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': name,
      'avatar_url': avatarUrl,
      ...theme.toJson(),
    };
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
  final Color? lightPrimaryColor;
  final Color? lightSecondaryColor;
  final Color? lightBackgroundColor;
  final Color? lightButtonColor;
  final Color? lightCardColor;
  final Color? darkPrimaryColor;
  final Color? darkSecondaryColor;
  final Color? darkBackgroundColor;
  final Color? darkButtonColor;
  final Color? darkCardColor;
  final String? logoUrl;
  final String? lightLogoUrl;
  final String? darkLogoUrl;
  final String? lightCoverUrl;
  final String? darkCoverUrl;
  final String? welcomeText;

  const TeacherThemeConfig({
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.lightPrimaryColor,
    this.lightSecondaryColor,
    this.lightBackgroundColor,
    this.lightButtonColor,
    this.lightCardColor,
    this.darkPrimaryColor,
    this.darkSecondaryColor,
    this.darkBackgroundColor,
    this.darkButtonColor,
    this.darkCardColor,
    this.logoUrl,
    this.lightLogoUrl,
    this.darkLogoUrl,
    this.lightCoverUrl,
    this.darkCoverUrl,
    this.welcomeText,
  });

  factory TeacherThemeConfig.fromJson(Map<String, dynamic> json) {
    return TeacherThemeConfig(
      primaryColor: _parseColor(json['primary_color'] as String?),
      secondaryColor: _parseColor(json['secondary_color'] as String?),
      backgroundColor: _parseColor(json['background_color'] as String?),
      lightPrimaryColor: _parseColor(json['light_primary_color'] as String?),
      lightSecondaryColor:
          _parseColor(json['light_secondary_color'] as String?),
      lightBackgroundColor:
          _parseColor(json['light_background_color'] as String?),
      lightButtonColor: _parseColor(json['light_button_color'] as String?),
      lightCardColor: _parseColor(json['light_card_color'] as String?),
      darkPrimaryColor: _parseColor(json['dark_primary_color'] as String?),
      darkSecondaryColor: _parseColor(json['dark_secondary_color'] as String?),
      darkBackgroundColor:
          _parseColor(json['dark_background_color'] as String?),
      darkButtonColor: _parseColor(json['dark_button_color'] as String?),
      darkCardColor: _parseColor(json['dark_card_color'] as String?),
      logoUrl: json['logo_url'] as String?,
      lightLogoUrl: json['light_logo_url'] as String?,
      darkLogoUrl: json['dark_logo_url'] as String?,
      lightCoverUrl: json['light_cover_url'] as String?,
      darkCoverUrl: json['dark_cover_url'] as String?,
      welcomeText: json['welcome_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': _colorToHex(primaryColor),
      'secondary_color': _colorToHex(secondaryColor),
      'background_color': _colorToHex(backgroundColor),
      'light_primary_color': _colorToHex(lightPrimaryColor),
      'light_secondary_color': _colorToHex(lightSecondaryColor),
      'light_background_color': _colorToHex(lightBackgroundColor),
      'light_button_color': _colorToHex(lightButtonColor),
      'light_card_color': _colorToHex(lightCardColor),
      'dark_primary_color': _colorToHex(darkPrimaryColor),
      'dark_secondary_color': _colorToHex(darkSecondaryColor),
      'dark_background_color': _colorToHex(darkBackgroundColor),
      'dark_button_color': _colorToHex(darkButtonColor),
      'dark_card_color': _colorToHex(darkCardColor),
      'logo_url': logoUrl,
      'light_logo_url': lightLogoUrl,
      'dark_logo_url': darkLogoUrl,
      'light_cover_url': lightCoverUrl,
      'dark_cover_url': darkCoverUrl,
      'welcome_text': welcomeText,
    };
  }

  bool get hasColors =>
      primaryColor != null ||
      secondaryColor != null ||
      backgroundColor != null ||
      lightPrimaryColor != null ||
      lightSecondaryColor != null ||
      lightBackgroundColor != null ||
      lightButtonColor != null ||
      lightCardColor != null ||
      darkPrimaryColor != null ||
      darkSecondaryColor != null ||
      darkBackgroundColor != null ||
      darkButtonColor != null ||
      darkCardColor != null;

  Color? primaryFor(bool isDarkMode) => isDarkMode
      ? darkPrimaryColor ?? primaryColor
      : lightPrimaryColor ?? primaryColor;

  Color? secondaryFor(bool isDarkMode) => isDarkMode
      ? darkSecondaryColor ?? secondaryColor
      : lightSecondaryColor ?? secondaryColor;

  Color? backgroundFor(bool isDarkMode) => isDarkMode
      ? darkBackgroundColor ?? backgroundColor
      : lightBackgroundColor ?? backgroundColor;

  Color? buttonFor(bool isDarkMode) => isDarkMode
      ? darkButtonColor ?? primaryFor(true)
      : lightButtonColor ?? primaryFor(false);

  Color? cardFor(bool isDarkMode) =>
      isDarkMode ? darkCardColor : lightCardColor;

  String? logoFor(bool isDarkMode) =>
      isDarkMode ? darkLogoUrl ?? logoUrl : lightLogoUrl ?? logoUrl;

  String? coverFor(bool isDarkMode) =>
      isDarkMode ? darkCoverUrl : lightCoverUrl;

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

  static String? _colorToHex(Color? color) {
    if (color == null) return null;
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }
}

class TeacherContextService {
  TeacherContextService._();

  static final TeacherContextService instance = TeacherContextService._();

  static const _selectedTeacherIdKey = 'nasaq_selected_teacher_id';
  static const _selectedTeacherNameKey = 'nasaq_selected_teacher_name';
  static const _selectedTeacherJsonKey = 'nasaq_selected_teacher_json';

  final ValueNotifier<SelectedTeacher?> selectedTeacher = ValueNotifier(null);

  SupabaseClient? _client;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init(SupabaseClient client) async {
    if (_isInitialized) return;
    AppLogger.i('🏫 [TeacherContextService] Initializing...');
    _client = client;
    _prefs = await SharedPreferences.getInstance();
    _restoreCachedTeacher();
    _isInitialized = true;
    AppLogger.success('[TeacherContextService] Initialized');
  }

  Future<void> ensureInitialized(SupabaseClient client) => init(client);

  String? get selectedTeacherId => selectedTeacher.value?.id;

  bool hasCachedTeacher() {
    final has = _prefs?.getString(_selectedTeacherIdKey) != null;
    AppLogger.d('🏫 [TeacherContextService] hasCachedTeacher: $has');
    return has;
  }

  Future<bool> hasSelectedTeacher(String studentId) async {
    AppLogger.i(
        '🏫 [TeacherContextService] Checking selected teacher for student: $studentId');

    final client = _client;
    if (client == null) {
      AppLogger.w('[TeacherContextService] Client is null — not initialized');
      return selectedTeacher.value != null || hasCachedTeacher();
    }

    try {
      AppLogger.d('🏫 [TeacherContextService] Fetching teacher from DB...');
      final response = await client
          .from('student_teacher_links')
          .select('teachers(id, display_name, avatar_url, teacher_themes(*))')
          .eq('student_id', studentId)
          .eq('is_active', true)
          .maybeSingle();

      final teacher = response?['teachers'] as Map<String, dynamic>?;
      if (teacher == null) {
        AppLogger.w(
            '[TeacherContextService] No active teacher linked to student $studentId — using نسق defaults');
        return false;
      }

      final selected = SelectedTeacher.fromJson(teacher);
      AppLogger.success(
          '[TeacherContextService] Teacher loaded: ${selected.name} (id: ${selected.id}) — hasTheme: ${selected.theme.hasColors}');
      await _setSelectedTeacher(selected);
      return true;
    } catch (e, stack) {
      AppLogger.e('[TeacherContextService] Error fetching teacher', e, stack);
      return selectedTeacher.value != null || hasCachedTeacher();
    }
  }

  Future<List<SelectedTeacher>> getAvailableTeachers() async {
    AppLogger.i('🏫 [TeacherContextService] Fetching available teachers...');
    try {
      final client = _requireClient();
      final response = await client
          .from('teachers')
          .select(
              'id, display_name, avatar_url, profiles!teachers_profile_id_fkey(name, avatar_url), teacher_themes(*)')
          .eq('is_active', true)
          .order('display_name', ascending: true);

      final teachers = (response as List)
          .map((json) => SelectedTeacher.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.success(
          '[TeacherContextService] Available teachers: ${teachers.length}');
      return teachers;
    } catch (e, stack) {
      AppLogger.e('[TeacherContextService] Error fetching available teachers',
          e, stack);
      rethrow;
    }
  }

  Future<void> selectTeacher({
    required String studentId,
    required SelectedTeacher teacher,
  }) async {
    AppLogger.i(
        '🏫 [TeacherContextService] Selecting teacher: ${teacher.name} for student: $studentId');
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
    AppLogger.success(
        '[TeacherContextService] Teacher selected: ${teacher.name}');
  }

  Future<void> clear() async {
    AppLogger.i('🏫 [TeacherContextService] Clearing selected teacher');
    selectedTeacher.value = null;
    await _prefs?.remove(_selectedTeacherIdKey);
    await _prefs?.remove(_selectedTeacherNameKey);
    await _prefs?.remove(_selectedTeacherJsonKey);
    AppLogger.success(
        '[TeacherContextService] Teacher cleared — reverting to نسق defaults');
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      AppLogger.e('[TeacherContextService] Not initialized — client is null');
      throw StateError('TeacherContextService is not initialized');
    }
    return client;
  }

  void _restoreCachedTeacher() {
    final cachedJson = _prefs?.getString(_selectedTeacherJsonKey);
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson);
        if (decoded is Map<String, dynamic>) {
          final teacher = SelectedTeacher.fromJson(decoded);
          AppLogger.i(
              '🏫 [TeacherContextService] Restored cached teacher theme: ${teacher.name} (id: ${teacher.id})');
          selectedTeacher.value = teacher;
          return;
        }
      } catch (e, stack) {
        AppLogger.e(
          '[TeacherContextService] Failed to restore cached teacher theme',
          e,
          stack,
        );
      }
    }

    final id = _prefs?.getString(_selectedTeacherIdKey);
    if (id == null) {
      AppLogger.d(
          '🏫 [TeacherContextService] No cached teacher — using نسق defaults');
      return;
    }
    final name = _prefs?.getString(_selectedTeacherNameKey) ?? 'مدرس';
    AppLogger.i(
        '🏫 [TeacherContextService] Restored cached teacher: $name (id: $id)');
    selectedTeacher.value = SelectedTeacher(
      id: id,
      name: name,
    );
  }

  Future<void> updateSelectedTeacher(SelectedTeacher teacher) async {
    await _setSelectedTeacher(teacher);
  }

  Future<void> _setSelectedTeacher(SelectedTeacher teacher) async {
    selectedTeacher.value = teacher;
    await _prefs?.setString(_selectedTeacherIdKey, teacher.id);
    await _prefs?.setString(_selectedTeacherNameKey, teacher.name);
    await _prefs?.setString(
      _selectedTeacherJsonKey,
      jsonEncode(teacher.toJson()),
    );
    AppLogger.d(
        '🏫 [TeacherContextService] Teacher persisted to cache: ${teacher.name}');
  }
}
