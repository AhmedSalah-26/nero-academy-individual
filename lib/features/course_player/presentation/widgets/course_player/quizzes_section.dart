import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../../../core/shared_widgets/empty_state.dart';
import '../../../../../core/shared_widgets/loading_state.dart';
import '../../../domain/entities/section_entity.dart';
import '../../../../quizzes/domain/entities/quiz_entity.dart';
import '../../../../quizzes/domain/repositories/quizzes_repository.dart';

/// Quizzes Section Widget - Shows all quizzes for the course
class QuizzesSection extends StatefulWidget {
  final bool isDark;
  final String courseId;
  final List<SectionEntity> sections;
  final QuizzesRepository repository;
  final Function(QuizEntity quiz) onQuizTap;

  const QuizzesSection({
    super.key,
    required this.isDark,
    required this.courseId,
    required this.sections,
    required this.repository,
    required this.onQuizTap,
  });

  @override
  State<QuizzesSection> createState() => _QuizzesSectionState();
}

class _QuizzesSectionState extends State<QuizzesSection> {
  late Future<List<QuizEntity>> _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() {
    _quizzesFuture = _fetchQuizzes();
  }

  Future<List<QuizEntity>> _fetchQuizzes() async {
    AppLogger.i(
        '📝 [QuizzesSection] Loading quizzes for course: ${widget.courseId}');
    final result =
        await widget.repository.getCourseQuizzes(courseId: widget.courseId);
    return result.fold(
      (failure) {
        AppLogger.e('[QuizzesSection] Failed: ${failure.message}');
        return [];
      },
      (quizzes) {
        AppLogger.success('[QuizzesSection] Loaded ${quizzes.length} quizzes');
        return quizzes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuizEntity>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: AppLoadingState.section(),
          );
        }

        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) return _buildEmptyState();

        final lessonQuizzes =
            quizzes.where((quiz) => !quiz.isCourseLevelQuiz).toList();
        final courseQuizzes =
            quizzes.where((quiz) => quiz.isCourseLevelQuiz).toList();
        final lessonQuizGroups = _groupLessonQuizzes(lessonQuizzes);

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (lessonQuizzes.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'اختبارات الدروس',
                subtitle: 'اختبارات مرتبطة بدروس محددة داخل الكورس',
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 12),
              ...lessonQuizGroups.map(_buildLessonQuizGroup),
              const SizedBox(height: 20),
            ],
            if (courseQuizzes.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'اختبار شامل',
                subtitle: 'اختبارات على محتوى الكورس بالكامل',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),
              ...courseQuizzes.map(_buildQuizItem),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        type: EmptyStateType.quizzes,
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color:
                      widget.isDark ? AppColors.white : AppColors.textMainLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_LessonQuizGroup> _groupLessonQuizzes(List<QuizEntity> lessonQuizzes) {
    final quizzesByLessonId = <String, List<QuizEntity>>{};
    final orphanQuizzes = <QuizEntity>[];

    for (final quiz in lessonQuizzes) {
      final lessonId = quiz.lessonId;
      if (lessonId == null || lessonId.trim().isEmpty) {
        orphanQuizzes.add(quiz);
        continue;
      }
      quizzesByLessonId.putIfAbsent(lessonId, () => []).add(quiz);
    }

    final groups = <_LessonQuizGroup>[];
    for (final section in widget.sections) {
      for (final lesson in section.lessons) {
        final quizzes = quizzesByLessonId.remove(lesson.id);
        if (quizzes == null || quizzes.isEmpty) continue;
        groups.add(_LessonQuizGroup(
          lessonId: lesson.id,
          lessonTitleAr: lesson.titleAr,
          lessonTitleEn: lesson.titleEn,
          quizzes: quizzes,
        ));
      }
    }

    for (final entry in quizzesByLessonId.entries) {
      groups.add(_LessonQuizGroup(
        lessonId: entry.key,
        lessonTitleAr: 'درس غير موجود',
        lessonTitleEn: 'Missing lesson',
        quizzes: entry.value,
      ));
    }

    if (orphanQuizzes.isNotEmpty) {
      groups.add(_LessonQuizGroup(
        lessonId: 'unassigned',
        lessonTitleAr: 'اختبارات غير مرتبطة',
        lessonTitleEn: 'Unassigned quizzes',
        quizzes: orphanQuizzes,
      ));
    }

    return groups;
  }

  Widget _buildLessonQuizGroup(_LessonQuizGroup group) {
    final locale = Localizations.localeOf(context).languageCode;
    final quizCount = group.quizzes.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_lesson_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          title: Text(
            group.getLessonTitle(locale),
            style: TextStyle(
              color: widget.isDark ? AppColors.white : AppColors.textMainLight,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$quizCount ${quizCount == 1 ? 'اختبار' : 'اختبارات'}',
              style: TextStyle(
                color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor:
              widget.isDark ? AppColors.grey400 : AppColors.grey600,
          children: group.quizzes.map(_buildQuizItem).toList(),
        ),
      ),
    );
  }

  Widget _buildQuizItem(QuizEntity quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.surfaceDark
            : AppColors.backgroundLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onQuizTap(quiz),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildQuizIcon(quiz),
                const SizedBox(width: 12),
                Expanded(child: _buildQuizInfo(quiz)),
                _buildQuizStatus(quiz),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizIcon(QuizEntity quiz) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.quiz,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildQuizInfo(QuizEntity quiz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quiz.titleAr,
          style: TextStyle(
            color: widget.isDark ? AppColors.white : AppColors.textMainLight,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        if (!quiz.isCourseLevelQuiz) ...[
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 14,
                color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
              ),
              const SizedBox(width: 4),
              Text(
                'اختبار درس',
                style: TextStyle(
                  color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(
              Icons.help_outline,
              size: 14,
              color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              '${quiz.totalQuestions} ${'course_player.questions'.tr()}',
              style: TextStyle(
                color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              quiz.hasTimeLimit
                  ? '${quiz.timeLimit} ${'course_player.minutes'.tr()}'
                  : 'quiz.no_limit'.tr(),
              style: TextStyle(
                color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${'course_player.passing_score'.tr()}: ${quiz.passingScore}%',
          style: TextStyle(
            color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStatus(QuizEntity quiz) {
    if (quiz.isScheduled) {
      return const Icon(Icons.schedule_rounded, color: AppColors.warning);
    }
    if (quiz.isExpired) {
      return const Icon(Icons.lock_clock_rounded, color: AppColors.error);
    }
    return Icon(
      Icons.chevron_right,
      color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
    );
  }
}

class _LessonQuizGroup {
  final String lessonId;
  final String lessonTitleAr;
  final String? lessonTitleEn;
  final List<QuizEntity> quizzes;

  const _LessonQuizGroup({
    required this.lessonId,
    required this.lessonTitleAr,
    required this.lessonTitleEn,
    required this.quizzes,
  });

  String getLessonTitle(String locale) {
    if (locale == 'en' && lessonTitleEn != null && lessonTitleEn!.isNotEmpty) {
      return lessonTitleEn!;
    }
    return lessonTitleAr;
  }
}
