'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import {
  ArrowBack,
  ArrowForward,
  Check,
  CheckCircle,
  ChevronLeft,
  ChevronRight,
  AssignmentTurnedIn,
  Schedule,
  Quiz,
  Lock,
  Replay,
  Send,
  EmojiEvents,
  Close,
  Cancel,
} from '@mui/icons-material';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import styles from './page.module.css';

interface Option {
  id: string;
  text_ar?: string;
  text_en?: string;
  is_correct?: boolean;
}

interface Question {
  id: string;
  question_ar: string;
  question_en?: string;
  question_type: 'single' | 'multiple' | 'true_false' | 'text';
  options: Option[];
  points: number;
  image_url?: string;
  explanation_ar?: string;
  explanation_en?: string;
  sort_order: number;
}

interface Quiz {
  id: string;
  course_id: string;
  lesson_id?: string;
  title_ar: string;
  title_en?: string;
  description_ar?: string;
  description_en?: string;
  passing_score: number;
  time_limit?: number;
  max_attempts?: number;
  shuffle_questions: boolean;
  shuffle_answers: boolean;
  show_correct_answers: boolean;
  total_questions: number;
  quiz_questions?: { count: number }[];
}

interface Attempt {
  id: string;
  quiz_id: string;
  enrollment_id: string;
  score: number;
  total_points: number;
  percentage: number;
  passed: boolean;
  answers: Record<string, string[]>;
  time_spent?: number;
  started_at?: string;
  completed_at?: string;
}

type Phase = 'info' | 'taking' | 'result';

function shuffle<T>(items: T[]) {
  return [...items].sort(() => Math.random() - 0.5);
}

function formatTime(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
}

