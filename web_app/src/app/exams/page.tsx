'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import {
  ArrowBack,
  ArrowForward,
  CheckCircle,
  AssignmentTurnedIn,
  Schedule,
  Quiz,
  Lock,
  PlayArrow,
  Replay,
  EmojiEvents,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface Enrollment {
  id: string;
  course_id: string;
  courses: { title_ar: string; title_en?: string } | null;
}

interface Quiz {
  id: string;
  course_id: string;
  section_id?: string | null;
  lesson_id?: string | null;
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
  const pageRef = usePageTransition();
  const { lang, user, loading: authLoading } = useApp();
  const [enrollments, setEnrollments] = useState<Enrollment[]>([]);
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [attempts, setAttempts] = useState<Attempt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [sections, setSections] = useState<any[]>([]);
  const [lessons, setLessons] = useState<any[]>([]);

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

        if (enrollmentError) throw new Error(`Enrollments load failed: ${enrollmentError.message} (${enrollmentError.code})`);
        const availableEnrollments = (enrollmentData || []) as unknown as Enrollment[];
        setEnrollments(availableEnrollments);

        const courseIds = availableEnrollments.map((item) => item.course_id);
        if (courseIds.length === 0) {
          setQuizzes([]);
          setAttempts([]);
          setSections([]);
          setLessons([]);
          return;
        }

        const { data: quizData, error: quizError } = await supabase
          .from('quizzes')
          .select('*, quiz_questions(count), courses(title_ar, title_en)')
          .eq('is_published', true)
          .in('course_id', courseIds)
          .order('created_at', { ascending: false });

        if (quizError) throw new Error(`Quizzes load failed: ${quizError.message} (${quizError.code})`);
        const availableQuizzes = (quizData || []) as unknown as Quiz[];
        setQuizzes(availableQuizzes);

        // Fetch sections for these courses
        const { data: sectionsData, error: sectionsError } = await supabase
          .from('sections')
          .select('id, course_id, title_ar, title_en, sort_order')
          .order('sort_order', { ascending: true });
        if (sectionsError) throw new Error(`Sections load failed: ${sectionsError.message} (${sectionsError.code})`);
        const fetchedSections = sectionsData || [];
        setSections(fetchedSections);

        // Fetch lessons for these sections
        const { data: lessonsData, error: lessonsError } = await supabase
          .from('lessons')
          .select('id, section_id, course_id, title_ar, title_en, sort_order')
          .order('sort_order', { ascending: true });
        if (lessonsError) throw new Error(`Lessons load failed: ${lessonsError.message} (${lessonsError.code})`);
        setLessons(lessonsData || []);

        const quizIds = availableQuizzes.map((quiz) => quiz.id);
        if (quizIds.length > 0) {
          const { data: attemptData, error: attemptsError } = await supabase
            .from('quiz_attempts')
            .select('id, quiz_id, percentage, passed, completed_at')
            .eq('user_id', user.id)
            .in('quiz_id', quizIds)
            .not('completed_at', 'is', null)
            .order('completed_at', { ascending: false });
          if (attemptsError) throw new Error(`Attempts load failed: ${attemptsError.message} (${attemptsError.code})`);
          setAttempts((attemptData || []) as Attempt[]);
        }

