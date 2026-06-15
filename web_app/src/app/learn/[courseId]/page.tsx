'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, ArrowRight, BarChart3, Bookmark, CheckCircle, ChevronLeft,
  ClipboardCheck, Clock3, Download, FileText, ListVideo, Lock, Menu,
  Play, Share2, User,
} from 'lucide-react';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { VideoPlayer } from '../../../components/VideoPlayer';
import styles from './page.module.css';

interface Lesson {
  id: string;
  title_ar: string;
  title_en: string;
  type: string;
  video_url: string;
  article_content_ar: string;
  article_content_en: string;
  file_url: string;
  file_name: string;
  video_duration?: number;
}

interface Section {
  id: string;
  title_ar: string;
  title_en: string;
  lessons: Lesson[];
}

interface CourseSummary {
  title_ar: string;
  title_en: string;
  description_ar: string;
  description_en: string;
}

export default function CoursePlayerPage() {
  const { courseId } = useParams();
  const router = useRouter();
  const { lang, t, user, loading: authLoading } = useApp();
  const [sections, setSections] = useState<Section[]>([]);
  const [course, setCourse] = useState<CourseSummary | null>(null);
  const [activeLesson, setActiveLesson] = useState<Lesson | null>(null);
  const [completedLessons, setCompletedLessons] = useState<string[]>([]);
  const [lastPositions, setLastPositions] = useState<Record<string, number>>({});
  const [enrollmentId, setEnrollmentId] = useState('');
  const [quizzesByLesson, setQuizzesByLesson] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<'description' | 'files' | 'homework' | 'questions'>('description');
  const progressRef = useRef({ position: 0, duration: 0, watchTime: 0 });
  const watchTimesRef = useRef<Record<string, number>>({});
  const userId = user?.id;

  useEffect(() => {
    if (authLoading || !courseId) return;
    if (!userId) {
      router.push('/login');
      return;
    }
    const currentUserId = userId;

    async function fetchCourseData() {
      try {
        const { data: enrollData } = await supabase.from('enrollments').select('id')
          .eq('user_id', currentUserId).eq('course_id', courseId)
          .in('status', ['active', 'completed']).maybeSingle();
        if (!enrollData) {
          router.push(`/courses/${courseId}`);
          return;
        }
        setEnrollmentId(enrollData.id);

        const { data: courseData } = await supabase.from('courses')
          .select('title_ar, title_en, description_ar, description_en').eq('id', courseId).maybeSingle();
        if (courseData) setCourse(courseData as CourseSummary);

        const { data: sectionsData } = await supabase.from('sections').select('*')
          .eq('course_id', courseId).eq('is_published', true).order('sort_order');
        const fullSections = await Promise.all(((sectionsData || []) as Section[]).map(async (section) => {
          const { data } = await supabase.from('lessons').select('*')
            .eq('section_id', section.id).eq('is_published', true).order('sort_order');
          return { ...section, lessons: (data || []) as Lesson[] };
        }));
        setSections(fullSections);
        setActiveLesson(fullSections.find((section) => section.lessons.length)?.lessons[0] || null);

        const { data: progressData } = await supabase.from('lesson_progress')
          .select('lesson_id, is_completed, last_position, watch_time')
          .eq('user_id', currentUserId).eq('course_id', courseId);
        const positions: Record<string, number> = {};
        const times: Record<string, number> = {};
        (progressData || []).forEach((progress) => {
          positions[progress.lesson_id as string] = Number(progress.last_position || 0);
          times[progress.lesson_id as string] = Number(progress.watch_time || 0);
        });
        setLastPositions(positions);
        watchTimesRef.current = times;
        setCompletedLessons((progressData || []).filter((progress) => progress.is_completed).map((progress) => progress.lesson_id as string));

        const { data: quizData } = await supabase.from('quizzes').select('id, lesson_id')
          .eq('course_id', courseId).eq('is_published', true);
        setQuizzesByLesson(Object.fromEntries((quizData || []).filter((quiz) => quiz.lesson_id).map((quiz) => [quiz.lesson_id, quiz.id])));
      } catch (error) {
        console.error('Error fetching player data:', error);
      } finally {
        setLoading(false);
      }
    }
    fetchCourseData();
  }, [authLoading, courseId, router, userId]);

  const saveProgress = useCallback(async (lessonId: string, isCompleted: boolean) => {
    if (!userId) return;
    const { position, watchTime } = progressRef.current;
    const totalWatchTime = (watchTimesRef.current[lessonId] || 0) + Math.max(0, watchTime);
    const { error } = await supabase.rpc('update_lesson_progress', {
      p_lesson_id: lessonId, p_watch_time: Math.round(totalWatchTime),
      p_last_position: Math.round(position), p_is_completed: isCompleted,
    });
    if (!error) {
      watchTimesRef.current[lessonId] = totalWatchTime;
      progressRef.current.watchTime = 0;
    }
  }, [userId]);

  const toggleCompleted = useCallback(async (lessonId: string) => {
    const completed = !completedLessons.includes(lessonId);
    await saveProgress(lessonId, completed);
    setCompletedLessons((previous) => completed ? [...previous, lessonId] : previous.filter((id) => id !== lessonId));
  }, [completedLessons, saveProgress]);

  const handleVideoProgress = useCallback((position: number, duration: number) => {
    progressRef.current.position = position;
    progressRef.current.duration = duration;
  }, []);

  const handleVideoComplete = useCallback(() => {
    if (activeLesson) void toggleCompleted(activeLesson.id);
  }, [activeLesson, toggleCompleted]);

  useEffect(() => {
    if (!activeLesson || activeLesson.type !== 'video') return;
    let lastSavedAt = Date.now();
    const interval = window.setInterval(() => {
      const now = Date.now();
      progressRef.current.watchTime = Math.floor((now - lastSavedAt) / 1000);
      lastSavedAt = now;
      saveProgress(activeLesson.id, completedLessons.includes(activeLesson.id));
    }, 10000);
    return () => window.clearInterval(interval);
  }, [activeLesson, completedLessons, saveProgress]);

  if (loading) return <div className={styles.loadingState}><div className={styles.spinner} /><p>{t.loading}</p></div>;

  const flatLessons = sections.flatMap((section) => section.lessons.map((lesson) => ({ lesson, section })));
  const activeIndex = flatLessons.findIndex(({ lesson }) => lesson.id === activeLesson?.id);
  const activeSection = activeIndex >= 0 ? flatLessons[activeIndex].section : null;
  const previousLesson = activeIndex > 0 ? flatLessons[activeIndex - 1].lesson : null;
  const nextLesson = activeIndex >= 0 && activeIndex < flatLessons.length - 1 ? flatLessons[activeIndex + 1].lesson : null;
  const progress = flatLessons.length ? Math.round((completedLessons.length / flatLessons.length) * 100) : 0;
  const title = activeLesson ? (lang === 'ar' ? activeLesson.title_ar : activeLesson.title_en) : '';
  const sectionTitle = activeSection ? (lang === 'ar' ? activeSection.title_ar : activeSection.title_en) : '';
  const selectLesson = (lesson: Lesson | null) => {
    if (!lesson) return;
    setActiveLesson(lesson);
    if (window.innerWidth < 900) setSidebarOpen(false);
  };

  return (
    <div className={styles.page}>
      <div className={styles.breadcrumbs}><span>{lang === 'ar' ? 'الكورسات' : 'Courses'}</span><ChevronLeft size={14} /><span>{course ? (lang === 'ar' ? course.title_ar : course.title_en) : ''}</span><ChevronLeft size={14} /><strong>{title}</strong></div>
      <button className={styles.sidebarToggle} onClick={() => setSidebarOpen(!sidebarOpen)}><Menu size={19} /></button>

      <div className={styles.layout}>
        <aside className={`${styles.sidebar} ${sidebarOpen ? styles.sidebarVisible : ''}`}>
          <section className={styles.progressCard}>
            <div className={styles.cardTitle}><BarChart3 size={18} /><strong>{lang === 'ar' ? 'تقدم الكورس' : 'Course progress'}</strong></div>
            <b>{progress}%</b><span>{lang === 'ar' ? 'اكتمال الكورس' : 'Course complete'}</span>
            <div className={styles.progressTrack}><i style={{ width: `${progress}%` }} /></div>
            <small>{completedLessons.length} {lang === 'ar' ? `من ${flatLessons.length} درس مكتمل` : `of ${flatLessons.length} lessons completed`}</small>
          </section>

          <section className={styles.curriculumCard}>
            <div className={styles.cardTitle}><Share2 size={16} /><strong>{lang === 'ar' ? 'محتوى الكورس' : 'Course content'}</strong></div>
            <div className={styles.curriculum}>
              {sections.map((section) => <div key={section.id} className={styles.sectionGroup}>
                <h4>{lang === 'ar' ? section.title_ar : section.title_en}</h4>
                {section.lessons.map((lesson, index) => {
                  const isActive = lesson.id === activeLesson?.id;
                  const isDone = completedLessons.includes(lesson.id);
                  return <button key={lesson.id} onClick={() => selectLesson(lesson)} className={isActive ? styles.activeLesson : ''}>
                    <span>{isDone ? <CheckCircle size={15} /> : isActive ? <Play size={14} fill="currentColor" /> : <Lock size={13} />}</span>
                    <strong>{lang === 'ar' ? lesson.title_ar : lesson.title_en}</strong>
                    <small>{lesson.video_duration ? `${Math.round(lesson.video_duration / 60)}:00` : `0${index + 1}`}</small>
                  </button>;
                })}
              </div>)}
            </div>
            <button className={styles.showAll}><ListVideo size={16} />{lang === 'ar' ? 'عرض كل محتوى الكورس' : 'Show all content'}</button>
          </section>
        </aside>

        <main className={styles.main}>
          {activeLesson ? <>
            <section className={styles.mediaStage}>
              <header className={styles.lessonHeader}>
                <div className={styles.stageHeading}><span>{sectionTitle}</span><h1>{title}</h1><div><span><CheckCircle size={15} />{completedLessons.includes(activeLesson.id) ? t.completed : t.markCompleted}</span><span><Clock3 size={15} />{activeLesson.video_duration ? `${Math.round(activeLesson.video_duration / 60)} ${lang === 'ar' ? 'دقيقة' : 'min'}` : '21:15'}</span></div></div>
                <div className={styles.stageButtons}><button><Share2 size={18} /></button><button><Bookmark size={18} /></button></div>
              </header>
              <div className={styles.mediaContent}>
                {activeLesson.type === 'video' && activeLesson.video_url && <VideoPlayer videoUrl={activeLesson.video_url} title={title} lessonId={activeLesson.id} startAt={lastPositions[activeLesson.id] || 0} onProgress={handleVideoProgress} onComplete={handleVideoComplete} />}
                {activeLesson.type === 'article' && <div className={styles.articleCard}><h2>{title}</h2><div dangerouslySetInnerHTML={{ __html: lang === 'ar' ? activeLesson.article_content_ar : activeLesson.article_content_en }} /></div>}
                {activeLesson.type === 'quiz' && <div className={styles.fallback}><ClipboardCheck size={46} /><h2>{title}</h2>{quizzesByLesson[activeLesson.id] && <Link href={`/quiz/${quizzesByLesson[activeLesson.id]}?enrollment=${enrollmentId}&courseId=${courseId}`}>{lang === 'ar' ? 'فتح الامتحان' : 'Open exam'}</Link>}</div>}
                {!['video', 'article', 'quiz'].includes(activeLesson.type) && <div className={styles.fallback}><FileText size={46} /><h2>{title}</h2>{activeLesson.file_url && <a href={activeLesson.file_url} target="_blank" rel="noreferrer">{lang === 'ar' ? 'تحميل الملف' : 'Download file'}</a>}</div>}
              </div>
            </section>

            <div className={styles.infoGrid}>
              <section className={styles.infoCard}>
                <div className={styles.tabs}>{(['description', 'files', 'homework', 'questions'] as const).map((tab) => <button key={tab} onClick={() => setActiveTab(tab)} className={activeTab === tab ? styles.activeTab : ''}>{tab === 'description' ? (lang === 'ar' ? 'الوصف' : 'Description') : tab === 'files' ? (lang === 'ar' ? 'الملفات' : 'Files') : tab === 'homework' ? (lang === 'ar' ? 'الواجب' : 'Homework') : (lang === 'ar' ? 'الأسئلة' : 'Questions')}</button>)}</div>
                <div className={styles.tabPanel}>
                  {activeTab === 'description' && <div dangerouslySetInnerHTML={{ __html: (lang === 'ar' ? activeLesson.article_content_ar : activeLesson.article_content_en) || (course ? (lang === 'ar' ? course.description_ar : course.description_en) : '') || (lang === 'ar' ? 'في هذا الدرس ستتعرف على المفاهيم الأساسية مع أمثلة وتطبيقات.' : 'Learn the core concepts with examples and practice.') }} />}
                  {activeTab === 'files' && (activeLesson.file_url ? <a href={activeLesson.file_url} target="_blank" rel="noreferrer" className={styles.fileItem}><FileText size={20} /><span>{activeLesson.file_name || (lang === 'ar' ? 'ملخص الدرس' : 'Lesson summary')}</span><Download size={16} /></a> : <p>{lang === 'ar' ? 'لا توجد ملفات مرفقة.' : 'No attached files.'}</p>)}
                  {activeTab === 'homework' && <p>{lang === 'ar' ? 'سيظهر واجب الدرس هنا عند إضافته.' : 'Homework will appear here.'}</p>}
                  {activeTab === 'questions' && <p>{lang === 'ar' ? 'راجع وناقش أسئلة الدرس هنا.' : 'Review lesson questions here.'}</p>}
                </div>
              </section>
              <aside className={styles.instructorCard}><div className={styles.avatar}><User size={28} /></div><div><strong>{lang === 'ar' ? 'د/ أحمد الشيخ' : 'Dr. Ahmed El-Sheikh'}</strong><small>{lang === 'ar' ? 'مدرس الكيمياء للمرحلة الثانوية' : 'High school chemistry teacher'}</small></div><Link href="/settings">{lang === 'ar' ? 'عرض الملف الشخصي' : 'View profile'}</Link></aside>
            </div>

            <nav className={styles.lessonNav}><button onClick={() => selectLesson(previousLesson)} disabled={!previousLesson}><ArrowRight size={18} />{lang === 'ar' ? 'السابق' : 'Previous'}</button><button onClick={() => selectLesson(nextLesson)} disabled={!nextLesson}>{lang === 'ar' ? 'التالي' : 'Next'}<ArrowLeft size={18} /></button></nav>
          </> : <div className={styles.empty}>{lang === 'ar' ? 'اختر درسًا للبدء' : 'Select a lesson to start'}</div>}
        </main>
      </div>
    </div>
  );
}
