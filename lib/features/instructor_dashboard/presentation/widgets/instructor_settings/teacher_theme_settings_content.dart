import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/services/teacher_context_service.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

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
  static const _defaultDarkBackground = '#01060B';
  static const _defaultLightBackground = '#F4F9FA';

  final _client = Supabase.instance.client;
  final _picker = ImagePicker();
  final _coverUrlController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _lightCoverUrlController = TextEditingController();
  final _darkCoverUrlController = TextEditingController();
  final _lightLogoUrlController = TextEditingController();
  final _darkLogoUrlController = TextEditingController();
  final _welcomeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLightCover = false;
  bool _isUploadingDarkCover = false;
  bool _isUploadingLogo = false;
  String? _teacherId;
  String? _error;
  Uint8List? _lightCoverPreviewBytes;
  Uint8List? _darkCoverPreviewBytes;
  Uint8List? _logoPreviewBytes;

  Color _lightPrimaryColor = _parseColor(_defaultPrimary);
  Color _lightSecondaryColor = _parseColor(_defaultSecondary);
  Color _lightBackgroundColor = _parseColor(_defaultLightBackground);
  Color _lightButtonColor = _parseColor(_defaultPrimary);
  Color _lightCardColor = _parseColor('#FFFFFF');
  Color _darkPrimaryColor = _parseColor(_defaultPrimary);
  Color _darkSecondaryColor = _parseColor(_defaultSecondary);
  Color _darkBackgroundColor = _parseColor(_defaultDarkBackground);
  Color _darkButtonColor = _parseColor(_defaultPrimary);
  Color _darkCardColor = _parseColor('#071720');
  _ThemeModePreview _previewMode = _ThemeModePreview.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  @override
  void dispose() {
    _coverUrlController.dispose();
    _logoUrlController.dispose();
    _lightCoverUrlController.dispose();
    _darkCoverUrlController.dispose();
    _lightLogoUrlController.dispose();
    _darkLogoUrlController.dispose();
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
          .select('id, avatar_url, cover_image_url, teacher_themes(*)')
          .eq('profile_id', userId)
          .maybeSingle();

      if (teacher == null) throw Exception('Teacher profile was not found');

      _teacherId = teacher['id'] as String;
      _logoUrlController.text = teacher['avatar_url'] as String? ?? '';
      _lightLogoUrlController.text = _logoUrlController.text;
      _darkLogoUrlController.text = _logoUrlController.text;

      final themeData = _firstMap(teacher['teacher_themes']);
      if (themeData != null) {
        final legacyPrimary = themeData['primary_color'] as String?;
        final legacySecondary = themeData['secondary_color'] as String?;
        final legacyBackground = themeData['background_color'] as String?;
        _lightPrimaryColor = _parseColor(
          themeData['light_primary_color'] as String? ??
              legacyPrimary ??
              _defaultPrimary,
        );
        _lightSecondaryColor = _parseColor(
          themeData['light_secondary_color'] as String? ??
              legacySecondary ??
              _defaultSecondary,
        );
        _lightBackgroundColor = _parseColor(
          themeData['light_background_color'] as String? ??
              _defaultLightBackground,
        );
        _lightButtonColor = _parseColor(
          themeData['light_button_color'] as String? ??
              legacyPrimary ??
              _defaultPrimary,
        );
        _lightCardColor = _parseColor(
          themeData['light_card_color'] as String? ?? '#FFFFFF',
        );
        _darkPrimaryColor = _parseColor(
          themeData['dark_primary_color'] as String? ??
              legacyPrimary ??
              _defaultPrimary,
        );
        _darkSecondaryColor = _parseColor(
          themeData['dark_secondary_color'] as String? ??
              legacySecondary ??
              _defaultSecondary,
        );
        _darkBackgroundColor = _parseColor(
          themeData['dark_background_color'] as String? ??
              legacyBackground ??
              _defaultDarkBackground,
        );
        _darkButtonColor = _parseColor(
          themeData['dark_button_color'] as String? ??
              legacyPrimary ??
              _defaultPrimary,
        );
        _darkCardColor = _parseColor(
          themeData['dark_card_color'] as String? ?? '#071720',
        );
        _coverUrlController.text = themeData['logo_url'] as String? ??
            teacher['cover_image_url'] as String? ??
            '';
        _lightCoverUrlController.text =
            themeData['light_cover_url'] as String? ?? _coverUrlController.text;
        _darkCoverUrlController.text =
            themeData['dark_cover_url'] as String? ?? _coverUrlController.text;
        _lightLogoUrlController.text =
            themeData['light_logo_url'] as String? ?? _logoUrlController.text;
        _darkLogoUrlController.text =
            themeData['dark_logo_url'] as String? ?? _logoUrlController.text;
        _welcomeController.text = themeData['welcome_text'] as String? ?? '';
      } else {
        _coverUrlController.text = teacher['cover_image_url'] as String? ?? '';
        _lightCoverUrlController.text = _coverUrlController.text;
        _darkCoverUrlController.text = _coverUrlController.text;
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

  Future<void> _pickAndUploadImage(
    _ThemeImageTarget target, {
    _ThemeModePreview? mode,
  }) async {
    final teacherId = _teacherId;
    if (teacherId == null) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final uploadMode = mode ?? _previewMode;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: target == _ThemeImageTarget.cover ? 1800 : 700,
      maxHeight: target == _ThemeImageTarget.cover ? 1000 : 700,
      imageQuality: 86,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      if (target == _ThemeImageTarget.cover) {
        if (uploadMode == _ThemeModePreview.dark) {
          _isUploadingDarkCover = true;
          _darkCoverPreviewBytes = bytes;
        } else {
          _isUploadingLightCover = true;
          _lightCoverPreviewBytes = bytes;
        }
      } else {
        _isUploadingLogo = true;
        _logoPreviewBytes = bytes;
      }
    });

    try {
      final modePrefix =
          uploadMode == _ThemeModePreview.dark ? 'dark' : 'light';
      final fileName = target == _ThemeImageTarget.cover
          ? '${modePrefix}_theme_cover.jpg'
          : '${modePrefix}_theme_logo.jpg';
      final path = '$userId/teacher_themes/$teacherId/$fileName';

      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final url = _client.storage.from('avatars').getPublicUrl(path);
      final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        if (target == _ThemeImageTarget.cover) {
          _coverControllerFor(uploadMode).text = cacheBusted;
          _coverUrlController.text = cacheBusted;
        } else {
          _logoControllerFor(uploadMode).text = cacheBusted;
          _logoUrlController.text = cacheBusted;
        }
      });
    } catch (e, stack) {
      AppLogger.e('[TeacherTheme] Failed to upload theme image', e, stack);
      if (!mounted) return;
      AnimatedSnackbar.showError(
        context: context,
        message: 'تعذر رفع الصورة',
      );
    } finally {
      if (mounted) {
        setState(() {
          if (target == _ThemeImageTarget.cover) {
            if (uploadMode == _ThemeModePreview.dark) {
              _isUploadingDarkCover = false;
            } else {
              _isUploadingLightCover = false;
            }
          } else {
            _isUploadingLogo = false;
          }
        });
      }
    }
  }

  Future<void> _saveTheme() async {
    final teacherId = _teacherId;
    if (teacherId == null) return;

    setState(() => _isSaving = true);
    try {
      final coverUrl = _emptyToNull(_coverUrlController.text);
      final logoUrl = _emptyToNull(_logoUrlController.text);
      final lightCoverUrl = _emptyToNull(_lightCoverUrlController.text);
      final darkCoverUrl = _emptyToNull(_darkCoverUrlController.text);
      final lightLogoUrl = _emptyToNull(_lightLogoUrlController.text);
      final darkLogoUrl = _emptyToNull(_darkLogoUrlController.text);

      await _client.from('teacher_themes').upsert({
        'teacher_id': teacherId,
        'primary_color': _colorToHex(_darkPrimaryColor),
        'secondary_color': _colorToHex(_darkSecondaryColor),
        'background_color': _colorToHex(_darkBackgroundColor),
        'light_primary_color': _colorToHex(_lightPrimaryColor),
        'light_secondary_color': _colorToHex(_lightSecondaryColor),
        'light_background_color': _colorToHex(_lightBackgroundColor),
        'light_button_color': _colorToHex(_lightButtonColor),
        'light_card_color': _colorToHex(_lightCardColor),
        'dark_primary_color': _colorToHex(_darkPrimaryColor),
        'dark_secondary_color': _colorToHex(_darkSecondaryColor),
        'dark_background_color': _colorToHex(_darkBackgroundColor),
        'dark_button_color': _colorToHex(_darkButtonColor),
        'dark_card_color': _colorToHex(_darkCardColor),
        'logo_url': logoUrl,
        'light_cover_url': lightCoverUrl,
        'dark_cover_url': darkCoverUrl,
        'light_logo_url': lightLogoUrl,
        'dark_logo_url': darkLogoUrl,
        'welcome_text': _emptyToNull(_welcomeController.text),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'teacher_id');

      await _client.from('teachers').update({
        'avatar_url': logoUrl ?? darkLogoUrl ?? lightLogoUrl,
        'cover_image_url': coverUrl ?? darkCoverUrl ?? lightCoverUrl,
      }).eq('id', teacherId);

      await _syncSelectedTeacherTheme(teacherId, logoUrl);

      if (!mounted) return;
      AnimatedSnackbar.showSuccess(
        context: context,
        message: 'تم حفظ الهوية',
      );
    } catch (_) {
      if (!mounted) return;
      AnimatedSnackbar.showError(
        context: context,
        message: 'تعذر حفظ الهوية',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncSelectedTeacherTheme(
      String teacherId, String? logoUrl) async {
    final selectedTeacher =
        TeacherContextService.instance.selectedTeacher.value;
    if (selectedTeacher == null || selectedTeacher.id != teacherId) return;

    await TeacherContextService.instance.updateSelectedTeacher(SelectedTeacher(
      id: selectedTeacher.id,
      name: selectedTeacher.name,
      avatarUrl: logoUrl ?? selectedTeacher.avatarUrl,
      theme: TeacherThemeConfig(
        primaryColor: _darkPrimaryColor,
        secondaryColor: _darkSecondaryColor,
        backgroundColor: _darkBackgroundColor,
        lightPrimaryColor: _lightPrimaryColor,
        lightSecondaryColor: _lightSecondaryColor,
        lightBackgroundColor: _lightBackgroundColor,
        lightButtonColor: _lightButtonColor,
        lightCardColor: _lightCardColor,
        darkPrimaryColor: _darkPrimaryColor,
        darkSecondaryColor: _darkSecondaryColor,
        darkBackgroundColor: _darkBackgroundColor,
        darkButtonColor: _darkButtonColor,
        darkCardColor: _darkCardColor,
        logoUrl: _emptyToNull(_coverUrlController.text),
        lightLogoUrl: _emptyToNull(_lightLogoUrlController.text),
        darkLogoUrl: _emptyToNull(_darkLogoUrlController.text),
        lightCoverUrl: _emptyToNull(_lightCoverUrlController.text),
        darkCoverUrl: _emptyToNull(_darkCoverUrlController.text),
        welcomeText: _emptyToNull(_welcomeController.text),
      ),
    ));
  }

  Color get _currentPrimaryColor => _previewMode == _ThemeModePreview.dark
      ? _darkPrimaryColor
      : _lightPrimaryColor;

  Color get _currentSecondaryColor => _previewMode == _ThemeModePreview.dark
      ? _darkSecondaryColor
      : _lightSecondaryColor;

  Color get _currentBackgroundColor => _previewMode == _ThemeModePreview.dark
      ? _darkBackgroundColor
      : _lightBackgroundColor;

  Color get _currentButtonColor => _previewMode == _ThemeModePreview.dark
      ? _darkButtonColor
      : _lightButtonColor;

  Color get _currentCardColor =>
      _previewMode == _ThemeModePreview.dark ? _darkCardColor : _lightCardColor;

  TextEditingController get _currentCoverController =>
      _coverControllerFor(_previewMode);

  TextEditingController get _currentLogoController =>
      _logoControllerFor(_previewMode);

  TextEditingController _coverControllerFor(_ThemeModePreview mode) =>
      mode == _ThemeModePreview.dark
          ? _darkCoverUrlController
          : _lightCoverUrlController;

  TextEditingController _logoControllerFor(_ThemeModePreview mode) =>
      mode == _ThemeModePreview.dark
          ? _darkLogoUrlController
          : _lightLogoUrlController;

  Uint8List? get _currentCoverPreviewBytes =>
      _previewMode == _ThemeModePreview.dark
          ? _darkCoverPreviewBytes
          : _lightCoverPreviewBytes;

  void _setCurrentPrimaryColor(Color color) {
    if (_previewMode == _ThemeModePreview.dark) {
      _darkPrimaryColor = color;
    } else {
      _lightPrimaryColor = color;
    }
  }

  void _setCurrentSecondaryColor(Color color) {
    if (_previewMode == _ThemeModePreview.dark) {
      _darkSecondaryColor = color;
    } else {
      _lightSecondaryColor = color;
    }
  }

  void _setCurrentBackgroundColor(Color color) {
    if (_previewMode == _ThemeModePreview.dark) {
      _darkBackgroundColor = color;
    } else {
      _lightBackgroundColor = color;
    }
  }

  void _setCurrentButtonColor(Color color) {
    if (_previewMode == _ThemeModePreview.dark) {
      _darkButtonColor = color;
    } else {
      _lightButtonColor = color;
    }
  }

  void _setCurrentCardColor(Color color) {
    if (_previewMode == _ThemeModePreview.dark) {
      _darkCardColor = color;
    } else {
      _lightCardColor = color;
    }
  }

  void _applyPreset(_TeacherThemePreset preset) {
    setState(() {
      _lightPrimaryColor = preset.lightPrimary;
      _lightSecondaryColor = preset.lightSecondary;
      _lightBackgroundColor = preset.lightBackground;
      _lightButtonColor = preset.lightButton;
      _lightCardColor = preset.lightCard;
      _darkPrimaryColor = preset.darkPrimary;
      _darkSecondaryColor = preset.darkSecondary;
      _darkBackgroundColor = preset.darkBackground;
      _darkButtonColor = preset.darkButton;
      _darkCardColor = preset.darkCard;
    });
  }

  bool _isPresetSelected(_TeacherThemePreset preset) {
    return _sameColor(_lightPrimaryColor, preset.lightPrimary) &&
        _sameColor(_lightSecondaryColor, preset.lightSecondary) &&
        _sameColor(_lightBackgroundColor, preset.lightBackground) &&
        _sameColor(_lightButtonColor, preset.lightButton) &&
        _sameColor(_lightCardColor, preset.lightCard) &&
        _sameColor(_darkPrimaryColor, preset.darkPrimary) &&
        _sameColor(_darkSecondaryColor, preset.darkSecondary) &&
        _sameColor(_darkBackgroundColor, preset.darkBackground) &&
        _sameColor(_darkButtonColor, preset.darkButton) &&
        _sameColor(_darkCardColor, preset.darkCard);
  }

  Future<void> _openCustomizeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateState(VoidCallback update) {
              setState(update);
              setSheetState(() {});
            }

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'تخصيص الثيم',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      _ModeSelector(
                        value: _previewMode,
                        onChanged: (value) {
                          updateState(() => _previewMode = value);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildCustomizationSections(
                        isDark: isDark,
                        updateState: updateState,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomizationSections({
    required bool isDark,
    required void Function(VoidCallback update) updateState,
  }) {
    return Column(
      children: [
        _SectionCard(
          title: 'الألوان',
          subtitle: 'عدّل ألوان الوضع المختار من الأعلى',
          isDark: isDark,
          child: Column(
            children: [
              _ColorSelectorTile(
                title: 'اللون الأساسي',
                color: _currentPrimaryColor,
                onTap: () => _openColorSheet(
                  title: 'اللون الأساسي',
                  selected: _currentPrimaryColor,
                  onSelected: (color) =>
                      updateState(() => _setCurrentPrimaryColor(color)),
                ),
              ),
              _ColorSelectorTile(
                title: 'اللون الثانوي',
                color: _currentSecondaryColor,
                onTap: () => _openColorSheet(
                  title: 'اللون الثانوي',
                  selected: _currentSecondaryColor,
                  onSelected: (color) =>
                      updateState(() => _setCurrentSecondaryColor(color)),
                ),
              ),
              _ColorSelectorTile(
                title: 'لون الخلفية',
                color: _currentBackgroundColor,
                onTap: () => _openColorSheet(
                  title: 'لون الخلفية',
                  selected: _currentBackgroundColor,
                  onSelected: (color) =>
                      updateState(() => _setCurrentBackgroundColor(color)),
                ),
              ),
              _ColorSelectorTile(
                title: 'لون الأزرار',
                color: _currentButtonColor,
                onTap: () => _openColorSheet(
                  title: 'لون الأزرار',
                  selected: _currentButtonColor,
                  onSelected: (color) =>
                      updateState(() => _setCurrentButtonColor(color)),
                ),
              ),
              _ColorSelectorTile(
                title: 'خلفية الكروت',
                color: _currentCardColor,
                onTap: () => _openColorSheet(
                  title: 'خلفية الكروت',
                  selected: _currentCardColor,
                  onSelected: (color) =>
                      updateState(() => _setCurrentCardColor(color)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'الصور',
          subtitle: 'ارفع شعار المدرس وصورة كفر منفصلة لكل وضع',
          isDark: isDark,
          child: Column(
            children: [
              _ImageUploadTile(
                title: 'الشعار',
                subtitle: 'يظهر مع بيانات المدرس',
                url: _currentLogoController.text,
                bytes: _logoPreviewBytes,
                isUploading: _isUploadingLogo,
                icon: Icons.badge_rounded,
                onUpload: () async {
                  await _pickAndUploadImage(_ThemeImageTarget.logo);
                  updateState(() {});
                },
                onClear: () {
                  updateState(() {
                    _currentLogoController.clear();
                    _logoUrlController.clear();
                    _logoPreviewBytes = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              _ImageUploadTile(
                title: 'صورة الكفر - لايت مود',
                subtitle: 'تظهر للطالب عند استخدام الوضع الفاتح',
                url: _lightCoverUrlController.text,
                bytes: _lightCoverPreviewBytes,
                isUploading: _isUploadingLightCover,
                icon: Icons.wallpaper_rounded,
                wide: true,
                onUpload: () async {
                  await _pickAndUploadImage(
                    _ThemeImageTarget.cover,
                    mode: _ThemeModePreview.light,
                  );
                  updateState(() {});
                },
                onClear: () {
                  updateState(() {
                    _lightCoverUrlController.clear();
                    _coverUrlController.clear();
                    _lightCoverPreviewBytes = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              _ImageUploadTile(
                title: 'صورة الكفر - دارك مود',
                subtitle: 'تظهر للطالب عند استخدام الوضع الداكن',
                url: _darkCoverUrlController.text,
                bytes: _darkCoverPreviewBytes,
                isUploading: _isUploadingDarkCover,
                icon: Icons.wallpaper_rounded,
                wide: true,
                onUpload: () async {
                  await _pickAndUploadImage(
                    _ThemeImageTarget.cover,
                    mode: _ThemeModePreview.dark,
                  );
                  updateState(() {});
                },
                onClear: () {
                  updateState(() {
                    _darkCoverUrlController.clear();
                    _coverUrlController.clear();
                    _darkCoverPreviewBytes = null;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'نص الترحيب',
          subtitle: 'اختياري',
          isDark: isDark,
          child: TextField(
            controller: _welcomeController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'مثال: ابدأ رحلتك التعليمية بثقة',
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
        _HeaderCard(isDark: isDark),
        const SizedBox(height: 14),
        _ThemePreview(
          primary: _currentPrimaryColor,
          secondary: _currentSecondaryColor,
          background: _currentBackgroundColor,
          button: _currentButtonColor,
          card: _currentCardColor,
          logoUrl: _currentLogoController.text,
          coverUrl: _currentCoverController.text,
          logoBytes: _logoPreviewBytes,
          coverBytes: _currentCoverPreviewBytes,
          isDarkPreview: _previewMode == _ThemeModePreview.dark,
        ),
        const SizedBox(height: 14),
        _ModeSelector(
          value: _previewMode,
          onChanged: (value) {
            setState(() {
              _previewMode = value;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _PresetThemeSection(
          presets: _themePresets,
          isDark: isDark,
          isSelected: _isPresetSelected,
          onSelected: _applyPreset,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _openCustomizeSheet,
            icon: const Icon(Icons.tune_rounded),
            label: const Text(
              'تخصيص الثيم',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSaving ||
                    _isUploadingLightCover ||
                    _isUploadingDarkCover ||
                    _isUploadingLogo
                ? null
                : _saveTheme,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text(
              'حفظ الهوية',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _openColorSheet({
    required String title,
    required Color selected,
    required ValueChanged<Color> onSelected,
  }) async {
    final hexController = TextEditingController(text: _colorToHex(selected));
    final color = await showModalBottomSheet<Color>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  6,
                  18,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorPresets.map((preset) {
                        final isSelected =
                            preset.toARGB32() == selected.toARGB32();
                        return InkWell(
                          onTap: () => Navigator.pop(context, preset),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: preset,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.textMainDark
                                        : AppColors.textMainLight)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hexController,
                      textDirection: TextDirection.ltr,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Hex',
                        hintText: '#20E5DC',
                        errorText: errorText,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded),
                          onPressed: () {
                            final parsed = _tryParseColor(hexController.text);
                            if (parsed == null) {
                              setSheetState(() {
                                errorText = 'اكتب كود لون صحيح';
                              });
                              return;
                            }
                            Navigator.pop(context, parsed);
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        final parsed = _tryParseColor(value);
                        if (parsed == null) {
                          setSheetState(() {
                            errorText = 'اكتب كود لون صحيح';
                          });
                          return;
                        }
                        Navigator.pop(context, parsed);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    hexController.dispose();

    if (color != null) onSelected(color);
  }

  static Map<String, dynamic>? _firstMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Color _parseColor(String value) {
    return _tryParseColor(value) ?? AppColors.primary;
  }

  static Color? _tryParseColor(String value) {
    final normalized = value.replaceAll('#', '').trim();
    if (normalized.length != 6 && normalized.length != 8) return null;
    final parsed = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    return parsed == null ? null : Color(parsed);
  }

  static String _colorToHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }

  static bool _sameColor(Color a, Color b) => a.toARGB32() == b.toARGB32();

  static final List<Color> _colorPresets = [
    const Color(0xFF20E5DC),
    const Color(0xFF117CFF),
    const Color(0xFF22C55E),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFF0F172A),
    const Color(0xFF01060B),
    const Color(0xFFF4F9FA),
    const Color(0xFFFFFFFF),
  ];

  static const List<_TeacherThemePreset> _themePresets = [
    _TeacherThemePreset(
      name: 'نسق نيونو',
      tagline: 'هوية تقنية مضيئة',
      icon: Icons.auto_awesome_rounded,
      lightPrimary: Color(0xFF00BEB8),
      lightSecondary: Color(0xFF117CFF),
      lightBackground: Color(0xFFF4FBFC),
      lightButton: Color(0xFF00BEB8),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFF20E5DC),
      darkSecondary: Color(0xFF117CFF),
      darkBackground: Color(0xFF01060B),
      darkButton: Color(0xFF20E5DC),
      darkCard: Color(0xFF071720),
    ),
    _TeacherThemePreset(
      name: 'ملكي',
      tagline: 'أزرق فاخر وذهبي',
      icon: Icons.workspace_premium_rounded,
      lightPrimary: Color(0xFF1D4ED8),
      lightSecondary: Color(0xFFD97706),
      lightBackground: Color(0xFFF7FAFF),
      lightButton: Color(0xFF1D4ED8),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFF60A5FA),
      darkSecondary: Color(0xFFFBBF24),
      darkBackground: Color(0xFF07111F),
      darkButton: Color(0xFF2563EB),
      darkCard: Color(0xFF0D1B2E),
    ),
    _TeacherThemePreset(
      name: 'زمرد',
      tagline: 'هادئ ومنظم',
      icon: Icons.eco_rounded,
      lightPrimary: Color(0xFF059669),
      lightSecondary: Color(0xFF0EA5E9),
      lightBackground: Color(0xFFF2FBF7),
      lightButton: Color(0xFF059669),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFF34D399),
      darkSecondary: Color(0xFF38BDF8),
      darkBackground: Color(0xFF03110D),
      darkButton: Color(0xFF10B981),
      darkCard: Color(0xFF08251C),
    ),
    _TeacherThemePreset(
      name: 'ياقوت',
      tagline: 'قوي وواضح',
      icon: Icons.local_fire_department_rounded,
      lightPrimary: Color(0xFFDC2626),
      lightSecondary: Color(0xFFF97316),
      lightBackground: Color(0xFFFFF7F5),
      lightButton: Color(0xFFDC2626),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFFFB7185),
      darkSecondary: Color(0xFFF97316),
      darkBackground: Color(0xFF160608),
      darkButton: Color(0xFFE11D48),
      darkCard: Color(0xFF2A1013),
    ),
    _TeacherThemePreset(
      name: 'بنفسج',
      tagline: 'إبداعي وناعم',
      icon: Icons.blur_on_rounded,
      lightPrimary: Color(0xFF7C3AED),
      lightSecondary: Color(0xFFEC4899),
      lightBackground: Color(0xFFFBF7FF),
      lightButton: Color(0xFF7C3AED),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFFA78BFA),
      darkSecondary: Color(0xFFF472B6),
      darkBackground: Color(0xFF10081F),
      darkButton: Color(0xFF8B5CF6),
      darkCard: Color(0xFF1E1233),
    ),
    _TeacherThemePreset(
      name: 'فضي',
      tagline: 'بسيط واحترافي',
      icon: Icons.diamond_rounded,
      lightPrimary: Color(0xFF475569),
      lightSecondary: Color(0xFF06B6D4),
      lightBackground: Color(0xFFF7FAFC),
      lightButton: Color(0xFF334155),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFFCBD5E1),
      darkSecondary: Color(0xFF22D3EE),
      darkBackground: Color(0xFF0A0F16),
      darkButton: Color(0xFF0891B2),
      darkCard: Color(0xFF111827),
    ),
    _TeacherThemePreset(
      name: 'شمس',
      tagline: 'مشرق وحيوي',
      icon: Icons.wb_sunny_rounded,
      lightPrimary: Color(0xFFF59E0B),
      lightSecondary: Color(0xFF14B8A6),
      lightBackground: Color(0xFFFFFBEB),
      lightButton: Color(0xFFF59E0B),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFFFBBF24),
      darkSecondary: Color(0xFF2DD4BF),
      darkBackground: Color(0xFF141006),
      darkButton: Color(0xFFD97706),
      darkCard: Color(0xFF261D0A),
    ),
    _TeacherThemePreset(
      name: 'محترف',
      tagline: 'داشبورد نظيف',
      icon: Icons.analytics_rounded,
      lightPrimary: Color(0xFF0F766E),
      lightSecondary: Color(0xFF2563EB),
      lightBackground: Color(0xFFF6F8FB),
      lightButton: Color(0xFF0F766E),
      lightCard: Color(0xFFFFFFFF),
      darkPrimary: Color(0xFF2DD4BF),
      darkSecondary: Color(0xFF60A5FA),
      darkBackground: Color(0xFF060B12),
      darkButton: Color(0xFF14B8A6),
      darkCard: Color(0xFF0F172A),
    ),
  ];
}

class _TeacherThemePreset {
  final String name;
  final String tagline;
  final IconData icon;
  final Color lightPrimary;
  final Color lightSecondary;
  final Color lightBackground;
  final Color lightButton;
  final Color lightCard;
  final Color darkPrimary;
  final Color darkSecondary;
  final Color darkBackground;
  final Color darkButton;
  final Color darkCard;

  const _TeacherThemePreset({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.lightPrimary,
    required this.lightSecondary,
    required this.lightBackground,
    required this.lightButton,
    required this.lightCard,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.darkBackground,
    required this.darkButton,
    required this.darkCard,
  });
}

class _PresetThemeSection extends StatelessWidget {
  final List<_TeacherThemePreset> presets;
  final bool isDark;
  final bool Function(_TeacherThemePreset preset) isSelected;
  final ValueChanged<_TeacherThemePreset> onSelected;

  const _PresetThemeSection({
    required this.presets,
    required this.isDark,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ثيمات جاهزة',
      subtitle: 'اختار ثيم فاخر وخصصه بعدين لو محتاج',
      isDark: isDark,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: presets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        itemBuilder: (context, index) {
          final preset = presets[index];
          return _PresetThemeCard(
            preset: preset,
            selected: isSelected(preset),
            darkPreview: isDark,
            onTap: () => onSelected(preset),
          );
        },
      ),
    );
  }
}

class _PresetThemeCard extends StatelessWidget {
  final _TeacherThemePreset preset;
  final bool selected;
  final bool darkPreview;
  final VoidCallback onTap;

  const _PresetThemeCard({
    required this.preset,
    required this.selected,
    required this.darkPreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = darkPreview ? preset.darkPrimary : preset.lightPrimary;
    final secondary =
        darkPreview ? preset.darkSecondary : preset.lightSecondary;
    final background =
        darkPreview ? preset.darkBackground : preset.lightBackground;
    final card = darkPreview ? preset.darkCard : preset.lightCard;
    final textColor = darkPreview ? AppColors.white : AppColors.textMainLight;
    final mutedColor = textColor.withValues(alpha: 0.68);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary : primary.withValues(alpha: 0.22),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: selected ? 0.18 : 0.08),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(preset.icon, color: primary),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: selected
                      ? Container(
                          key: const ValueKey('selected'),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey('idle'),
                          color: primary.withValues(alpha: 0.45),
                        ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 6,
                          width: 54,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: 6,
                          width: 36,
                          decoration: BoxDecoration(
                            color: secondary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              preset.tagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isDark;

  const _HeaderCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.palette_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هوية المدرس',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ألوان وصور تظهر للطالب بعد اختيار هذا المدرس',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final _ThemeModePreview value;
  final ValueChanged<_ThemeModePreview> onChanged;
  final bool isDark;

  const _ModeSelector({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'لايت مود',
              icon: Icons.light_mode_rounded,
              selected: value == _ThemeModePreview.light,
              onTap: () => onChanged(_ThemeModePreview.light),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ModeButton(
              label: 'دارك مود',
              icon: Icons.dark_mode_rounded,
              selected: value == _ThemeModePreview.dark,
              onTap: () => onChanged(_ThemeModePreview.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.white : AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ColorSelectorTile extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ColorSelectorTile({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _TeacherThemeSettingsContentState._colorToHex(color),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageUploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String url;
  final Uint8List? bytes;
  final bool isUploading;
  final IconData icon;
  final VoidCallback onUpload;
  final VoidCallback onClear;
  final bool wide;

  const _ImageUploadTile({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.bytes,
    required this.isUploading,
    required this.icon,
    required this.onUpload,
    required this.onClear,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _ImagePreview(
            url: url,
            bytes: bytes,
            icon: icon,
            wide: wide,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isUploading ? null : onUpload,
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(isUploading ? 'جاري الرفع' : 'رفع صورة'),
                    ),
                    if (url.trim().isNotEmpty || bytes != null)
                      IconButton(
                        onPressed: isUploading ? null : onClear,
                        tooltip: 'حذف',
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String url;
  final Uint8List? bytes;
  final IconData icon;
  final bool wide;

  const _ImagePreview({
    required this.url,
    required this.bytes,
    required this.icon,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    final child = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover)
        : url.trim().isNotEmpty
            ? Image.network(
                url.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder();

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: wide ? 108 : 72,
        height: 72,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: child,
      ),
    );
  }

  Widget _placeholder() {
    return Icon(icon, color: AppColors.primary, size: 28);
  }
}

class _ThemePreview extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color button;
  final Color card;
  final String logoUrl;
  final String coverUrl;
  final Uint8List? logoBytes;
  final Uint8List? coverBytes;
  final bool isDarkPreview;

  const _ThemePreview({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.button,
    required this.card,
    required this.logoUrl,
    required this.coverUrl,
    required this.logoBytes,
    required this.coverBytes,
    required this.isDarkPreview,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkPreview ? AppColors.white : AppColors.textMainLight;
    return Container(
      height: 184,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverBytes != null)
            Image.memory(coverBytes!, fit: BoxFit.cover)
          else if (coverUrl.trim().isNotEmpty)
            Image.network(
              coverUrl.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(color: background.withValues(alpha: 0.68)),
          Positioned(
            right: 18,
            left: 18,
            bottom: 18,
            child: Row(
              children: [
                _LogoPreview(
                  color: primary,
                  url: logoUrl,
                  bytes: logoBytes,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تجربة الطالب',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 8, width: 150, color: primary),
                      const SizedBox(height: 7),
                      Container(height: 8, width: 108, color: secondary),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 86,
                            height: 34,
                            decoration: BoxDecoration(
                              color: button,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  final Color color;
  final String url;
  final Uint8List? bytes;

  const _LogoPreview({
    required this.color,
    required this.url,
    required this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (bytes != null) {
      child = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (url.trim().isNotEmpty) {
      child = Image.network(
        url.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, color: color),
      );
    } else {
      child = Icon(Icons.school_rounded, color: color);
    }

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

enum _ThemeModePreview { light, dark }

enum _ThemeImageTarget { logo, cover }
