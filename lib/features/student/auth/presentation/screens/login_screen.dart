// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/utils/toast_utils.dart';
import 'package:lms_platform/core/utils/validators.dart';
import 'package:lms_platform/features/student/settings/presentation/cubit/settings_cubit.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms_platform/features/student/auth/presentation/cubit/auth_state.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/auth_tab_bar.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/auth_text_field.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/avatar_picker.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/multi_stage_register.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _emailOtpCtrl = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;
  bool _obscureConfirm = true;
  UserRole _role = UserRole.student;
  Uint8List? _avatarBytes;
  String _countryDialCode = '+20';
  bool _showAwaitingVerification = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _emailOtpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final bytes = await pickImage();
    if (bytes != null) {
      setState(() => _avatarBytes = bytes);
    }
  }

  Future<void> _loadSettingsAndNavigate(
      BuildContext context, String route) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await sl<SettingsCubit>().loadSettings(userId);
    }
    if (mounted) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode.toLowerCase() == 'ar';
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (ctx, state) {
          if (state.isError && state.errorMessage != null) {
            final isCurrent = ModalRoute.of(ctx)?.isCurrent ?? false;
            if (isCurrent) {
              ToastUtils.showError(state.errorMessage!.tr());
              ctx.read<AuthCubit>().clearError();
            }
          }
          if (state.isAwaitingEmailVerification) {
            setState(() {
              _showAwaitingVerification = true;
            });
          }
          if (state.needsInterests) {
            _loadSettingsAndNavigate(ctx, '/interests');
          } else if (state.isLoggedIn && state.user != null) {
            final user = state.user!;
            if (user.isAdmin) {
              _loadSettingsAndNavigate(ctx, '/admin');
            } else if (user.isInstructor) {
              _loadSettingsAndNavigate(ctx, '/instructor');
            } else {
              _loadSettingsAndNavigate(ctx, '/home');
            }
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SizedBox(
                        width: double.infinity,
                        child: _showAwaitingVerification
                            ? _buildAwaitingVerificationView(isDark)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 32),
                                  FadeIn(
                                    duration: const Duration(milliseconds: 600),
                                    child: _titleSection(
                                      isDark,
                                      isArabic,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SlideFadeIn.fromBottom(
                                    delay: const Duration(milliseconds: 200),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: AuthTabBar(
                                        isLogin: _isLogin,
                                        loginLabel: 'auth.login'.tr(),
                                        registerLabel: 'auth.register'.tr(),
                                        onChanged: (v) =>
                                            setState(() => _isLogin = v),
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SlideFadeIn.fromBottom(
                                    delay: const Duration(milliseconds: 300),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: _isLogin
                                          ? Form(
                                              key: _formKey,
                                              child: Column(
                                                children: [
                                                  _loginForm(isDark),
                                                  const SizedBox(height: 24),
                                                  _submitBtn(),
                                                  const SizedBox(height: 16),
                                                  _googleAuthSection(),
                                                  const SizedBox(height: 32),
                                                  _terms(),
                                                ],
                                              ),
                                            )
                                          : MultiStageRegister(
                                              nameCtrl: _nameCtrl,
                                              phoneCtrl: _phoneCtrl,
                                              emailCtrl: _emailCtrl,
                                              passCtrl: _passCtrl,
                                              confirmPassCtrl: _confirmPassCtrl,
                                              headlineCtrl: _headlineCtrl,
                                              bioCtrl: _bioCtrl,
                                              avatarBytes: _avatarBytes,
                                              onPickAvatar: _pickAvatar,
                                              obscurePassword: _obscure,
                                              obscureConfirmPassword:
                                                  _obscureConfirm,
                                              onTogglePassword: () => setState(
                                                  () => _obscure = !_obscure),
                                              onToggleConfirmPassword: () =>
                                                  setState(() =>
                                                      _obscureConfirm =
                                                          !_obscureConfirm),
                                              selectedRole: _role,
                                              onRoleChanged: (_) => setState(
                                                  () =>
                                                      _role = UserRole.student),
                                              onCountryCodeChanged: (code) =>
                                                  setState(() =>
                                                      _countryDialCode = code),
                                              isDark: isDark,
                                              isSubmitting: false,
                                              onComplete: _submit,
                                            ),
                                    ),
                                  ),
                                  if (!_isLogin) ...[
                                    const SizedBox(height: 16),
                                    FadeIn(
                                      delay: const Duration(milliseconds: 350),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: _googleAuthSection(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FadeIn(
                                      delay: const Duration(milliseconds: 400),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: _terms(),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _titleSection(bool d, bool isArabic) => Column(
        children: [
          _brandNameText(d),
          const SizedBox(height: 14),
          Text(
            _isLogin ? 'auth.login'.tr() : 'auth.join_community'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: d ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? 'auth.login_subtitle'.tr()
                : 'auth.create_account_subtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: d ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
        ],
      );

  Widget _brandNameText(bool isDark) {
    final gradient = isDark
        ? const LinearGradient(
            colors: [
              AppColors.primaryOnDark,
              AppColors.primary,
              AppColors.primaryLight,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : const LinearGradient(
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryOnDark,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        'app_name'.tr(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Almarai',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _loginForm(bool d) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            controller: _emailCtrl,
            label: 'auth.email'.tr(),
            hint: 'auth.email_placeholder'.tr(),
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            isDark: d,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passCtrl,
            label: 'auth.password'.tr(),
            hint: 'auth.password_placeholder'.tr(),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            isDark: d,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.grey400,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => Validators.password(v, minLength: 8),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'auth.forgot_password'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _submitBtn() => BlocBuilder<AuthCubit, AuthState>(
        builder: (_, s) => SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: s.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: s.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin
                            ? 'auth.login'.tr()
                            : 'auth.create_account'.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      );

  Widget _googleAuthSection() => BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return SocialLoginButtons(
            isLoading: state.isLoading,
            showApple: false,
            showFacebook: false,
            googleLabel: _isLogin
                ? (context.locale.languageCode == 'ar'
                    ? 'الدخول بحساب Google'
                    : 'Continue with Google')
                : (context.locale.languageCode == 'ar'
                    ? 'التسجيل بحساب Google'
                    : 'Sign up with Google'),
            onGoogleTap: () => context.read<AuthCubit>().loginWithGoogle(),
          );
        },
      );

  Widget _terms() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text.rich(
          TextSpan(
            text: '${'auth.terms_text'.tr()} ',
            style: const TextStyle(fontSize: 12, color: AppColors.grey400),
            children: [
              TextSpan(
                text: 'auth.terms_of_service'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' ${'auth.and'.tr()} '),
              TextSpan(
                text: 'auth.privacy_policy'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      );

  void _submit() {
    // Only validate form for login, register has its own validation per stage
    if (_isLogin && !_formKey.currentState!.validate()) return;

    final c = context.read<AuthCubit>();
    if (_isLogin) {
      c.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    } else {
      c.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
        phone: _getFullPhoneNumber(),
        role: UserRole.student,
        headline: null,
        bio: null,
        avatarBytes: _avatarBytes,
      );
    }
  }

  String? _getFullPhoneNumber() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return null;
    final cleanDialCode = _countryDialCode.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$cleanDialCode$cleanPhone';
  }

  Widget _buildAwaitingVerificationView(bool isDark) {
    final email = _emailCtrl.text.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Card(
        color: isDark ? AppColors.cardDark : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'تأكيد الحساب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'لقد أرسلنا رمز تفعيل (OTP) إلى البريد الإلكتروني:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.grey300 : AppColors.grey600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: _emailOtpCtrl,
                label: 'رمز التحقق (OTP)',
                hint: 'أدخل الرمز المكون من 6 أرقام',
                icon: Icons.security_rounded,
                keyboardType: TextInputType.number,
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.trim().length != 6) {
                    return 'الرمز يجب أن يتكون من 6 أرقام';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              final otp = _emailOtpCtrl.text.trim();
                              if (otp.length == 6) {
                                context.read<AuthCubit>().verifyEmailOtp(
                                      email: email,
                                      otp: otp,
                                    );
                              } else {
                                ToastUtils.showError(
                                    'يرجى إدخال رمز التحقق المكون من 6 أرقام');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'تأكيد الرمز وتفعيل الحساب',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final success = await context
                                  .read<AuthCubit>()
                                  .resendVerificationEmail(email);
                              if (success) {
                                ToastUtils.showSuccess(
                                    'تم إعادة إرسال رمز التحقق بنجاح!');
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            )
                          : const Text(
                              'إعادة إرسال رمز التحقق (OTP)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAwaitingVerification = false;
                    _isLogin = true;
                  });
                },
                child: const Text(
                  'الرجوع لتسجيل الدخول',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
