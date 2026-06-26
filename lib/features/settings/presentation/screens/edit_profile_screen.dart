import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/back_button.dart';
import '../../../../core/shared_widgets/phone_input_field.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../auth/presentation/widgets/login/avatar_picker.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_form_fields.dart';

/// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _countryDialCode = '+20'; // كود الدولة الافتراضي
  // Instructor fields
  final _displayNameCtrl = TextEditingController();
  final _headlineArCtrl = TextEditingController();
  final _headlineEnCtrl = TextEditingController();
  final _bioArCtrl = TextEditingController();
  final _bioEnCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();
  final _websiteUrlCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  Uint8List? _avatarBytes;
  Uint8List? _coverImageBytes;
  String? _currentAvatarUrl;
  String? _currentCoverImageUrl;
  bool _isLoading = false;
  bool _isInstructor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  Future<void> _ensureProfileLoaded() async {
    final cubit = context.read<ProfileCubit>();
    if (cubit.state.profile == null) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await cubit.loadProfile(userId);
      }
    }
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final state = context.read<ProfileCubit>().state;
    _nameCtrl.text = state.userName;
    _currentAvatarUrl = state.userAvatar;

    if (state.profile != null) {
      final profile = state.profile!;
      setState(() {
        _isInstructor = profile.role == 'instructor';
      });

      if (profile.phone != null) {
        // استخراج كود الدولة من الرقم الكامل
        final phone = profile.phone!;
        if (phone.startsWith('+')) {
          // محاولة استخراج كود الدولة (أول 2-4 أرقام بعد +)
          final match = RegExp(r'^\+(\d{1,4})(.*)').firstMatch(phone);
          if (match != null) {
            _countryDialCode = '+${match.group(1)}';
            _phoneCtrl.text = match.group(2) ?? '';
          } else {
            _phoneCtrl.text = phone;
          }
        } else {
          _phoneCtrl.text = phone;
        }
      }



      if (_isInstructor) {
        _displayNameCtrl.text = profile.displayName ?? profile.name;
        _headlineArCtrl.text = profile.headlineAr ?? '';
        _headlineEnCtrl.text = profile.headlineEn ?? '';
        _bioArCtrl.text = profile.bioAr ?? '';
        _bioEnCtrl.text = profile.bioEn ?? '';
        _expertiseCtrl.text = (profile.expertise ?? []).join(', ');
        _websiteUrlCtrl.text = profile.websiteUrl ?? '';
        _currentCoverImageUrl = profile.coverImageUrl;

        final socialLinks = profile.socialLinks ?? {};
        _facebookCtrl.text = socialLinks['facebook'] ?? '';
        _twitterCtrl.text = socialLinks['twitter'] ?? '';
        _linkedinCtrl.text = socialLinks['linkedin'] ?? '';
        _youtubeCtrl.text = socialLinks['youtube'] ?? '';
        _websiteCtrl.text = socialLinks['website'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _displayNameCtrl.dispose();
    _headlineArCtrl.dispose();
    _headlineEnCtrl.dispose();
    _bioArCtrl.dispose();
    _bioEnCtrl.dispose();
    _expertiseCtrl.dispose();
    _websiteUrlCtrl.dispose();
    _facebookCtrl.dispose();
    _twitterCtrl.dispose();
    _linkedinCtrl.dispose();
    _youtubeCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final bytes = await pickImage();
    if (bytes != null) {
      setState(() => _avatarBytes = bytes);
    }
  }

  Future<void> _pickCoverImage() async {
    final bytes = await pickImage();
    if (bytes != null) {
      setState(() => _coverImageBytes = bytes);
    }
  }

  Future<String> _uploadImageToAvatarBucket({
    required Uint8List bytes,
    required String userId,
    required String fileName,
  }) async {
    final client = Supabase.instance.client;
    final storagePath = '$userId/$fileName';

    await client.storage.from('avatars').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final publicUrl = client.storage.from('avatars').getPublicUrl(storagePath);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    List<String>? expertise;
    if (_isInstructor && _expertiseCtrl.text.trim().isNotEmpty) {
      expertise = _expertiseCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    Map<String, String>? socialLinks;
    if (_isInstructor) {
      socialLinks = {};
      if (_facebookCtrl.text.trim().isNotEmpty) {
        socialLinks['facebook'] = _facebookCtrl.text.trim();
      }
      if (_twitterCtrl.text.trim().isNotEmpty) {
        socialLinks['twitter'] = _twitterCtrl.text.trim();
      }
      if (_linkedinCtrl.text.trim().isNotEmpty) {
        socialLinks['linkedin'] = _linkedinCtrl.text.trim();
      }
      if (_youtubeCtrl.text.trim().isNotEmpty) {
        socialLinks['youtube'] = _youtubeCtrl.text.trim();
      }
      if (_websiteCtrl.text.trim().isNotEmpty) {
        socialLinks['website'] = _websiteCtrl.text.trim();
      }
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showError('errors.unknown'.tr());
      }
      return;
    }

    String? avatarUrl;
    String? coverImageUrl;
    try {
      if (_avatarBytes != null) {
        avatarUrl = await _uploadImageToAvatarBucket(
          bytes: _avatarBytes!,
          userId: userId,
          fileName: 'avatar.jpg',
        );
      }

      if (_isInstructor && _coverImageBytes != null) {
        coverImageUrl = await _uploadImageToAvatarBucket(
          bytes: _coverImageBytes!,
          userId: userId,
          fileName: 'cover.jpg',
        );
      }
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showError('errors.unknown'.tr());
      }
      return;
    }

    if (!mounted) return;

    final success = await context.read<ProfileCubit>().updateProfile(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isNotEmpty
              ? _buildFullPhone(_countryDialCode, _phoneCtrl.text.trim())
              : null,
          parentPhone: null,
          avatarUrl: avatarUrl,
          displayName: _isInstructor && _displayNameCtrl.text.trim().isNotEmpty
              ? _displayNameCtrl.text.trim()
              : null,
          headlineAr: _isInstructor && _headlineArCtrl.text.trim().isNotEmpty
              ? _headlineArCtrl.text.trim()
              : null,
          headlineEn: _isInstructor && _headlineEnCtrl.text.trim().isNotEmpty
              ? _headlineEnCtrl.text.trim()
              : null,
          bioAr: _isInstructor && _bioArCtrl.text.trim().isNotEmpty
              ? _bioArCtrl.text.trim()
              : null,
          bioEn: _isInstructor && _bioEnCtrl.text.trim().isNotEmpty
              ? _bioEnCtrl.text.trim()
              : null,
          websiteUrl: _isInstructor && _websiteUrlCtrl.text.trim().isNotEmpty
              ? _websiteUrlCtrl.text.trim()
              : null,
          coverImageUrl: coverImageUrl,
          expertise: expertise,
          socialLinks: socialLinks,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ToastUtils.showSuccess('profile.profile_updated'.tr());
      context.pop();
    } else if (mounted) {
      ToastUtils.showError('errors.unknown'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        title: Text(
          'profile.edit_profile'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        leading: const AppBackButton(),
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'common.save'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAvatarSection(isDark),
                  if (_isInstructor) ...[
                    const SizedBox(height: 24),
                    _buildCoverImageSection(isDark),
                  ],
                  const SizedBox(height: 32),
                  _buildBasicFields(isDark),
                  if (_isInstructor)
                    InstructorFormFields(
                      displayNameCtrl: _displayNameCtrl,
                      headlineArCtrl: _headlineArCtrl,
                      headlineEnCtrl: _headlineEnCtrl,
                      bioArCtrl: _bioArCtrl,
                      bioEnCtrl: _bioEnCtrl,
                      expertiseCtrl: _expertiseCtrl,
                      websiteUrlCtrl: _websiteUrlCtrl,
                      facebookCtrl: _facebookCtrl,
                      twitterCtrl: _twitterCtrl,
                      linkedinCtrl: _linkedinCtrl,
                      youtubeCtrl: _youtubeCtrl,
                      websiteCtrl: _websiteCtrl,
                      isDark: isDark,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: isDark
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : (_currentAvatarUrl != null
                          ? NetworkImage(_currentAvatarUrl!)
                          : null),
                  child: _avatarBytes == null && _currentAvatarUrl == null
                      ? const Icon(Icons.person,
                          size: 55, color: AppColors.primary)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'auth.change_avatar'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
        ),
      ],
    );
  }

  /// بناء رقم الهاتف الكامل مع كود الدولة (مع التنظيف والتحقق)
  String? _buildFullPhone(String dialCode, String localPhone) {
    final fullPhone = '$dialCode$localPhone';
    final normalized = PhoneUtils.normalizeWhatsappNumber(fullPhone);
    return normalized != null ? '+$normalized' : null;
  }

  Widget _buildBasicFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          controller: _nameCtrl,
          label: 'auth.name'.tr(),
          hint: 'auth.name_placeholder'.tr(),
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'auth.name_required'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildPhoneFieldWithCountryCode(isDark),
      ],
    );
  }

  Widget _buildPhoneFieldWithCountryCode(bool isDark) {
    return PhoneInputField(
      controller: _phoneCtrl,
      label: 'auth.phone'.tr(),
      onCountryCodeChanged: (code) {
        setState(() {
          _countryDialCode = code;
        });
      },
    );
  }

  Widget _buildCoverImageSection(bool isDark) {
    final isArabic = context.locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'صورة الغلاف' : 'Cover Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              image: _coverImageBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_coverImageBytes!),
                      fit: BoxFit.cover,
                    )
                  : (_currentCoverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_currentCoverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null),
            ),
            child: _coverImageBytes == null && _currentCoverImageUrl == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'اضغط لإضافة صورة غلاف'
                            : 'Tap to add cover image',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
