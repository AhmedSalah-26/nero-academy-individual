'use client';

import { useCallback, useEffect, useState } from 'react';
import { Help as HelpIcon, CheckCircle, Chat, Send, Close, School } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { AppBackButton, EmptyState, ShimmerEffect, AppButton, AppCard } from '../../components/ui';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

type Question = {
  id: string;
  title: string;
  content: string;
  is_answered: boolean;
  answers_count: number;
  created_at: string;
  course_id: string;
  courses?: { title_ar: string; title_en?: string };
  profiles?: { name?: string };
};

type Answer = {
  id: string;
  content: string;
  is_instructor_answer: boolean;
  created_at: string;
  profiles?: { name?: string };
};

const TITLE_MIN = 10;
const CONTENT_MIN = 20;

export default function QAPage() {
  const pageRef = usePageTransition();
  const { lang, user, profile } = useApp();
  const [items, setItems] = useState<Question[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<Question | null>(null);
  const [answers, setAnswers] = useState<Answer[]>([]);
  const [answerText, setAnswerText] = useState('');
  const [showAsk, setShowAsk] = useState(false);
  const [routeFilters] = useState(() => {
    if (typeof window === 'undefined') return { courseId: '', lessonId: '' };
    const params = new URLSearchParams(window.location.search);
    return { courseId: params.get('courseId') || '', lessonId: params.get('lessonId') || '' };
  });
  const [courses, setCourses] = useState<{ id: string; title_ar: string; title_en?: string }[]>([]);
  const [newQuestion, setNewQuestion] = useState({ course_id: routeFilters.courseId, title: '', content: '' });
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [answerError, setAnswerError] = useState('');

  const isInstructor = profile?.role === 'instructor';

  const loadQuestions = useCallback(async () => {
    setLoading(true);
    let query = supabase.from('qa_questions').select('*,courses(title_ar,title_en),profiles(name)').eq('is_visible', true);
    if (routeFilters.courseId) query = query.eq('course_id', routeFilters.courseId);
    if (routeFilters.lessonId) query = query.eq('lesson_id', routeFilters.lessonId);
    const { data } = await query.order('created_at', { ascending: false });
    setItems((data || []) as unknown as Question[]);
    setLoading(false);
  }, [routeFilters]);

  useEffect(() => {
    const timer = window.setTimeout(() => void loadQuestions(), 0);
    if (user) {
      supabase.from('enrollments').select('course_id, courses(id, title_ar, title_en)')
        .eq('user_id', user.id).in('status', ['active', 'completed'])
        .then(({ data }) => {
          const list = (data || []).map((e: { course_id: string; courses?: { title_ar: string; title_en?: string }[] }) => {
            const course = Array.isArray(e.courses) ? e.courses[0] : e.courses;
            return { id: e.course_id, title_ar: course?.title_ar || '', title_en: course?.title_en };
          });
          setCourses(list);
        });
    }
    return () => window.clearTimeout(timer);
  }, [loadQuestions, user]);

  async function openQuestion(q: Question) {
    setSelected(q);
    const { data } = await supabase.from('qa_answers').select('*,profiles(name)')
      .eq('question_id', q.id).eq('is_visible', true).order('created_at', { ascending: true });
    setAnswers((data || []) as unknown as Answer[]);
  }

  async function submitAnswer() {
    if (!user || !selected) return;
    if (answerText.trim().length < CONTENT_MIN) {
      setAnswerError(lang === 'ar' ? `الإجابة يجب أن تكون ${CONTENT_MIN} حرف على الأقل` : `Answer must be at least ${CONTENT_MIN} characters`);
      return;
    }
    setAnswerError('');
    await supabase.from('qa_answers').insert({
      question_id: selected.id, user_id: user.id,
      content: answerText.trim(), is_instructor_answer: isInstructor,
    });
    await supabase.from('qa_questions').update({ is_answered: true, answers_count: selected.answers_count + 1 }).eq('id', selected.id);
    setAnswerText('');
    openQuestion({ ...selected, is_answered: true, answers_count: selected.answers_count + 1 });
    loadQuestions();
  }

  function validateQuestion(): string[] {
    const errors: string[] = [];
    if (newQuestion.title.trim().length < TITLE_MIN) {
      errors.push(lang === 'ar' ? `عنوان السؤال يجب أن يكون ${TITLE_MIN} حرف على الأقل` : `Title must be at least ${TITLE_MIN} characters`);
    }
    if (newQuestion.content.trim().length < CONTENT_MIN) {
      errors.push(lang === 'ar' ? `تفاصيل السؤال يجب أن تكون ${CONTENT_MIN} حرف على الأقل` : `Details must be at least ${CONTENT_MIN} characters`);
    }
    if (!newQuestion.course_id) {
      errors.push(lang === 'ar' ? 'اختر الكورس' : 'Select a course');
    }
    return errors;
  }

  async function submitQuestion(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;
    const errors = validateQuestion();
    setValidationErrors(errors);
    if (errors.length > 0) return;
    const { error } = await supabase.from('qa_questions').insert({
      user_id: user.id, course_id: newQuestion.course_id,
      lesson_id: routeFilters.lessonId || null,
      title: newQuestion.title.trim(), content: newQuestion.content.trim(),
    });
    if (error) { setValidationErrors([error.message]); return; }
    setNewQuestion({ course_id: routeFilters.courseId, title: '', content: '' });
    setValidationErrors([]);
    setShowAsk(false);
    loadQuestions();
  }

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.header}>
        <AppBackButton />
        <h1>{lang === 'ar' ? 'الأسئلة والإجابات' : 'Questions & Answers'}</h1>
        <span className={styles.countLabel}>{items.length} {lang === 'ar' ? 'سؤال' : 'questions'}</span>
      </div>

      {user && courses.length > 0 && (
        <div className={styles.toolbar}>
          <AppButton size="small" startIcon={<Chat fontSize="small" />} onClick={() => setShowAsk(!showAsk)}>
            {lang === 'ar' ? 'اسأل سؤالاً' : 'Ask a question'}
          </AppButton>
        </div>
      )}

      {showAsk && (
        <AppCard className={styles.askForm}>
          <h3>{lang === 'ar' ? 'سؤال جديد' : 'New Question'}</h3>
          <form onSubmit={submitQuestion}>
            <select value={newQuestion.course_id} onChange={(e) => setNewQuestion({ ...newQuestion, course_id: e.target.value })} required className={styles.select}>
              <option value="">{lang === 'ar' ? 'اختر الكورس' : 'Select course'}</option>
              {courses.map((c) => <option key={c.id} value={c.id}>{lang === 'ar' ? c.title_ar : c.title_en || c.title_ar}</option>)}
            </select>
            <input value={newQuestion.title} onChange={(e) => setNewQuestion({ ...newQuestion, title: e.target.value })}
              placeholder={lang === 'ar' ? `عنوان السؤال (${TITLE_MIN} حرف minimum)` : `Question title (${TITLE_MIN} chars minimum)`} className={styles.input} />
            <textarea value={newQuestion.content} onChange={(e) => setNewQuestion({ ...newQuestion, content: e.target.value })}
              placeholder={lang === 'ar' ? `تفاصيل السؤال (${CONTENT_MIN} حرف minimum)` : `Question details (${CONTENT_MIN} chars minimum)`} rows={4} className={styles.textarea} />
            {validationErrors.length > 0 && (
              <div className={styles.errors}>{validationErrors.map((err, i) => <p key={i}>{err}</p>)}</div>
            )}
            <AppButton type="submit" size="small" startIcon={<Send fontSize="small" />}>
              {lang === 'ar' ? 'إرسال' : 'Submit'}
            </AppButton>
          </form>
        </AppCard>
      )}

      {loading ? (
        <div className={styles.shimmerGrid}>{Array.from({ length: 4 }).map((_, i) => <ShimmerEffect key={i} height={72} />)}</div>
      ) : items.length === 0 ? (
        <EmptyState type="qa" />
      ) : (
        <section className={styles.list}>
          {items.map((q) => (
            <article key={q.id} className={styles.qaCard} onClick={() => openQuestion(q)}>
              <div className={styles.qaIconWrap}>
                {q.is_answered ? <CheckCircle fontSize="small" className={styles.answeredIcon} /> : <Chat fontSize="small" />}
              </div>
              <div className={styles.qaBody}>
                <h3>{q.title}</h3>
                <p>{q.content}</p>
                <div className={styles.qaMeta}>
                  <span>{q.courses?.title_ar}</span>
                  <span>{q.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')}</span>
                  <span>{q.answers_count} {lang === 'ar' ? 'إجابة' : 'answers'}</span>
                </div>
              </div>
            </article>
          ))}
        </section>
      )}

      {selected && (
        <div className={styles.modalOverlay} onClick={() => setSelected(null)}>
          <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
            <button className={styles.modalClose} onClick={() => setSelected(null)}><Close fontSize="small" /></button>
            <h2>{selected.title}</h2>
            <p className={styles.modalBody}>{selected.content}</p>
            <div className={styles.answersList}>
              <h3>{lang === 'ar' ? 'الإجابات' : 'Answers'}</h3>
              {answers.length === 0 ? (
                <p className={styles.noAnswers}>{lang === 'ar' ? 'لا توجد إجابات بعد' : 'No answers yet'}</p>
              ) : answers.map((a) => (
                <div key={a.id} className={`${styles.answerCard} ${a.is_instructor_answer ? styles.instructorAnswer : ''}`}>
                  <div className={styles.answerHeader}>
                    <strong>{a.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')}</strong>
                    {a.is_instructor_answer && <span className={styles.instructorBadge}><School fontSize="small" />{lang === 'ar' ? 'مدرس' : 'Instructor'}</span>}
                  </div>
                  <p>{a.content}</p>
                </div>
              ))}
            </div>
            {user && (
              <div className={styles.answerForm}>
                <textarea value={answerText} onChange={(e) => { setAnswerText(e.target.value); setAnswerError(''); }}
                  placeholder={lang === 'ar' ? 'اكتب إجابتك...' : 'Write your answer...'} rows={3} className={styles.textarea} />
                {answerError && <p className={styles.answerError}>{answerError}</p>}
                <AppButton size="small" onClick={submitAnswer} disabled={!answerText.trim()} startIcon={<Send fontSize="small" />}>
                  {lang === 'ar' ? 'إضافة إجابة' : 'Add answer'}
                </AppButton>
              </div>
            )}
          </div>
        </div>
      )}
    </main>
  );
}
