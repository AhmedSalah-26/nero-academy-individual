import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms_platform/features/student/auth/presentation/cubit/auth_state.dart';

class SignupBottomButtons extends StatelessWidget {
  final int currentStep;
  final bool isDark;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const SignupBottomButtons({
    super.key,
    required this.currentStep,
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (_, state) {
          return Row(
            children: [
              if (currentStep == 1)
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isLoading ? null : onPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side:
                          const BorderSide(color: AppColors.primary, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 56),
                    ),
                    child: Text(
                      'auth.previous'.tr(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (currentStep == 1) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : currentStep == 0
                          ? onNext
                          : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 56),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentStep == 0
                                  ? 'auth.next'.tr()
                                  : 'auth.create_account'.tr(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              currentStep == 0
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