        console.log('Exams debug on client:', {
          courseIds,
          quizzes: availableQuizzes.map(q => ({ id: q.id, title: q.title_ar, section_id: q.section_id, lesson_id: q.lesson_id })),
          sections: fetchedSections.map(s => ({ id: s.id, course_id: s.course_id, title: s.title_ar })),
        });
      } catch (loadError: any) {
        console.error('Failed to load exams error details:', loadError);
        setError(loadError.message || (lang === 'ar' ? 'تعذر تحميل الامتحانات. حاول مرة أخرى.' : 'Could not load exams. Please try again.'));
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

  const renderQuizCard = (quiz: Quiz) => {
    const quizAttempts = attemptsByQuiz.get(quiz.id) || [];
    const bestAttempt = [...quizAttempts].sort((a, b) => Number(b.percentage) - Number(a.percentage))[0];
    const questionCount = quiz.quiz_questions?.[0]?.count ?? quiz.total_questions ?? 0;
    const remaining = quiz.max_attempts ? Math.max(quiz.max_attempts - quizAttempts.length, 0) : null;
    const unavailable = remaining === 0;

    return (
      <article className={styles.card} key={quiz.id}>
        <div className={styles.cardHeader}>
          <div className={styles.cardIcon}><Quiz fontSize="small" /></div>
          <span className={bestAttempt?.passed ? styles.passedBadge : styles.scoreBadge}>
            {bestAttempt
              ? `${Math.round(Number(bestAttempt.percentage))}%`
              : `${quiz.passing_score}% ${lang === 'ar' ? 'للنجاح' : 'to pass'}`}
          </span>
        </div>
        <h2>{lang === 'ar' ? quiz.title_ar : quiz.title_en || quiz.title_ar}</h2>
        <p>{lang === 'ar' ? quiz.description_ar : quiz.description_en || quiz.description_ar}</p>
        <div className={styles.metaGrid}>
          <span><Schedule fontSize="small" /><b>{quiz.time_limit || '∞'}</b><small>{lang === 'ar' ? 'دقيقة' : 'minutes'}</small></span>
          <span><Quiz fontSize="small" /><b>{questionCount}</b><small>{lang === 'ar' ? 'سؤال' : 'questions'}</small></span>
          <span><Replay fontSize="small" /><b>{remaining ?? '∞'}</b><small>{lang === 'ar' ? 'متبقي' : 'left'}</small></span>
          <span><EmojiEvents fontSize="small" /><b>{quizAttempts.length}</b><small>{lang === 'ar' ? 'نتائج' : 'results'}</small></span>
        </div>
        <Link href={makeQuizHref(quiz)} className={`${styles.startAction} ${unavailable ? styles.reviewAction : ''}`}>
          {unavailable ? <CheckCircle fontSize="small" /> : <PlayArrow fontSize="small" />}
          {unavailable
            ? (lang === 'ar' ? 'عرض النتائج' : 'View results')
            : (lang === 'ar' ? 'تفاصيل وبدء الامتحان' : 'Details & start')}
          {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
        </Link>
      </article>
    );
  };

  return (
    <main ref={pageRef} className={styles.page}>
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
      </section>

      {loading || authLoading ? (
        <div className={styles.stateCard}>{lang === 'ar' ? 'جاري تحميل الامتحانات...' : 'Loading exams...'}</div>
      ) : !user ? (
        <div className={styles.stateCard}>
          <Lock fontSize="large" />
          <h2>{lang === 'ar' ? 'سجّل الدخول لعرض امتحاناتك' : 'Sign in to view your exams'}</h2>
          <p>{lang === 'ar' ? 'الامتحانات متاحة فقط داخل الكورسات المشترك بها.' : 'Exams are available for your enrolled courses.'}</p>
          <Link href="/login?redirect=/exams" className={styles.primaryAction}>
            {lang === 'ar' ? 'تسجيل الدخول' : 'Sign in'}
          </Link>
        </div>
      ) : error ? (
        <div className={styles.stateCard}><Quiz fontSize="large" /><h2>{error}</h2></div>
      ) : enrollments.length === 0 ? (
        <div className={styles.stateCard}>
          <BookOpenState />
          <h2>{lang === 'ar' ? 'اشترك في كورس أولاً' : 'Enroll in a course first'}</h2>
          <p>{lang === 'ar' ? 'ستظهر امتحانات الكورس هنا بعد الاشتراك.' : 'Course exams will appear here after enrollment.'}</p>
          <Link href="/" className={styles.primaryAction}>{lang === 'ar' ? 'استكشف الكورسات' : 'Browse courses'}</Link>
        </div>
      ) : quizzes.length === 0 ? (
        <div className={styles.stateCard}>
          <Quiz fontSize="large" />
          <h2>{lang === 'ar' ? 'لا توجد امتحانات منشورة في كورساتك' : 'No published exams in your courses'}</h2>
          <p>{lang === 'ar' ? 'ستظهر هنا فور نشرها من المدرس.' : 'They will appear as soon as the instructor publishes them.'}</p>
        </div>
      ) : (
        <div className={styles.groupedContainer}>
          {enrollments.map((enrollment) => {
            const courseTitle = lang === 'ar'
              ? enrollment.courses?.title_ar
              : enrollment.courses?.title_en || enrollment.courses?.title_ar;

            const courseQuizzes = quizzes.filter((q) => q.course_id === enrollment.course_id);
            if (courseQuizzes.length === 0) return null;

            const renderedQuizIds = new Set<string>();
            const courseSections = sections.filter((s) => s.course_id === enrollment.course_id);

            // Filter quizzes that belong to this section directly or via its lessons
            const sectionBlocks = courseSections.map((section) => {
              const sectionTitle = lang === 'ar' ? section.title_ar : section.title_en || section.title_ar;
              
              const secQuizzes = courseQuizzes.filter((q) => q.section_id === section.id && !q.lesson_id);
              const sectionLessons = lessons.filter((l) => l.section_id === section.id);
              const lesQuizzes = courseQuizzes.filter((q) => q.lesson_id && sectionLessons.some((l) => l.id === q.lesson_id));
              const allSectionQuizzes = [...secQuizzes, ...lesQuizzes];

              if (allSectionQuizzes.length === 0) return null;

              allSectionQuizzes.forEach((q) => renderedQuizIds.add(q.id));

              return (
                <details key={section.id} className={styles.quizAccordionGroup}>
                  <summary className={styles.quizAccordionHeader}>
                    <span className={styles.quizAccordionChevron} />
                    <div className={styles.quizAccordionTitle}>
                      <strong>{lang === 'ar' ? `امتحانات قسم: ${sectionTitle}` : `Exams for section: ${sectionTitle}`}</strong>
                      <small>{allSectionQuizzes.length} {lang === 'ar' ? 'اختبار' : 'quizzes'}</small>
                    </div>
                  </summary>
                  <div className={styles.quizAccordionContent}>
                    <div className={styles.grid}>
                      {allSectionQuizzes.map((quiz) => renderQuizCard(quiz))}
                    </div>
                  </div>
                </details>
              );
            });

            // 3. Fallback / General / Remaining Quizzes
            const remainingQuizzes = courseQuizzes.filter((q) => !renderedQuizIds.has(q.id));

            return (
              <section key={enrollment.id} className={styles.courseGroupSection}>
                <h2 className={styles.courseGroupTitle}>
                  <AssignmentTurnedIn fontSize="medium" />
                  <span>{courseTitle}</span>
                </h2>

                <div className={styles.accordionContainer}>
                  {sectionBlocks}

                  {remainingQuizzes.length > 0 && (
                    <details className={styles.quizAccordionGroup}>
                      <summary className={styles.quizAccordionHeader}>
                        <span className={styles.quizAccordionChevron} />
                        <div className={styles.quizAccordionTitle}>
                          <strong>{lang === 'ar' ? 'امتحانات عامة للمنهج' : 'General Course Exams'}</strong>
                          <small>{remainingQuizzes.length} {lang === 'ar' ? 'اختبار' : 'quizzes'}</small>
                        </div>
                      </summary>
                      <div className={styles.quizAccordionContent}>
                        <div className={styles.grid}>
                          {remainingQuizzes.map((quiz) => renderQuizCard(quiz))}
                        </div>
                      </div>
                    </details>
                  )}
                </div>
              </section>
            );
          })}
        </div>
      )}
    </main>
  );
}

function BookOpenState() {
  return <AssignmentTurnedIn fontSize="large" />;
}
