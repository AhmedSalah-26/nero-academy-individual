import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/user_avatar.dart';
import 'package:lms_platform/features/student/qa/domain/entities/qa_entity.dart';

/// Question Card Widget
class QuestionCard extends StatelessWidget {
  final QuestionEntity question;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onUpvote;

  const QuestionCard({
    super.key,
    required this.question,
    required this.isDark,
    required this.onTap,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTitle(),
            const SizedBox(height: 6),
            _buildContent(),
            const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        UserAvatar(
          imageUrl: question.userAvatar,
          name: question.userName,
          size: AvatarSize.sm,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.userName,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              Text(
                _formatTime(question.createdAt),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 11,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
              ),
            ],
          ),
        ),
        if (question.hasInstructorAnswer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'qa.instructor'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      question.title,
      style: TextStyle(
        fontFamily: 'Almarai',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.white : AppColors.textMainLight,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContent() {
    return Text(
      question.content,
      style: TextStyle(
        fontFamily: 'Almarai',
        fontSize: 13,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        QAActionButton(
          icon: question.isUpvotedByUser
              ? Icons.thumb_up_rounded
              : Icons.thumb_up_outlined,
          label: question.upvotes.toString(),
          isActive: question.isUpvotedByUser,
          onTap: onUpvote,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        QAActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${question.answersCount} ${'qa.answers'.tr()}',
          onTap: onTap,
          isDark: isDark,
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

/// Q&A Action Button
class QAActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const QAActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? AppColors.grey400 : AppColors.grey500),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 12,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.grey400 : AppColors.grey500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ask Question Form
class AskQuestionForm extends StatelessWidget {
  final bool isDark;

  const AskQuestionForm({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey600 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'qa.ask_question'.tr(),
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'qa.question_title'.tr(),
              hintText: 'qa.question_title_hint'.tr(),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'qa.question_details'.tr(),
              hintText: 'qa.question_details_hint'.tr(),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'qa.post_question'.tr(),
                style: const TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Answer Card Widget
class AnswerCard extends StatelessWidget {
  final AnswerEntity answer;
  final bool isDark;

  const AnswerCard({super.key, required this.answer, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isInstructor
            ? AppColors.success.withValues(alpha: 0.08)
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer.isInstructor
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                imageUrl: answer.userAvatar,
                name: answer.userName,
                size: AvatarSize.sm,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          answer.userName,
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.white
                                : AppColors.textMainLight,
                          ),
                        ),
                        if (answer.isInstructor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'qa.instructor'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Almarai',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (answer.isAccepted)
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer.content,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 14,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
