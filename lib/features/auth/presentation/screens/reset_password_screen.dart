import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/shared_widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isDone = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _readSupabaseLinkError();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _readSupabaseLinkError() {
    final uri = Uri.base;
    final params = <String, String>{
      ...uri.queryParameters,
      ...Uri.splitQueryString(
        uri.fragment.startsWith('/') ? '' : uri.fragment,
      ),
    };

    final errorDescription = params['error_description'];
    if (errorDescription == null || errorDescription.isEmpty) return;

    setState(() {
      _errorMessage = errorDescription.replaceAll('+', ' ');
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      if (response.user == null) {
        throw AuthException('auth.reset_link_invalid'.tr());
      }

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      setState(() {
        _isDone = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'auth.reset_password_failed'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: _isDone
                    ? _buildDoneContent(context, isDark)
                    : _buildFormContent(context, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneContent(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 52,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'auth.reset_password_done_title'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'auth.reset_password_done_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.5,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'auth.login'.tr(),
          icon: Icons.login_rounded,
          isFullWidth: true,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildFormContent(BuildContext context, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'auth.reset_password_new_title'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'auth.reset_password_new_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _MessageBox(message: _errorMessage!, isError: true),
          ],
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'auth.new_password'.tr(),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
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
            validator: (value) {
              if (value == null || value.trim().length < 8) {
                return 'auth.password_min_8'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'auth.confirm_password'.tr(),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'auth.passwords_dont_match'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          AppButton(
            text: 'auth.change_password'.tr(),
            icon: Icons.check_rounded,
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
