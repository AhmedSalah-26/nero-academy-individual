import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Help Topics Grid Widget
class HelpTopicsGrid extends StatelessWidget {
  final List<HelpTopic> topics;
  final ValueChanged<HelpTopic>? onTopicTap;
  final bool isDark;

  const HelpTopicsGrid({
    super.key,
    required this.topics,
    this.onTopicTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        return _buildTopicCard(topics[index]);
      },
    );
  }

  Widget _buildTopicCard(HelpTopic topic) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTopicTap?.call(topic),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.grey700 : AppColors.grey200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  topic.icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                topic.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Help Topic Model
class HelpTopic {
  final String id;
  final String title;
  final IconData icon;

  const HelpTopic({
    required this.id,
    required this.title,
    required this.icon,
  });
}
