import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

class SignupProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isDark;

  const SignupProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              backgroundColor: isDark ? AppColors.grey700 : AppColors.grey200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${currentStep + 1} ${'auth.of'.tr()} $totalSteps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
