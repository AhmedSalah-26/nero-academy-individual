import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/app_logger.dart';

part 'instructor_quizzes_state.dart';

/// Instructor Quizzes Cubit
class InstructorQuizzesCubit extends Cubit<InstructorQuizzesState> {
  final SupabaseClient _supabase;
  int _currentPage = 1;
  static const int _pageSize = 20;
  static const _tag = 'InstructorQuizzesCubit';

  InstructorQuizzesCubit(this._supabase)
      : super(const InstructorQuizzesState());

  /// Load quizzes
  Future<void> loadQuizzes({bool refresh = false}) async {
    AppLogger.i('📝 [$_tag] loadQuizzes: refresh=$refresh');

    if (refresh) {
      _currentPage = 1;
      emit(state.copyWith(
        status: InstructorQuizzesStatus.loading,
        quizzes: [],
        hasMore: true,
      ));
    } else if (state.status == InstructorQuizzesStatus.initial) {
      emit(state.copyWith(status: InstructorQuizzesStatus.loading));
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.e('[$_tag] User not authenticated');
        throw Exception('User not authenticated');
      }

      AppLogger.d('[$_tag] Loading quizzes for instructor: $userId');

      // Get instructor's courses first
      final coursesResponse = await _supabase
          .from('courses')
          .select('id')
          .eq('instructor_id', userId);

      final courseIds =
          (coursesResponse as List).map((c) => c['id'] as String).toList();

      AppLogger.d('[$_tag] Found ${courseIds.length} courses');

      if (courseIds.isEmpty) {
        AppLogger.w('[$_tag] No courses found for instructor');
        emit(state.copyWith(
          status: InstructorQuizzesStatus.success,
          quizzes: [],
          hasMore: false,
        ));
        return;
      }

      // Get quizzes for instructor's courses (course-level quizzes)
      final response = await _supabase
          .from('quizzes')
          .select('''
            *,
            course:courses!inner(id, title_ar, title_en, instructor_id)
          ''')
          .inFilter('course_id', courseIds)
          .order('created_at', ascending: false)
          .range(
            (_currentPage - 1) * _pageSize,
            _currentPage * _pageSize - 1,
          );

      AppLogger.d(
          '[$_tag] Raw quizzes response: ${(response as List).length} quizzes');

      final quizzes =
          response.map((q) => InstructorQuizModel.fromJson(q)).toList();

      AppLogger.success('[$_tag] Loaded ${quizzes.length} quizzes');

      emit(state.copyWith(
        status: InstructorQuizzesStatus.success,
        quizzes: refresh ? quizzes : [...state.quizzes, ...quizzes],
        hasMore: quizzes.length >= _pageSize,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadQuizzes error', e, s);
      emit(state.copyWith(
        status: InstructorQuizzesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more quizzes
  Future<void> loadMoreQuizzes() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    _currentPage++;
    await loadQuizzes();
    emit(state.copyWith(isLoadingMore: false));
  }

  /// Filter by course
  void filterByCourse(String? courseId) {
    emit(state.copyWith(selectedCourseId: courseId));
    loadQuizzes(refresh: true);
  }

  /// Create quiz. When lessonId is null, the quiz is course-level.
  Future<bool> createQuiz({
    required String courseId,
    String? sectionId,
    String? lessonId,
    required String titleAr,
    required String titleEn,
    String? descriptionAr,
    String? descriptionEn,
    required int passingScore,
    int? timeLimitMinutes,
    int? maxAttempts,
    DateTime? availableFrom,
    DateTime? availableUntil,
    bool shuffleQuestions = false,
    bool shuffleAnswers = false,
    bool showCorrectAnswers = true,
    bool isPublished = false,
  }) async {
    AppLogger.i('📝 [$_tag] createQuiz: courseId=$courseId, title=$titleAr');

    try {
      final insertData = {
        'course_id': courseId,
        'lesson_id': lessonId,
        'title_ar': titleAr,
        'title_en': titleEn,
        'description_ar': descriptionAr,
        'description_en': descriptionEn,
        'passing_score': passingScore,
        'time_limit': timeLimitMinutes,
        'max_attempts': maxAttempts,
        'available_from': availableFrom?.toUtc().toIso8601String(),
        'available_until': availableUntil?.toUtc().toIso8601String(),
        'shuffle_questions': shuffleQuestions,
        'shuffle_answers': shuffleAnswers,
        'show_correct_answers': showCorrectAnswers,
        'is_published': isPublished,
      };
      if (sectionId != null) insertData['section_id'] = sectionId;

      final response =
          await _supabase.from('quizzes').insert(insertData).select().single();

      AppLogger.success('[$_tag] Quiz created: ${response['id']}');
      await loadQuizzes(refresh: true);
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] createQuiz error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Update quiz
  Future<bool> updateQuiz({
    required String quizId,
    String? titleAr,
    String? titleEn,
    String? descriptionAr,
    String? descriptionEn,
    int? passingScore,
    int? timeLimitMinutes,
    int? maxAttempts,
    DateTime? availableFrom,
    DateTime? availableUntil,
    bool clearAvailableFrom = false,
    bool clearAvailableUntil = false,
    bool? shuffleQuestions,
    bool? shuffleAnswers,
    bool? showCorrectAnswers,
    bool? isPublished,
  }) async {
    AppLogger.i('📝 [$_tag] updateQuiz: quizId=$quizId');

    try {
      final updates = <String, dynamic>{};
      if (titleAr != null) updates['title_ar'] = titleAr;
      if (titleEn != null) updates['title_en'] = titleEn;
      if (descriptionAr != null) updates['description_ar'] = descriptionAr;
      if (descriptionEn != null) updates['description_en'] = descriptionEn;
      if (passingScore != null) updates['passing_score'] = passingScore;
      if (timeLimitMinutes != null) updates['time_limit'] = timeLimitMinutes;
      if (maxAttempts != null) updates['max_attempts'] = maxAttempts;
      if (clearAvailableFrom) {
        updates['available_from'] = null;
      } else if (availableFrom != null) {
        updates['available_from'] = availableFrom.toUtc().toIso8601String();
      }
      if (clearAvailableUntil) {
        updates['available_until'] = null;
      } else if (availableUntil != null) {
        updates['available_until'] = availableUntil.toUtc().toIso8601String();
      }
      if (shuffleQuestions != null) {
        updates['shuffle_questions'] = shuffleQuestions;
      }
      if (shuffleAnswers != null) updates['shuffle_answers'] = shuffleAnswers;
      if (showCorrectAnswers != null) {
        updates['show_correct_answers'] = showCorrectAnswers;
      }
      if (isPublished != null) updates['is_published'] = isPublished;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('quizzes').update(updates).eq('id', quizId);

      AppLogger.success('[$_tag] Quiz updated');
      await loadQuizzes(refresh: true);
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateQuiz error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  Future<bool> toggleQuizPublished(String quizId, bool isPublished) async {
    AppLogger.i(
        'ðŸ“ [$_tag] toggleQuizPublished: quizId=$quizId, isPublished=$isPublished');

    try {
      await _supabase.from('quizzes').update({
        'is_published': isPublished,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', quizId);

      final updatedQuizzes = state.quizzes.map((quiz) {
        if (quiz.id != quizId) return quiz;
        return InstructorQuizModel(
          id: quiz.id,
          courseId: quiz.courseId,
          sectionId: quiz.sectionId,
          lessonId: quiz.lessonId,
          courseTitleAr: quiz.courseTitleAr,
          courseTitleEn: quiz.courseTitleEn,
          titleAr: quiz.titleAr,
          titleEn: quiz.titleEn,
          descriptionAr: quiz.descriptionAr,
          descriptionEn: quiz.descriptionEn,
          passingScore: quiz.passingScore,
          timeLimitMinutes: quiz.timeLimitMinutes,
          maxAttempts: quiz.maxAttempts,
          shuffleQuestions: quiz.shuffleQuestions,
          shuffleAnswers: quiz.shuffleAnswers,
          showCorrectAnswers: quiz.showCorrectAnswers,
          questionsCount: quiz.questionsCount,
          totalPoints: quiz.totalPoints,
          attemptsCount: quiz.attemptsCount,
          averageScore: quiz.averageScore,
          isPublished: isPublished,
          availableFrom: quiz.availableFrom,
          availableUntil: quiz.availableUntil,
          createdAt: quiz.createdAt,
        );
      }).toList();
      emit(state.copyWith(quizzes: updatedQuizzes));
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleQuizPublished error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Delete quiz
  Future<bool> deleteQuiz(String quizId) async {
    AppLogger.i('📝 [$_tag] deleteQuiz: quizId=$quizId');

    try {
      await _supabase.from('quizzes').delete().eq('id', quizId);

      final updatedQuizzes =
          state.quizzes.where((q) => q.id != quizId).toList();
      emit(state.copyWith(quizzes: updatedQuizzes));

      AppLogger.success('[$_tag] Quiz deleted');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteQuiz error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Get quiz questions
  Future<List<QuizQuestionModel>> getQuizQuestions(String quizId) async {
    AppLogger.i('📝 [$_tag] getQuizQuestions: quizId=$quizId');

    try {
      final response = await _supabase
          .from('quiz_questions')
          .select()
          .eq('quiz_id', quizId)
          .order('sort_order');

      final questions =
          (response as List).map((q) => QuizQuestionModel.fromJson(q)).toList();

      AppLogger.success('[$_tag] Loaded ${questions.length} questions');
      return questions;
    } catch (e, s) {
      AppLogger.e('[$_tag] getQuizQuestions error', e, s);
      return [];
    }
  }

  Future<void> _refreshQuizQuestionTotals(String quizId) async {
    try {
      final response = await _supabase
          .from('quiz_questions')
          .select('points')
          .eq('quiz_id', quizId);
      final questions = response as List;
      final totalPoints = questions.fold<int>(0, (sum, question) {
        final points = question['points'];
        if (points is int) return sum + points;
        if (points is num) return sum + points.toInt();
        return sum;
      });

      await _supabase.from('quizzes').update({
        'total_questions': questions.length,
        'total_points': totalPoints,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', quizId);
    } catch (e, s) {
      AppLogger.e('[$_tag] refresh quiz question totals error', e, s);
    }
  }

  /// Add question
  Future<bool> addQuestion({
    required String quizId,
    required String questionAr,
    required String questionEn,
    String? imageUrl,
    required String type,
    int points = 1,
    required List<Map<String, dynamic>> options,
    String? correctAnswer,
  }) async {
    AppLogger.i('📝 [$_tag] addQuestion: quizId=$quizId, type=$type');
    AppLogger.d('📝 [$_tag] addQuestion: questionAr=$questionAr');
    AppLogger.d('📝 [$_tag] addQuestion: questionEn=$questionEn');
    AppLogger.d('📝 [$_tag] addQuestion: imageUrl=$imageUrl');
    AppLogger.d('📝 [$_tag] addQuestion: options count=${options.length}');

    try {
      // Get current max order
      AppLogger.d('📝 [$_tag] Getting max sort_order...');
      final existingQuestions = await _supabase
          .from('quiz_questions')
          .select('sort_order')
          .eq('quiz_id', quizId)
          .order('sort_order', ascending: false)
          .limit(1);

      final maxOrder = existingQuestions.isNotEmpty
          ? (existingQuestions[0]['sort_order'] as int) + 1
          : 0;
      AppLogger.d('📝 [$_tag] New sort_order: $maxOrder');

      // Generate UUIDs for options that don't have IDs
      const uuid = Uuid();
      final optionsWithIds = options.map((opt) {
        if (opt['id'] == null || (opt['id'] as String).isEmpty) {
          return {...opt, 'id': uuid.v4()};
        }
        return opt;
      }).toList();

      // Insert question with options as JSONB
      final insertData = {
        'quiz_id': quizId,
        'question_ar': questionAr,
        'question_en': questionEn,
        'image_url': imageUrl,
        'question_type': type,
        'points': points,
        'sort_order': maxOrder,
        'options': optionsWithIds,
        'correct_answer': correctAnswer,
      };
      AppLogger.d('📝 [$_tag] Inserting: $insertData');

      final response = await _supabase
          .from('quiz_questions')
          .insert(insertData)
          .select()
          .single();
      AppLogger.d('📝 [$_tag] Insert response: $response');

      await _refreshQuizQuestionTotals(quizId);

      AppLogger.success('[$_tag] Question added successfully');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] addQuestion error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  Future<bool> addQuestionsBulk({
    required String quizId,
    required List<Map<String, dynamic>> questions,
    bool replaceExisting = false,
  }) async {
    AppLogger.i(
        'ðŸ“ [$_tag] addQuestionsBulk: quizId=$quizId, count=${questions.length}, replaceExisting=$replaceExisting');
    if (questions.isEmpty) return true;

    List<Map<String, dynamic>> previousQuestions = const [];

    try {
      if (replaceExisting) {
        final existingRows = await _supabase
            .from('quiz_questions')
            .select()
            .eq('quiz_id', quizId)
            .order('sort_order');
        previousQuestions = List<Map<String, dynamic>>.from(existingRows);
        await _supabase.from('quiz_questions').delete().eq('quiz_id', quizId);
      }

      final existingQuestions = replaceExisting
          ? <dynamic>[]
          : await _supabase
              .from('quiz_questions')
              .select('sort_order')
              .eq('quiz_id', quizId)
              .order('sort_order', ascending: false)
              .limit(1);

      final startOrder = existingQuestions.isNotEmpty
          ? (existingQuestions[0]['sort_order'] as int) + 1
          : 0;

      const uuid = Uuid();
      final rows = questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        final rawOptions = (question['options'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final optionsWithIds = rawOptions.map((opt) {
          final id = opt['id'];
          if (id == null || id.toString().isEmpty) {
            return {...opt, 'id': uuid.v4()};
          }
          return opt;
        }).toList();

        return {
          'quiz_id': quizId,
          'question_ar': question['question_ar'] as String? ?? '',
          'question_en': question['question_en'] as String? ?? '',
          'image_url': question['image_url'],
          'question_type': question['question_type'] as String? ?? 'single',
          'points': question['points'] as int? ?? 1,
          'sort_order': startOrder + index,
          'options': optionsWithIds,
          'correct_answer': question['correct_answer'],
        };
      }).toList();

      try {
        await _supabase.from('quiz_questions').insert(rows);
        await _refreshQuizQuestionTotals(quizId);
      } catch (_) {
        if (replaceExisting && previousQuestions.isNotEmpty) {
          await _supabase.from('quiz_questions').insert(previousQuestions);
          await _refreshQuizQuestionTotals(quizId);
        }
        rethrow;
      }

      AppLogger.success('[$_tag] Bulk questions added successfully');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] addQuestionsBulk error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Update question
  Future<bool> updateQuestion({
    required String quizId,
    required String questionId,
    String? questionAr,
    String? questionEn,
    String? imageUrl,
    bool removeImage = false,
    String? type,
    int? points,
    List<Map<String, dynamic>>? options,
    String? correctAnswer,
  }) async {
    AppLogger.i('📝 [$_tag] updateQuestion: questionId=$questionId');

    try {
      final updates = <String, dynamic>{};
      if (questionAr != null) updates['question_ar'] = questionAr;
      if (questionEn != null) updates['question_en'] = questionEn;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (removeImage) updates['image_url'] = null;
      if (type != null) updates['question_type'] = type;
      if (points != null) updates['points'] = points;
      if (options != null) {
        // Generate UUIDs for options that don't have IDs
        const uuid = Uuid();
        final optionsWithIds = options.map((opt) {
          if (opt['id'] == null || (opt['id'] as String).isEmpty) {
            return {...opt, 'id': uuid.v4()};
          }
          return opt;
        }).toList();
        updates['options'] = optionsWithIds;
      }
      if (correctAnswer != null) updates['correct_answer'] = correctAnswer;

      if (updates.isNotEmpty) {
        await _supabase
            .from('quiz_questions')
            .update(updates)
            .eq('id', questionId);
        await _refreshQuizQuestionTotals(quizId);
      }

      AppLogger.success('[$_tag] Question updated');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateQuestion error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Delete question
  Future<bool> deleteQuestion(String questionId, String quizId) async {
    AppLogger.i('📝 [$_tag] deleteQuestion: questionId=$questionId');

    try {
      await _supabase.from('quiz_questions').delete().eq('id', questionId);
      await _refreshQuizQuestionTotals(quizId);

      AppLogger.success('[$_tag] Question deleted');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteQuestion error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Reorder questions
  Future<bool> reorderQuestions(String quizId, List<String> questionIds) async {
    AppLogger.i(
        '📝 [$_tag] reorderQuestions: quizId=$quizId, count=${questionIds.length}');

    try {
      // Update sort_order for each question
      for (int i = 0; i < questionIds.length; i++) {
        await _supabase
            .from('quiz_questions')
            .update({'sort_order': i}).eq('id', questionIds[i]);
      }

      AppLogger.success('[$_tag] Questions reordered');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reorderQuestions error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Get quiz attempts with student info and answers
  Future<List<Map<String, dynamic>>> getQuizAttempts(String quizId) async {
    AppLogger.i('📝 [$_tag] getQuizAttempts: quizId=$quizId');

    try {
      // Get attempts with user profile info
      final response = await _supabase
          .from('quiz_attempts')
          .select('''
            id,
            user_id,
            quiz_id,
            score,
            percentage,
            passed,
            answers,
            started_at,
            completed_at,
            time_spent,
            user:profiles!quiz_attempts_user_id_fkey(id, name, email, phone, avatar_url)
          ''')
          .eq('quiz_id', quizId)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);

      AppLogger.d('[$_tag] Raw attempts: ${(response as List).length}');

      // Get quiz questions for answer details
      final questions = await getQuizQuestions(quizId);
      final questionsMap = {for (var q in questions) q.id: q};

      // Process attempts with detailed answers
      final attempts = response.map((attempt) {
        // Handle user - could be Map or List (when using FK reference)
        final userData = attempt['user'];
        Map<String, dynamic>? user;
        if (userData is Map<String, dynamic>) {
          user = userData;
        } else if (userData is Map) {
          user = Map<String, dynamic>.from(userData);
        } else if (userData is List && userData.isNotEmpty) {
          // Sometimes Supabase returns a list with one item
          final firstItem = userData.first;
          if (firstItem is Map<String, dynamic>) {
            user = firstItem;
          } else if (firstItem is Map) {
            user = Map<String, dynamic>.from(firstItem);
          }
        }

        // Calculate time taken - prefer time_spent from DB, fallback to calculation
        final timeSpent = attempt['time_spent'] as int?;
        int timeTaken;
        if (timeSpent != null && timeSpent > 0) {
          timeTaken = timeSpent;
        } else {
          final startedAt = attempt['started_at'] != null
              ? DateTime.tryParse(attempt['started_at'].toString())
              : null;
          final completedAt = attempt['completed_at'] != null
              ? DateTime.tryParse(attempt['completed_at'].toString())
              : null;
          timeTaken = (startedAt != null && completedAt != null)
              ? completedAt.difference(startedAt).inSeconds.abs()
              : 0;
        }

        // Handle answers - can be two formats:
        // New format: { "question_id": { "selected_option_ids": [...], "is_correct": bool, "points_earned": int } }
        // Old format: { "question_id": ["option_id1", "option_id2"], ... }
        final answersData = attempt['answers'];
        final List<Map<String, dynamic>> detailedAnswers = [];

        if (answersData is Map) {
          final answersMap = Map<String, dynamic>.from(answersData);

          for (final entry in answersMap.entries) {
            final questionId = entry.key;
            final answerValue = entry.value;
            final question = questionsMap[questionId];

            // Parse answer based on format
            List<String> selectedOptionIds = [];
            bool? storedIsCorrect;

            if (answerValue is Map) {
              // New format with is_correct
              final answerMap = Map<String, dynamic>.from(answerValue);
              final selectedIds = answerMap['selected_option_ids'];
              if (selectedIds is List) {
                selectedOptionIds =
                    selectedIds.map((e) => e.toString()).toList();
              }
              storedIsCorrect = answerMap['is_correct'] as bool?;
            } else if (answerValue is List) {
              // Old format - just array of option IDs
              selectedOptionIds = answerValue.map((e) => e.toString()).toList();
            }

            if (question == null) {
              detailedAnswers.add({
                'question_id': questionId,
                'question_text_ar': 'سؤال محذوف',
                'question_text_en': 'Deleted question',
                'options': <Map<String, dynamic>>[],
                'selected_option_id': selectedOptionIds.isNotEmpty
                    ? selectedOptionIds.first
                    : null,
                'selected_option_ids': selectedOptionIds,
                'correct_option_id': '',
                'is_correct': storedIsCorrect ?? false,
                'explanation': null,
              });
              continue;
            }

            // Find correct option(s) from QuizOptionModel list
            final options = question.options;
            final correctOptionIds = <String>[];
            for (final opt in options) {
              if (opt.isCorrect) {
                correctOptionIds.add(opt.id);
              }
            }

            // Use stored is_correct if available (new format), otherwise calculate
            bool isCorrect;
            if (storedIsCorrect != null) {
              // New format - use stored value (more reliable)
              isCorrect = storedIsCorrect;
            } else {
              // Old format - calculate from options (may be wrong if options changed)
              final selectedSet = selectedOptionIds.toSet();
              final correctSet = correctOptionIds.toSet();
              isCorrect = selectedSet.isNotEmpty &&
                  selectedSet.length == correctSet.length &&
                  selectedSet.containsAll(correctSet);
            }

            AppLogger.d(
                '[$_tag] Q: $questionId, selected: $selectedOptionIds, storedIsCorrect: $storedIsCorrect, isCorrect: $isCorrect');

            detailedAnswers.add({
              'question_id': questionId,
              'question_text_ar': question.questionAr,
              'question_text_en': question.questionEn,
              'image_url': question.imageUrl,
              'options': options
                  .map((o) => {
                        'id': o.id,
                        'text_ar': o.textAr,
                        'text_en': o.textEn,
                        'is_correct': o.isCorrect,
                      })
                  .toList(),
              'selected_option_id':
                  selectedOptionIds.isNotEmpty ? selectedOptionIds.first : null,
              'selected_option_ids': selectedOptionIds,
              'correct_option_id':
                  correctOptionIds.isNotEmpty ? correctOptionIds.first : '',
              'correct_option_ids': correctOptionIds,
              'is_correct': isCorrect,
              'explanation': null,
            });
          }
        } else if (answersData is List) {
          // Legacy format: [{ "question_id": "...", "selected_option_id": "..." }, ...]
          for (final ans in answersData) {
            if (ans is! Map) continue;
            final ansMap = Map<String, dynamic>.from(ans);
            final questionId = ansMap['question_id'] as String?;
            final question =
                questionId != null ? questionsMap[questionId] : null;

            if (question == null) {
              detailedAnswers.add({
                'question_id': questionId,
                'question_text_ar': 'سؤال محذوف',
                'question_text_en': 'Deleted question',
                'options': <Map<String, dynamic>>[],
                'selected_option_id': ansMap['selected_option_id'],
                'correct_option_id': '',
                'is_correct': ansMap['is_correct'] ?? false,
                'explanation': null,
              });
              continue;
            }

            final options = question.options;
            String? correctOptionId;
            for (final opt in options) {
              if (opt.isCorrect) {
                correctOptionId = opt.id;
                break;
              }
            }

            detailedAnswers.add({
              'question_id': questionId,
              'question_text_ar': question.questionAr,
              'question_text_en': question.questionEn,
              'options': options
                  .map((o) => {
                        'id': o.id,
                        'text_ar': o.textAr,
                        'text_en': o.textEn,
                        'is_correct': o.isCorrect,
                      })
                  .toList(),
              'selected_option_id': ansMap['selected_option_id'],
              'correct_option_id': correctOptionId ?? '',
              'is_correct': ansMap['is_correct'] ?? false,
              'explanation': null,
            });
          }
        }

        return {
          'id': attempt['id'],
          'student_name': user?['name'] ?? 'Unknown',
          'student_email': user?['email'],
          'student_phone': user?['phone'],
          'avatar_url': user?['avatar_url'],
          'score': attempt['percentage'] ?? 0, // Use percentage, not raw score
          'passed': attempt['passed'] ?? false,
          'started_at': attempt['started_at'],
          'completed_at': attempt['completed_at'],
          'time_taken': timeTaken,
          'answers': detailedAnswers,
        };
      }).toList();

      AppLogger.success('[$_tag] Processed ${attempts.length} attempts');
      return attempts;
    } catch (e, s) {
      AppLogger.e('[$_tag] getQuizAttempts error', e, s);
      return [];
    }
  }
}
