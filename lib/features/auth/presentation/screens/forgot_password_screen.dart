import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isResetting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.isError && state.errorMessage != null) {
            final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
            if (isCurrent) {
              ToastUtils.showError(state.errorMessage!.tr());
              context.read<AuthCubit>().clearError();
            }
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _codeSent
                    ? _buildResetContent(isDark)
                    : _buildEmailContent(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailContent(bool isDark) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeaderIcon(Icons.mark_email_unread_rounded),
          const SizedBox(height: 32),
          _buildTitle('auth.reset_password'.tr(), isDark),
          const SizedBox(height: 12),
          _buildSubtitle('auth.reset_otp_subtitle'.tr(), isDark),
          const SizedBox(height: 32),
          _buildEmailField(isDark),
          const SizedBox(height: 24),
          _buildSendCodeButton(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'auth.back_to_login'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetContent(bool isDark) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeaderIcon(Icons.lock_reset_rounded),
          const SizedBox(height: 32),
          _buildTitle('auth.reset_password'.tr(), isDark),
          const SizedBox(height: 12),
          _buildSubtitle('auth.enter_reset_code'.tr(), isDark),
          const SizedBox(height: 8),
          Text(
            _emailController.text.trim(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 28),
          _buildOtpField(isDark),
          const SizedBox(height: 16),
          _buildPasswordField(isDark),
          const SizedBox(height: 16),
          _buildConfirmPasswordField(isDark),
          const SizedBox(height: 24),
          _buildResetButton(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isResetting ? null : _resendCode,
            child: Text(
              'auth.resend_code'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: AppColors.primary),
    );
  }

  Widget _buildTitle(String text, bool isDark) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.white : AppColors.textMainLight,
      ),
    );
  }

  Widget _buildSubtitle(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.grey400 : AppColors.grey500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailField(bool isDark) {
    return _buildLabeledField(
      isDark: isDark,
      label: 'auth.email'.tr(),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: Validators.email,
        style: _inputTextStyle(isDark),
        decoration: _inputDecoration(
          isDark: isDark,
          hintText: 'auth.email_placeholder'.tr(),
          icon: Icons.mail_outline_rounded,
        ),
      ),
    );
  }

  Widget _buildOtpField(bool isDark) {
    return _buildLabeledField(
      isDark: isDark,
      label: 'auth.otp_code'.tr(),
      child: TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'auth.otp_required'.tr();
          }
          return null;
        },
        style: _inputTextStyle(isDark),
        decoration: _inputDecoration(
          isDark: isDark,
          hintText: 'auth.otp_code_hint'.tr(),
          icon: Icons.pin_outlined,
        ),
      ),
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return _buildLabeledField(
      isDark: isDark,
      label: 'auth.new_password'.tr(),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.trim().length < 8) {
            return 'auth.password_min_8'.tr();
          }
          return null;
        },
        style: _inputTextStyle(isDark),
        decoration: _inputDecoration(
          isDark: isDark,
          hintText: 'auth.create_password_placeholder'.tr(),
          icon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(bool isDark) {
    return _buildLabeledField(
      isDark: isDark,
      label: 'auth.confirm_password'.tr(),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        validator: (value) {
          if (value != _passwordController.text) {
            return 'auth.passwords_dont_match'.tr();
          }
          return null;
        },
        style: _inputTextStyle(isDark),
        decoration: _inputDecoration(
          isDark: isDark,
          hintText: 'auth.confirm_password_placeholder'.tr(),
          icon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required bool isDark,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.grey300 : AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  TextStyle _inputTextStyle(bool isDark) {
    return TextStyle(
      fontSize: 16,
      color: isDark ? AppColors.white : AppColors.textMainLight,
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? AppColors.grey500 : AppColors.grey400,
      ),
      prefixIcon: Icon(
        icon,
        color: isDark ? AppColors.grey500 : AppColors.grey400,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.cardDark : Colors.white,
      border: _fieldBorder(isDark),
      enabledBorder: _fieldBorder(isDark),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(bool isDark) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? AppColors.grey700 : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildSendCodeButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return _PrimaryActionButton(
          isLoading: state.isLoading,
          text: 'auth.send_reset_code'.tr(),
          icon: Icons.send_rounded,
          onPressed: state.isLoading ? null : _sendCode,
        );
      },
    );
  }

  Widget _buildResetButton() {
    return _PrimaryActionButton(
      isLoading: _isResetting,
      text: 'auth.verify_and_change_password'.tr(),
      icon: Icons.check_rounded,
      onPressed: _isResetting ? null : _verifyOtpAndResetPassword,
    );
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final success = await context.read<AuthCubit>().forgotPassword(
          _emailController.text.trim(),
        );

    if (success && mounted) {
      setState(() => _codeSent = true);
      ToastUtils.showSuccess('auth.reset_otp_sent'.tr());
    }
  }

  Future<void> _resendCode() async {
    final success = await context.read<AuthCubit>().forgotPassword(
          _emailController.text.trim(),
        );

    if (success && mounted) {
      ToastUtils.showSuccess('auth.reset_otp_sent'.tr());
    }
  }

  Future<void> _verifyOtpAndResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isResetting = true);
    try {
      // Step 1: verify the OTP sent via signInWithOtp (type = email)
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
      );

      // Step 2: update password now that user is authenticated via OTP
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      ToastUtils.showSuccess('auth.reset_success'.tr());
      context.go('/login');
    } on AuthException catch (e) {
      if (mounted) ToastUtils.showError(e.message);
    } catch (e) {
      if (mounted) ToastUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.isLoading,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final bool isLoading;
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20),
                ],
              ),
      ),
    );
  }
}
