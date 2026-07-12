import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Toast Utilities - Show toast messages
class ToastUtils {
  ToastUtils._();

  static void showSuccess(String message, {String? title}) {
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: AppColors.success,
      foregroundColor: AppColors.white,
      primaryColor: AppColors.white,
      icon: const Icon(Icons.check_circle, color: AppColors.white),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.none,
    );
  }

  static void showError(String message, {String? title}) {
    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.white,
      primaryColor: AppColors.white,
      icon: const Icon(Icons.error, color: AppColors.white),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.none,
    );
  }

  static void showWarning(String message, {String? title}) {
    toastification.show(
      type: ToastificationType.warning,
      style: ToastificationStyle.flat,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: AppColors.warning,
      foregroundColor: AppColors.white,
      primaryColor: AppColors.white,
      icon: const Icon(Icons.warning, color: AppColors.white),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.none,
    );
  }

  static void showInfo(String message, {String? title}) {
    toastification.show(
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: AppColors.info,
      foregroundColor: AppColors.white,
      primaryColor: AppColors.white,
      icon: const Icon(Icons.info, color: AppColors.white),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.none,
    );
  }

  static void showNetworkError() {
    showError('لا يوجد اتصال بالإنترنت');
  }
}
