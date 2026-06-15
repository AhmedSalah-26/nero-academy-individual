'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import {
  ArrowLeft,
  ArrowRight,
  CheckCircle2,
  ClipboardCheck,
  Clock3,
  FileQuestion,
  LockKeyhole,
  Play,
  RotateCcw,
  Trophy,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import styles from './page.module.css';

interface Enrollment {
  id: string;
  course_id: string;
  courses: { title_ar: string; title_en?: string } | null;
}

interface Quiz {
  id: string;
  course_id: string;
  title_ar: string;
  title_en?: string;
  description_ar?: string;
  description_en?: string;
  passing_score: number;
  time_limit?: number;
  max_attempts?: number;
  total_questions: number;
  quiz_questions?: { count: number }[];
  courses?: { title_ar: string; title_en?: string } | null;
}

interface Attempt {
  id: string;
  quiz_id: string;
  percentage: number;
  passed: boolean;
  completed_at?: string;
}

export default function ExamsPage() {
  const { lang, user, loading: authLoading } = useApp();
  const [enrollments, setEnrollments] = useState<Enrollment[]>([]);
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [attempts, setAttempts] = useState<Attempt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    async function loadExams() {
      if (authLoading) return;
      if (!user) {
        setLoading(false);
        return;
      }

      setLoading(true);
      setError('');
      try {
        const { data: enrollmentData, error: enrollmentError } = await supabase
          .from('enrollments')
          .select('id, course_id, courses(title_ar, title_en)')
          .eq('user_id', user.id)
          .in('status', ['active', 'completed']);

        if (enrollmentError) throw enrollmentError;
        const availableEnrollments = (enrollmentData || []) as unknown as Enrollment[];
        setEnrollments(availableEnrollments);

        const courseIds = availableEnrollments.map((item) => item.course_id);
        if (courseIds.length === 0) {
          setQuizzes([]);
          setAttempts([]);
          return;
        }

        const { data: quizData, error: quizError } = await supabase
          .from('quizzes')
          .select('*, quiz_questions(count), courses(title_ar, title_en)')
          .eq('is_published', true)
          .in('course_id', courseIds)
          .order('created_at', { ascending: false });

        if (quizError) throw quizError;
        const availableQuizzes = (quizData || []) as unknown as Quiz[];
        setQuizzes(availableQuizzes);

        const quizIds = availableQuizzes.map((quiz) => quiz.id);
        if (quizIds.length > 0) {
          const { data: attemptData, error: attemptsError } = await supabase
            .from('quiz_attempts')
            .select('id, quiz_id, percentage, passed, completed_at')
            .eq('user_id', user.id)
            .in('quiz_id', quizIds)
            .not('completed_at', 'is', null)
            .order('completed_at', { ascending: false });
          if (attemptsError) throw attemptsError;
          setAttempts((attemptData || []) as Attempt[]);
        }
      } catch (loadError) {
        console.error('Failed to load exams:', loadError);
        setError(lang === 'ar' ? 'تعذر تحميل الامتحانات. حاول مرة أخرى.' : 'Could not load exams. Please try again.');
      } finally {
        setLoading(false);
      }
    }

    loadExams();
  }, [authLoading, lang, user]);

  const enrollmentByCourse = useMemo(
    () => new Map(enrollments.map((enrollment) => [enrollment.course_id, enrollment])),
    [enrollments],
  );

  const attemptsByQuiz = useMemo(() => {
    const map = new Map<string, Attempt[]>();
    attempts.forEach((attempt) => map.set(attempt.quiz_id, [...(map.get(attempt.quiz_id) || []), attempt]));
    return map;
  }, [attempts]);

  const makeQuizHref = (quiz: Quiz) => {
    const enrollment = enrollmentByCourse.get(quiz.course_id);
    const courseTitle = lang === 'ar'
      ? quiz.courses?.title_ar || enrollment?.courses?.title_ar || ''
      : quiz.courses?.title_en || enrollment?.courses?.title_en || quiz.courses?.title_ar || '';
    const query = new URLSearchParams({
      enrollment: enrollment?.id || '',
      courseId: quiz.course_id,
      title: courseTitle,
    });
    return `/quiz/${quiz.id}?${query.toString()}`;
  };

  return (
    <main className={styles.page}>
      <section className={styles.hero}>
        <div>
          <span>{lang === 'ar' ? 'اختبارات كورساتك' : 'YOUR ASSESSMENTS'}</span>
          <h1>{lang === 'ar' ? 'الامتحانات والكويزات' : 'Exams & Quizzes'}</h1>
          <p>
            {lang === 'ar'
              ? 'ابدأ محاولتك، تابع الوقت، وراجع نتائجك السابقة بنفس نظام تطبيق الموبايل.'
              : 'Start attempts, track time, and review previous results just like the mobile app.'}
          </p>
        </div>
        <div className={styles.heroIcon}><ClipboardCheck size={38} /></div>
      </section>

      {loading || authLoading ? (
        <div className={styles.stateCard}>{lang === 'ar' ? 'جاري تحميل الامتحانات...' : 'Loading exams...'}</div>
      ) : !user ? (
        <div className={styles.stateCard}>
          <LockKeyhole size={34} />
          <h2>{lang === 'ar' ? 'سجّل الدخول لعرض امتحاناتك' : 'Sign in to view your exams'}</h2>
          <p>{lang === 'ar' ? 'الامتحانات متاحة فقط داخل الكورسات المشترك بها.' : 'Exams are available for your enrolled courses.'}</p>
          <Link href="/login?redirect=/exams" className={styles.primaryAction}>
            {lang === 'ar' ? 'تسجيل الدخول' : 'Sign in'}
          </Link>
        </div>
      ) : error ? (
        <div className={styles.stateCard}><FileQuestion size={34} /><h2>{error}</h2></div>
      ) : enrollments.length === 0 ? (
        <div className={styles.stateCard}>
          <BookOpenState />
          <h2>{lang === 'ar' ? 'اشترك في كورس أولاً' : 'Enroll in a course first'}</h2>
          <p>{lang === 'ar' ? 'ستظهر امتحانات الكورس هنا بعد الاشتراك.' : 'Course exams will appear here after enrollment.'}</p>
          <Link href="/" className={styles.primaryAction}>{lang === 'ar' ? 'استكشف الكورسات' : 'Browse courses'}</Link>
        </div>
      ) : quizzes.length === 0 ? (
        <div className={styles.stateCard}>
          <FileQuestion size={34} />
          <h2>{lang === 'ar' ? 'لا توجد امتحانات منشورة في كورساتك' : 'No published exams in your courses'}</h2>
          <p>{lang === 'ar' ? 'ستظهر هنا فور نشرها من المدرس.' : 'They will appear as soon as the instructor publishes them.'}</p>
        </div>
      ) : (
        <section className={styles.grid}>
          {quizzes.map((quiz) => {
            const quizAttempts = attemptsByQuiz.get(quiz.id) || [];
            const bestAttempt = [...quizAttempts].sort((a, b) => Number(b.percentage) - Number(a.percentage))[0];
            const questionCount = quiz.quiz_questions?.[0]?.count ?? quiz.total_questions ?? 0;
            const remaining = quiz.max_attempts ? Math.max(quiz.max_attempts - quizAttempts.length, 0) : null;
            const unavailable = remaining === 0;
            const courseTitle = lang === 'ar'
              ? quiz.courses?.title_ar
              : quiz.courses?.title_en || quiz.courses?.title_ar;

            return (
              <article className={styles.card} key={quiz.id}>
                <div className={styles.cardHeader}>
                  <div className={styles.cardIcon}><FileQuestion size={21} /></div>
                  <span className={bestAttempt?.passed ? styles.passedBadge : styles.scoreBadge}>
                    {bestAttempt
                      ? `${Math.round(Number(bestAttempt.percentage))}%`
                      : `${quiz.passing_score}% ${lang === 'ar' ? 'للنجاح' : 'to pass'}`}
                  </span>
                </div>
                <span className={styles.courseName}>{courseTitle}</span>
                <h2>{lang === 'ar' ? quiz.title_ar : quiz.title_en || quiz.title_ar}</h2>
                <p>{lang === 'ar' ? quiz.description_ar : quiz.description_en || quiz.description_ar}</p>
                <div className={styles.metaGrid}>
                  <span><Clock3 size={15} /><b>{quiz.time_limit || '∞'}</b><small>{lang === 'ar' ? 'دقيقة' : 'minutes'}</small></span>
                  <span><FileQuestion size={15} /><b>{questionCount}</b><small>{lang === 'ar' ? 'سؤال' : 'questions'}</small></span>
                  <span><RotateCcw size={15} /><b>{remaining ?? '∞'}</b><small>{lang === 'ar' ? 'محاولة متبقية' : 'attempts left'}</small></span>
                  <span><Trophy size={15} /><b>{quizAttempts.length}</b><small>{lang === 'ar' ? 'نتيجة سابقة' : 'past results'}</small></span>
                </div>
                <Link href={makeQuizHref(quiz)} className={`${styles.startAction} ${unavailable ? styles.reviewAction : ''}`}>
                  {unavailable ? <CheckCircle2 size={16} /> : <Play size={16} fill="currentColor" />}
                  {unavailable
                    ? (lang === 'ar' ? 'عرض النتائج' : 'View results')
                    : (lang === 'ar' ? 'تفاصيل وبدء الامتحان' : 'Details & start')}
                  {lang === 'ar' ? <ArrowLeft size={15} /> : <ArrowRight size={15} />}
                </Link>
              </article>
            );
          })}
        </section>
      )}
    </main>
  );
}

function BookOpenState() {
  return <ClipboardCheck size={34} />;
}
