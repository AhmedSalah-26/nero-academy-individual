import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';

/// Cart Error State Widget
class CartErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const CartErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      type: ErrorType.generic,
      message: message,
      onRetry: onRetry,
    );
  }
}
