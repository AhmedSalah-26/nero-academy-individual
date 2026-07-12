import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';

/// Wishlist Empty State - Shown when wishlist is empty
class WishlistEmptyState extends StatelessWidget {
  final VoidCallback onBrowseCourses;
  final bool isDark;

  const WishlistEmptyState({
    super.key,
    required this.onBrowseCourses,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      type: EmptyStateType.wishlist,
      onAction: onBrowseCourses,
    );
  }
}
