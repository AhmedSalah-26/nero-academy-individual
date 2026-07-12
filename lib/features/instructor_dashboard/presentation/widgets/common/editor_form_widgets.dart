import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Common form card wrapper for editor screens
class EditorFormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final Widget child;

  const EditorFormCard({
    super.key,
    required this.icon,
    required this.title,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Info card with colored background
class EditorInfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isDark;

  const EditorInfoCard({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hint box widget
class EditorHintBox extends StatelessWidget {
  final String text;
  final bool isDark;

  const EditorHintBox({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor form actions (Cancel + Save buttons)
class EditorFormActions extends StatelessWidget {
  final bool isLoading;
  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const EditorFormActions({
    super.key,
    required this.isLoading,
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        saveLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Selected course chip widget
class SelectedCourseChip extends StatelessWidget {
  final String title;
  final String? thumbnailUrl;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onRemove;

  const SelectedCourseChip({
    super.key,
    required this.title,
    this.thumbnailUrl,
    required this.isArabic,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                thumbnailUrl!,
                width: 50,
                height: 35,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          else
            _buildPlaceholder(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            tooltip: isArabic ? 'إزالة' : 'Remove',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 35,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.school,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }
}
