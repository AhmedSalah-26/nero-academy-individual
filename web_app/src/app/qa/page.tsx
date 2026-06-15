'use client';

import { useCallback, useEffect, useState } from 'react';
import { CircleHelp, CheckCircle2, MessageCircle, Send, X } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import styles from '../student-features.module.css';

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

export default function QAPage() {
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
  const [message, setMessage] = useState('');

  const isInstructor = profile?.role === 'instructor';

  const loadQuestions = useCallback(async () => {
    setLoading(true);
    let query = supabase
      .from('qa_questions')
      .select('*,courses(title_ar,title_en),profiles(name)')
      .eq('is_visible', true);
    if (routeFilters.courseId) query = query.eq('course_id', routeFilters.courseId);
    if (routeFilters.lessonId) query = query.eq('lesson_id', routeFilters.lessonId);
    const { data } = await query.order('created_at', { ascending: false });
    setItems((data || []) as unknown as Question[]);
    setLoading(false);
  }, [routeFilters]);

  useEffect(() => {
    const questionsTimer = window.setTimeout(() => void loadQuestions(), 0);

    if (user) {
      supabase
        .from('enrollments')
        .select('course_id, courses(id, title_ar, title_en)')
        .eq('user_id', user.id)
        .in('status', ['active', 'completed'])
        .then(({ data }) => {
          const list = (data || []).map((e: { course_id: string; courses?: { title_ar: string; title_en?: string }[] }) => {
          const course = Array.isArray(e.courses) ? e.courses[0] : e.courses;
          return {
            id: e.course_id,
            title_ar: course?.title_ar || '',
            title_en: course?.title_en,
          };
        });
          setCourses(list);
        });
    }

    return () => window.clearTimeout(questionsTimer);
  }, [loadQuestions, user]);

  async function openQuestion(q: Question) {
    setSelected(q);
    const { data } = await supabase
      .from('qa_answers')
      .select('*,profiles(name)')
      .eq('question_id', q.id)
      .eq('is_visible', true)
      .order('created_at', { ascending: true });
    setAnswers((data || []) as unknown as Answer[]);
  }

  async function submitAnswer() {
    if (!user || !selected || !answerText.trim()) return;

    await supabase.from('qa_answers').insert({
      question_id: selected.id,
      user_id: user.id,
      content: answerText.trim(),
      is_instructor_answer: isInstructor,
    });

    await supabase
      .from('qa_questions')
      .update({ is_answered: true, answers_count: selected.answers_count + 1 })
      .eq('id', selected.id);

    setAnswerText('');
    openQuestion({ ...selected, is_answered: true, answers_count: selected.answers_count + 1 });
    loadQuestions();
  }

  async function submitQuestion(e: React.FormEvent) {
    e.preventDefault();
    if (!user || !newQuestion.course_id || !newQuestion.title.trim()) return;

    const { error } = await supabase.from('qa_questions').insert({
      user_id: user.id,
      course_id: newQuestion.course_id,
      lesson_id: routeFilters.lessonId || null,
      title: newQuestion.title.trim(),
      content: newQuestion.content.trim(),
    });

    if (error) {
      setMessage(error.message);
    } else {
      setMessage(lang === 'ar' ? 'تم إرسال السؤال' : 'Question submitted');
      setNewQuestion({ course_id: routeFilters.courseId, title: '', content: '' });
      setShowAsk(false);
      loadQuestions();
    }
  }

  return (
    <main className={styles.page}>
      <FeaturePageHero
        icon={CircleHelp}
        eyebrow="Q&A"
        title={lang === 'ar' ? 'الأسئلة والإجابات' : 'Questions & Answers'}
        subtitle={lang === 'ar' ? 'ابحث عن إجابة أو راجع أسئلة الطلاب والمدرس.' : 'Find answers from students and the instructor.'}
      />

      {user && courses.length > 0 && (
        <div className={styles.toolbar}>
          <button className={styles.action} onClick={() => setShowAsk(!showAsk)}>
            <MessageCircle size={14} />
            {lang === 'ar' ? 'اسأل سؤالاً جديداً' : 'Ask a new question'}
          </button>
        </div>
      )}

      {showAsk && (
        <form onSubmit={submitQuestion} className={`${styles.card} ${styles.askForm}`}>
          <h3>{lang === 'ar' ? 'سؤال جديد' : 'New Question'}</h3>
          <select
            value={newQuestion.course_id}
            onChange={(e) => setNewQuestion({ ...newQuestion, course_id: e.target.value })}
            required
            className={styles.input}
          >
            <option value="">{lang === 'ar' ? 'اختر الكورس' : 'Select course'}</option>
            {courses.map((c) => (
              <option key={c.id} value={c.id}>
                {lang === 'ar' ? c.title_ar : c.title_en || c.title_ar}
              </option>
            ))}
          </select>
          <input
            value={newQuestion.title}
            onChange={(e) => setNewQuestion({ ...newQuestion, title: e.target.value })}
            placeholder={lang === 'ar' ? 'عنوان السؤال' : 'Question title'}
            required
            className={styles.input}
          />
          <textarea
            value={newQuestion.content}
            onChange={(e) => setNewQuestion({ ...newQuestion, content: e.target.value })}
            placeholder={lang === 'ar' ? 'تفاصيل السؤال' : 'Question details'}
            rows={4}
            className={styles.input}
          />
          {message && <div className={styles.message}>{message}</div>}
          <button type="submit" className={styles.action}>
            <Send size={14} /> {lang === 'ar' ? 'إرسال' : 'Submit'}
          </button>
        </form>
      )}

      {loading ? (
        <div className={styles.empty}>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</div>
      ) : items.length === 0 ? (
        <div className={styles.empty}>
          <CircleHelp size={38} />
          <strong>{lang === 'ar' ? 'لا توجد أسئلة بعد' : 'No questions yet'}</strong>
        </div>
      ) : (
        <section className={styles.list}>
          {items.map((q) => (
            <article
              key={q.id}
              className={`${styles.card} ${styles.qaCard}`}
              onClick={() => openQuestion(q)}
            >
              <div className={styles.cardTop}>
                <div className={styles.cardIcon}>{q.is_answered ? <CheckCircle2 /> : <MessageCircle />}</div>
                <span className={styles.badge}>{q.is_answered ? (lang === 'ar' ? 'تمت الإجابة' : 'Answered') : (lang === 'ar' ? 'بانتظار الإجابة' : 'Pending')}</span>
              </div>
              <h3>{q.title}</h3>
              <p>{q.content}</p>
              <div className={styles.meta}>
                <span>{q.courses?.title_ar}</span>
                <span>{q.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')}</span>
                <span>{q.answers_count} {lang === 'ar' ? 'إجابة' : 'answers'}</span>
              </div>
            </article>
          ))}
        </section>
      )}

      {selected && (
        <div className={styles.modalOverlay} onClick={() => setSelected(null)}>
          <div className={`${styles.modal} glass`} onClick={(e) => e.stopPropagation()}>
            <button className={styles.modalClose} onClick={() => setSelected(null)}>
              <X size={20} />
            </button>
            <h2>{selected.title}</h2>
            <p className={styles.modalBody}>{selected.content}</p>

            <div className={styles.answersList}>
              <h3>{lang === 'ar' ? 'الإجابات' : 'Answers'}</h3>
              {answers.length === 0 ? (
                <div className={styles.empty}>{lang === 'ar' ? 'لا توجد إجابات بعد' : 'No answers yet'}</div>
              ) : (
                answers.map((a) => (
                  <div key={a.id} className={`${styles.answerCard} ${a.is_instructor_answer ? styles.instructorAnswer : ''}`}>
                    <strong>{a.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')}</strong>
                    {a.is_instructor_answer && <span className={styles.badge}>{lang === 'ar' ? 'مدرس' : 'Instructor'}</span>}
                    <p>{a.content}</p>
                  </div>
                ))
              )}
            </div>

            {user && (
              <div className={styles.answerForm}>
                <textarea
                  value={answerText}
                  onChange={(e) => setAnswerText(e.target.value)}
                  placeholder={lang === 'ar' ? 'اكتب إجابتك...' : 'Write your answer...'}
                  rows={3}
                  className={styles.input}
                />
                <button onClick={submitAnswer} disabled={!answerText.trim()} className={styles.action}>
                  <Send size={14} /> {lang === 'ar' ? 'إضافة إجابة' : 'Add answer'}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </main>
  );
}