export default function QuizPage() {
  const { id } = useParams<{ id: string }>();
  const { lang, user, loading: authLoading } = useApp();
  const [quiz, setQuiz] = useState<Quiz | null>(null);
  const [enrollmentId, setEnrollmentId] = useState('');
  const [courseTitle, setCourseTitle] = useState('');
  const [attempts, setAttempts] = useState<Attempt[]>([]);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [answers, setAnswers] = useState<Record<string, string[]>>({});
  const [currentIndex, setCurrentIndex] = useState(0);
  const [currentAttempt, setCurrentAttempt] = useState<Attempt | null>(null);
  const [completedAttempt, setCompletedAttempt] = useState<Attempt | null>(null);
  const [remainingSeconds, setRemainingSeconds] = useState<number | null>(null);
  const [phase, setPhase] = useState<Phase>('info');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const startedAtRef = useRef<number | null>(null);

  const loadQuizInfo = useCallback(async () => {
    if (authLoading) return;
    if (!user) {
      setLoading(false);
      return;
    }

    setLoading(true);
    setError('');
    try {
      const params = new URLSearchParams(window.location.search);
      const requestedEnrollment = params.get('enrollment') || '';
      setCourseTitle(params.get('title') || '');

      const { data: quizData, error: quizError } = await supabase
        .from('quizzes')
        .select('*, quiz_questions(count)')
        .eq('id', id)
        .eq('is_published', true)
        .single();
      if (quizError) throw quizError;

      const loadedQuiz = quizData as unknown as Quiz;
      setQuiz(loadedQuiz);

      let activeEnrollmentId = requestedEnrollment;
      if (!activeEnrollmentId) {
        const { data: enrollmentData } = await supabase
          .from('enrollments')
          .select('id')
          .eq('user_id', user.id)
          .eq('course_id', loadedQuiz.course_id)
          .in('status', ['active', 'completed'])
          .maybeSingle();
        activeEnrollmentId = enrollmentData?.id || '';
      }

      if (!activeEnrollmentId) {
        setError(lang === 'ar' ? 'هذا الامتحان متاح للمشتركين في الكورس فقط.' : 'This exam is only available to enrolled students.');
        return;
      }
      setEnrollmentId(activeEnrollmentId);

      const { data: attemptData, error: attemptsError } = await supabase
        .from('quiz_attempts')
        .select('*')
        .eq('quiz_id', id)
        .eq('enrollment_id', activeEnrollmentId)
        .not('completed_at', 'is', null)
        .order('started_at', { ascending: false });
      if (attemptsError) throw attemptsError;
      setAttempts((attemptData || []) as Attempt[]);
    } catch (loadError) {
      console.error('Failed to load quiz:', loadError);
      setError(lang === 'ar' ? 'تعذر تحميل بيانات الامتحان.' : 'Could not load quiz details.');
    } finally {
      setLoading(false);
    }
  }, [authLoading, id, lang, user]);

  useEffect(() => {
    const timer = window.setTimeout(() => void loadQuizInfo(), 0);
    return () => window.clearTimeout(timer);
  }, [loadQuizInfo]);

  const questionCount = quiz?.quiz_questions?.[0]?.count ?? quiz?.total_questions ?? 0;
  const remainingAttempts = quiz?.max_attempts ? Math.max(quiz.max_attempts - attempts.length, 0) : null;
  const canStart = !!quiz && !!enrollmentId && (remainingAttempts === null || remainingAttempts > 0);
  const currentQuestion = questions[currentIndex];
  const answeredCount = Object.values(answers).filter((answer) => answer.length > 0 && answer.some(Boolean)).length;
  const progress = questions.length ? ((currentIndex + 1) / questions.length) * 100 : 0;

  const submitQuiz = useCallback(async () => {
    if (!currentAttempt || submitting) return;

    setSubmitting(true);
    setError('');
    try {
      const timeSpent = startedAtRef.current ? Math.max(0, Math.round((Date.now() - startedAtRef.current) / 1000)) : 0;
      const { data: submitData, error: submitError } = await supabase.rpc('submit_quiz_attempt', {
        p_attempt_id: currentAttempt.id,
        p_answers: answers,
        p_time_spent: timeSpent,
      });
      if (submitError) throw submitError;
      if (!submitData?.success) throw new Error(submitData?.error || 'Submit failed');

      const { data: attemptData, error: attemptError } = await supabase
        .from('quiz_attempts')
        .select('*')
        .eq('id', currentAttempt.id)
        .single();
      if (attemptError) throw attemptError;

      const finished = attemptData as Attempt;
      setCompletedAttempt(finished);
      setAttempts((previous) => [finished, ...previous]);
      setCurrentAttempt(null);
      setRemainingSeconds(null);
      setPhase('result');
    } catch (submitFailure) {
      console.error('Failed to submit quiz:', submitFailure);
      setError(lang === 'ar' ? 'تعذر إرسال الامتحان. إجاباتك ما زالت محفوظة، حاول مرة أخرى.' : 'Could not submit the exam. Your answers are still saved.');
    } finally {
      setSubmitting(false);
    }
  }, [answers, currentAttempt, lang, submitting]);

  useEffect(() => {
    if (phase !== 'taking' || remainingSeconds === null) return;
    if (remainingSeconds <= 0) {
      const autoSubmitTimer = window.setTimeout(() => void submitQuiz(), 0);
      return () => window.clearTimeout(autoSubmitTimer);
    }
    const timer = window.setTimeout(() => setRemainingSeconds((value) => value === null ? null : value - 1), 1000);
    return () => window.clearTimeout(timer);
  }, [phase, remainingSeconds, submitQuiz]);

  async function startQuiz() {
    if (!canStart || !quiz || !user) return;

    setLoading(true);
    setError('');
    try {
      const { data: attemptData, error: attemptError } = await supabase
        .from('quiz_attempts')
        .insert({
          quiz_id: quiz.id,
          enrollment_id: enrollmentId,
          user_id: user.id,
          started_at: new Date().toISOString(),
        })
        .select()
        .single();
      if (attemptError) throw attemptError;

      const { data: questionData, error: questionsError } = await supabase
        .from('quiz_questions')
        .select('id, question_ar, question_en, question_type, options, points, image_url, explanation_ar, explanation_en, sort_order')
        .eq('quiz_id', quiz.id)
        .order('sort_order');
      if (questionsError) throw questionsError;

      let loadedQuestions = (questionData || []) as Question[];
      loadedQuestions = loadedQuestions.map((question) => ({
        ...question,
        options: quiz.shuffle_answers ? shuffle(question.options || []) : question.options || [],
      }));
      if (quiz.shuffle_questions) loadedQuestions = shuffle(loadedQuestions);
      if (loadedQuestions.length === 0) throw new Error('No questions');

      setQuestions(loadedQuestions);
      setCurrentAttempt(attemptData as Attempt);
      setAnswers({});
      setCurrentIndex(0);
      setCompletedAttempt(null);
      setRemainingSeconds(quiz.time_limit ? quiz.time_limit * 60 : null);
      startedAtRef.current = Date.now();
      setPhase('taking');
    } catch (startError) {
      console.error('Failed to start quiz:', startError);
      setError(lang === 'ar' ? 'تعذر بدء الامتحان. تأكد من اشتراكك ثم حاول مرة أخرى.' : 'Could not start the exam. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  function selectOption(question: Question, optionId: string) {
    setAnswers((previous) => {
      const selected = previous[question.id] || [];
      if (question.question_type === 'multiple') {
        return {
          ...previous,
          [question.id]: selected.includes(optionId)
            ? selected.filter((idValue) => idValue !== optionId)
            : [...selected, optionId],
        };
      }
      return { ...previous, [question.id]: [optionId] };
    });
  }

  function setTextAnswer(questionId: string, value: string) {
    setAnswers((previous) => ({ ...previous, [questionId]: value ? [value] : [] }));
  }

  function confirmSubmit() {
    const unanswered = questions.length - answeredCount;
    const message = unanswered > 0
      ? (lang === 'ar' ? `لم تجب عن ${unanswered} سؤال. هل تريد إرسال الامتحان؟` : `${unanswered} questions are unanswered. Submit anyway?`)
      : (lang === 'ar' ? 'هل تريد إرسال الامتحان الآن؟' : 'Submit the exam now?');
    if (window.confirm(message)) void submitQuiz();
  }

  function returnToInfo() {
    setPhase('info');
    setCurrentAttempt(null);
    setRemainingSeconds(null);
    setQuestions([]);
    setAnswers({});
    setError('');
  }

  const bestAttempt = useMemo(
    () => [...attempts].sort((a, b) => Number(b.percentage) - Number(a.percentage))[0],
    [attempts],
  );

  if (loading || authLoading) {
    return <div className={styles.loading}>{lang === 'ar' ? 'جاري تحميل الامتحان...' : 'Loading exam...'}</div>;
  }

  if (!user) {
    return (
      <main className={styles.page}>
        <div className={styles.stateCard}>
          <Lock fontSize="large" />
          <h1>{lang === 'ar' ? 'سجّل الدخول لبدء الامتحان' : 'Sign in to start the exam'}</h1>
          <Link href={`/login?redirect=/quiz/${id}`} className={styles.primaryButton}>{lang === 'ar' ? 'تسجيل الدخول' : 'Sign in'}</Link>
        </div>
      </main>
    );
  }

  if (!quiz || (error && !enrollmentId)) {
    return (
      <main className={styles.page}>
        <div className={styles.stateCard}>
          <Quiz fontSize="large" />
          <h1>{error || (lang === 'ar' ? 'الامتحان غير متاح' : 'Exam unavailable')}</h1>
          <Link href="/my-learning" className={styles.primaryButton}>{lang === 'ar' ? 'العودة لتعليمي' : 'Back to My Learning'}</Link>
        </div>
      </main>
    );
  }

  if (phase === 'taking' && currentQuestion) {
    return (
      <main className={styles.examPage}>
        <header className={styles.examHeader}>
          <button type="button" onClick={returnToInfo} className={styles.iconButton} aria-label="Close"><Close fontSize="small" /></button>
          <div>
            <span>{courseTitle}</span>
            <h1>{lang === 'ar' ? quiz.title_ar : quiz.title_en || quiz.title_ar}</h1>
          </div>
          {remainingSeconds !== null ? (
            <strong className={`${styles.timer} ${remainingSeconds < 60 ? styles.timerDanger : ''}`}><Schedule fontSize="small" />{formatTime(remainingSeconds)}</strong>
           ) : <span className={styles.timer}><Schedule fontSize="small" />∞</span>}
        </header>

        <div className={styles.progressTrack}><div style={{ width: `${progress}%` }} /></div>
        <div className={styles.questionStatus}>
          <span>{lang === 'ar' ? `السؤال ${currentIndex + 1} من ${questions.length}` : `Question ${currentIndex + 1} of ${questions.length}`}</span>
          <span>{lang === 'ar' ? `${answeredCount} تمت إجابته` : `${answeredCount} answered`}</span>
        </div>

        {error && <div className={styles.errorBanner}>{error}</div>}

        <section className={styles.questionLayout}>
          <aside className={styles.questionNavigator}>
            {questions.map((question, index) => (
              <button
                type="button"
                key={question.id}
                onClick={() => setCurrentIndex(index)}
                className={`${index === currentIndex ? styles.currentDot : ''} ${(answers[question.id] || []).length ? styles.answeredDot : ''}`}
              >
                {index + 1}
              </button>
            ))}
          </aside>

          <article className={styles.questionCard}>
            <div className={styles.questionTitleRow}>
              <span>{currentIndex + 1}</span>
              <h2>{lang === 'ar' ? currentQuestion.question_ar : currentQuestion.question_en || currentQuestion.question_ar}</h2>
              <b>{currentQuestion.points || 1} {lang === 'ar' ? 'نقطة' : 'pt'}</b>
            </div>
            {currentQuestion.image_url && (
              <img src={currentQuestion.image_url} alt="" className={styles.questionImage} />
            )}
            {currentQuestion.question_type === 'multiple' && (
              <p className={styles.helperText}>{lang === 'ar' ? 'يمكنك اختيار أكثر من إجابة.' : 'You can select more than one answer.'}</p>
            )}
            {currentQuestion.options?.length ? (
              <div className={styles.options}>
                {currentQuestion.options.map((option, index) => {
                  const selected = (answers[currentQuestion.id] || []).includes(option.id);
                  return (
                    <button
                      type="button"
                      key={option.id}
                      onClick={() => selectOption(currentQuestion, option.id)}
                      className={`${styles.option} ${selected ? styles.selectedOption : ''}`}
                    >
                      <span>{selected ? <Check fontSize="small" /> : String.fromCharCode(65 + index)}</span>
                      <strong>{lang === 'ar' ? option.text_ar : option.text_en || option.text_ar}</strong>
                    </button>
                  );
                })}
              </div>
            ) : (
              <textarea
                value={answers[currentQuestion.id]?.[0] || ''}
                onChange={(event) => setTextAnswer(currentQuestion.id, event.target.value)}
                className={styles.textAnswer}
                placeholder={lang === 'ar' ? 'اكتب إجابتك هنا...' : 'Write your answer here...'}
              />
            )}
          </article>
        </section>

        <footer className={styles.examFooter}>
          <button type="button" onClick={() => setCurrentIndex((value) => Math.max(0, value - 1))} disabled={currentIndex === 0} className={styles.secondaryButton}>
            {lang === 'ar' ? <ChevronRight fontSize="small" /> : <ChevronLeft fontSize="small" />}
            {lang === 'ar' ? 'السابق' : 'Previous'}
          </button>
          {currentIndex < questions.length - 1 ? (
            <button type="button" onClick={() => setCurrentIndex((value) => Math.min(questions.length - 1, value + 1))} className={styles.primaryButton}>
              {lang === 'ar' ? 'التالي' : 'Next'}
              {lang === 'ar' ? <ChevronLeft fontSize="small" /> : <ChevronRight fontSize="small" />}
            </button>
          ) : (
            <button type="button" onClick={confirmSubmit} disabled={submitting} className={styles.submitButton}>
              <Send fontSize="small" />
              {submitting ? (lang === 'ar' ? 'جاري الإرسال...' : 'Submitting...') : (lang === 'ar' ? 'إرسال الامتحان' : 'Submit exam')}
            </button>
          )}
        </footer>
      </main>
    );
  }

  if (phase === 'result' && completedAttempt) {
    const passed = completedAttempt.passed;
    return (
      <main className={styles.page}>
        <section className={styles.resultCard}>
          <div className={`${styles.resultIcon} ${passed ? styles.resultPassed : styles.resultFailed}`}>
            {passed ? <EmojiEvents fontSize="large" /> : <Replay fontSize="large" />}
          </div>
          <span>{lang === 'ar' ? 'نتيجة الامتحان' : 'EXAM RESULT'}</span>
          <h1>{Math.round(Number(completedAttempt.percentage))}%</h1>
          <h2>{passed ? (lang === 'ar' ? 'أحسنت، اجتزت الامتحان' : 'Great work, you passed') : (lang === 'ar' ? 'راجع الدروس وحاول مرة أخرى' : 'Review and try again')}</h2>
          <div className={styles.resultStats}>
            <div><CheckCircle fontSize="small" /><strong>{completedAttempt.score}/{completedAttempt.total_points}</strong><small>{lang === 'ar' ? 'الدرجة' : 'Score'}</small></div>
            <div><Schedule fontSize="small" /><strong>{formatTime(completedAttempt.time_spent || 0)}</strong><small>{lang === 'ar' ? 'الوقت' : 'Time'}</small></div>
            <div><EmojiEvents fontSize="small" /><strong>{quiz.passing_score}%</strong><small>{lang === 'ar' ? 'درجة النجاح' : 'Pass score'}</small></div>
          </div>
          {error && <div className={styles.errorBanner}>{error}</div>}
          <div className={styles.resultActions}>
            {!passed && canStart && <button type="button" onClick={returnToInfo} className={styles.secondaryButton}><Replay fontSize="small" />{lang === 'ar' ? 'إعادة المحاولة' : 'Try again'}</button>}
            <Link href="/exams" className={styles.primaryButton}>{lang === 'ar' ? 'العودة للامتحانات' : 'Back to exams'}</Link>
          </div>
        </section>

        {quiz.show_correct_answers && questions.length > 0 && (
          <section className={styles.reviewSection}>
            <h2>{lang === 'ar' ? 'مراجعة الإجابات' : 'Answer review'}</h2>
            {questions.map((question, index) => {
              const selected = answers[question.id] || [];
              const correct = (question.options || []).filter((option) => option.is_correct).map((option) => option.id);
              const isCorrect = selected.length === correct.length && selected.every((value) => correct.includes(value));
              return (
                <article className={styles.reviewCard} key={question.id}>
                  <div className={isCorrect ? styles.reviewCorrect : styles.reviewWrong}>{isCorrect ? <CheckCircle fontSize="small" /> : <Cancel fontSize="small" />}</div>
                  <div>
                    <h3>{index + 1}. {lang === 'ar' ? question.question_ar : question.question_en || question.question_ar}</h3>
                    <p>{lang === 'ar' ? question.explanation_ar : question.explanation_en || question.explanation_ar}</p>
                  </div>
                </article>
              );
            })}
          </section>
        )}
      </main>
    );
  }

  return (
    <main className={styles.page}>
      <section className={styles.infoHero}>
        <div>
          <span>{courseTitle || (lang === 'ar' ? 'اختبار الكورس' : 'Course exam')}</span>
          <h1>{lang === 'ar' ? quiz.title_ar : quiz.title_en || quiz.title_ar}</h1>
          <p>{lang === 'ar' ? quiz.description_ar : quiz.description_en || quiz.description_ar}</p>
        </div>
      </section>

      {error && <div className={styles.errorBanner}>{error}</div>}

      <section className={styles.infoGrid}>
        <div><Schedule fontSize="small" /><span>{lang === 'ar' ? 'الوقت' : 'Time'}</span><strong>{quiz.time_limit ? `${quiz.time_limit} ${lang === 'ar' ? 'دقيقة' : 'min'}` : (lang === 'ar' ? 'بدون حد' : 'Unlimited')}</strong></div>
        <div><Quiz fontSize="small" /><span>{lang === 'ar' ? 'الأسئلة' : 'Questions'}</span><strong>{questionCount}</strong></div>
        <div><Replay fontSize="small" /><span>{lang === 'ar' ? 'المحاولات المتبقية' : 'Attempts left'}</span><strong>{remainingAttempts ?? (lang === 'ar' ? 'غير محدودة' : 'Unlimited')}</strong></div>
        <div><EmojiEvents fontSize="small" /><span>{lang === 'ar' ? 'درجة النجاح' : 'Pass score'}</span><strong>{quiz.passing_score}%</strong></div>
      </section>

      {attempts.length > 0 && (
        <section className={styles.attemptsSection}>
          <div className={styles.attemptsHeader}>
            <h2>{lang === 'ar' ? 'المحاولات السابقة' : 'Previous attempts'}</h2>
            {bestAttempt && <span>{lang === 'ar' ? 'أفضل نتيجة' : 'Best'}: {Math.round(Number(bestAttempt.percentage))}%</span>}
          </div>
          <div className={styles.attemptsList}>
            {attempts.map((attempt, index) => (
              <div className={styles.attemptRow} key={attempt.id}>
                <span className={attempt.passed ? styles.attemptPassed : styles.attemptFailed}>{attempt.passed ? <CheckCircle fontSize="small" /> : <Cancel fontSize="small" />}</span>
                <strong>{lang === 'ar' ? `المحاولة ${attempts.length - index}` : `Attempt ${attempts.length - index}`}</strong>
                <small>{attempt.completed_at ? new Date(attempt.completed_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US') : ''}</small>
                <b>{Math.round(Number(attempt.percentage))}%</b>
              </div>
            ))}
          </div>
        </section>
      )}

      <div className={styles.infoActions}>
        <Link href="/exams" className={styles.secondaryButton}>
          {lang === 'ar' ? <ArrowForward fontSize="small" /> : <ArrowBack fontSize="small" />}
          {lang === 'ar' ? 'العودة للامتحانات' : 'Back to exams'}
        </Link>
        <button type="button" onClick={startQuiz} disabled={!canStart || loading} className={styles.primaryButton}>
          {canStart ? <AssignmentTurnedIn fontSize="small" /> : <Lock fontSize="small" />}
          {canStart ? (lang === 'ar' ? 'ابدأ الامتحان' : 'Start exam') : (lang === 'ar' ? 'لا توجد محاولات متبقية' : 'No attempts left')}
          {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
        </button>
      </div>
    </main>
  );
}
