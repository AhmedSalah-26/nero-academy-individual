import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../domain/entities/user_entity.dart';
import 'register_stages/stage_basic_info.dart';
import 'register_stages/stage_contact_info.dart';
import 'register_stages/stage_password.dart';
import 'register_stages/stage_profile_photo.dart';

enum _RegisterStageType {
  basicInfo,
  contactInfo,
  password,
  profilePhoto,
}

class MultiStageRegister extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmPassCtrl;
  final TextEditingController? headlineCtrl;
  final TextEditingController? bioCtrl;
  final Uint8List? avatarBytes;
  final VoidCallback? onPickAvatar;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final bool isDark;
  final ValueChanged<String>? onCountryCodeChanged;
  final VoidCallback onComplete;
  final bool isSubmitting;

  const MultiStageRegister({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmPassCtrl,
    this.headlineCtrl,
    this.bioCtrl,
    this.avatarBytes,
    this.onPickAvatar,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.isDark,
    this.onCountryCodeChanged,
    required this.onComplete,
    this.isSubmitting = false,
  });

  @override
  State<MultiStageRegister> createState() => _MultiStageRegisterState();
}

class _MultiStageRegisterState extends State<MultiStageRegister> {
  int _currentStage = 0;
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _contactInfoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isCheckingEmail = false;
  String? _lastCheckedEmail;
  bool? _lastCheckedEmailAvailable;

  List<_RegisterStageType> get _stageTypes {
    return const <_RegisterStageType>[
      _RegisterStageType.basicInfo,
      _RegisterStageType.contactInfo,
      _RegisterStageType.password,
      _RegisterStageType.profilePhoto,
    ];
  }

  _RegisterStageType get _currentStageType => _stageTypes[_currentStage];

  int get _totalStages {
    return _stageTypes.length;
  }

  Future<void> _nextStage() async {
    if (_currentStage < _totalStages - 1) {
      // Validate current stage
      final isValid = await _validateCurrentStage();
      if (!isValid) return;

      if (!mounted) return;
      setState(() => _currentStage++);
    } else {
      // Last stage - submit
      if (await _validateCurrentStage()) {
        widget.onComplete();
      }
    }
  }

  void _previousStage() {
    if (_currentStage > 0) {
      setState(() => _currentStage--);
    }
  }

  Future<bool> _validateCurrentStage() async {
    switch (_currentStageType) {
      case _RegisterStageType.basicInfo:
        return _basicInfoFormKey.currentState?.validate() ?? false;
      case _RegisterStageType.contactInfo:
        final isFormValid =
            _contactInfoFormKey.currentState?.validate() ?? false;
        if (!isFormValid) return false;
        return _validateEmailAvailability();
      case _RegisterStageType.password:
        return _passwordFormKey.currentState?.validate() ?? false;
      case _RegisterStageType.profilePhoto:
        return true;
    }
  }

  Future<bool> _validateEmailAvailability() async {
    final email = widget.emailCtrl.text.trim().toLowerCase();

    if (_lastCheckedEmail == email && _lastCheckedEmailAvailable != null) {
      if (_lastCheckedEmailAvailable == false) {
        ToastUtils.showError('auth.errors.email_already_in_use'.tr());
      }
      return _lastCheckedEmailAvailable!;
    }

    setState(() => _isCheckingEmail = true);

    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .ilike('email', email)
          .limit(1);

      final isTaken = result.isNotEmpty;
      _lastCheckedEmail = email;
      _lastCheckedEmailAvailable = !isTaken;

      if (isTaken) {
        ToastUtils.showError('auth.errors.email_already_in_use'.tr());
        return false;
      }

      return true;
    } catch (e) {
      // RLS or network error — don't block the user.
      // Supabase Auth will reject duplicate emails during actual sign-up.
      AppLogger.w('[Register] Email check failed (RLS/network): $e — allowing user to proceed');
      return true;
    } finally {
      if (mounted) {
        setState(() => _isCheckingEmail = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),
        const SizedBox(height: 24),

        // Current Stage
        _getCurrentStage(),

        const SizedBox(height: 32),

        // Next/Create button
        _buildNextButton(),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _getCurrentStage() {
    switch (_currentStageType) {
      case _RegisterStageType.basicInfo:
        return Form(
          key: _basicInfoFormKey,
          child: StageBasicInfo(
            key: const ValueKey('stage_basic_info'),
            nameCtrl: widget.nameCtrl,
            isDark: widget.isDark,
          ),
        );
      case _RegisterStageType.contactInfo:
        return Form(
          key: _contactInfoFormKey,
          child: StageContactInfo(
            key: const ValueKey('stage_contact_info'),
            emailCtrl: widget.emailCtrl,
            phoneCtrl: widget.phoneCtrl,
            isDark: widget.isDark,
            onCountryCodeChanged: widget.onCountryCodeChanged,
          ),
        );
      case _RegisterStageType.password:
        return Form(
          key: _passwordFormKey,
          child: StagePassword(
            key: const ValueKey('stage_password'),
            passCtrl: widget.passCtrl,
            confirmPassCtrl: widget.confirmPassCtrl,
            obscurePassword: widget.obscurePassword,
            obscureConfirmPassword: widget.obscureConfirmPassword,
            onTogglePassword: widget.onTogglePassword,
            onToggleConfirmPassword: widget.onToggleConfirmPassword,
            isDark: widget.isDark,
          ),
        );
      case _RegisterStageType.profilePhoto:
        return StageProfilePhoto(
          avatarBytes: widget.avatarBytes,
          onPickAvatar: widget.onPickAvatar,
          isDark: widget.isDark,
        );
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (_currentStage > 0)
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color:
                    widget.isDark ? AppColors.white : AppColors.textMainLight,
              ),
              onPressed: _previousStage,
            ),
          Expanded(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStage + 1) / _totalStages,
                  backgroundColor:
                      widget.isDark ? AppColors.grey700 : AppColors.grey200,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentStage + 1} ${'auth.of'.tr()} $_totalStages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        widget.isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastStage = _currentStage == _totalStages - 1;
    final isSubmitting = _isCheckingEmail || widget.isSubmitting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _nextStage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStage
                          ? 'auth.create_account'.tr()
                          : 'common.next'.tr(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStage
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
