import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';

/// Announcements Bottom Sheet Widget
class AnnouncementsSheet extends StatelessWidget {
  final bool isDark;

  const AnnouncementsSheet({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHandle(),
        _buildHeader(context),
        const SizedBox(height: 16),
        Expanded(
          child: _buildEmptyState(),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey600 : AppColors.grey300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'course_player.announcements'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        type: EmptyStateType.announcements,
      ),
    );
  }
}
