'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowBack, ArrowForward, BarChart, Bookmark, BookmarkBorder, CheckCircle, ChevronLeft,
  AssignmentTurnedIn, Schedule, Download, Description, VideoLibrary, Lock, Menu,
  Help as HelpIcon, PlayArrow, Share, Person, Star, StarBorder, MoreHoriz,
  Speed, Fullscreen, FullscreenExit, EmojiEvents, Delete, Add, Send,
} from '@mui/icons-material';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { VideoPlayer } from '../../../components/VideoPlayer';
import { AppButton, ResponsiveDialog, RatingStars } from '../../../components/ui';
import { sanitizeHtml } from '../../../lib/sanitize';
import { usePageTransition } from '../../../lib/animations';
import styles from './page.module.css';

interface Lesson {
  id: string;
  title_ar: string;
  title_en: string;
  description_ar: string;
  description_en: string;
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
  instructor_id: string;
  title_ar: string;
  title_en: string;
  description_ar: string;
  description_en: string;
  rating?: number;
  rating_count?: number;
  rating_distribution?: Record<string, number>;
  profiles?: { id: string; name?: string; avatar_url?: string } | null;
}

interface Attachment {
  id: string;
  file_name: string;
  file_name_ar?: string;
  file_url: string;
  file_type?: string;
  file_size?: number;
}

interface Question {
  id: string;
  title: string;
  content: string;
  is_answered: boolean;
  answers_count: number;
  profiles?: { name?: string } | null;
}

interface Instructor {
  display_name?: string;
  headline_ar?: string;
  headline_en?: string;
  avatar_url?: string;
}

interface Note {
  id: string;
  content: string;
  timestamp: number;
  created_at: string;
}

interface BookmarkItem {
  id: string;
  lesson_id: string;
  lesson_title_ar?: string;
  lesson_title_en?: string;
  created_at: string;
}

type PlayerTab = 'lectures' | 'more' | 'qa' | 'quizzes' | 'rating';
type MoreSubTab = 'notes' | 'bookmarks' | 'announcements' | 'attachments';

export default function CoursePlayerPage() {
  const { courseId } = useParams();
  const router = useRouter();
  const pageRef = usePageTransition();
  const { lang, t, user, loading: authLoading } = useApp();
  const [sections, setSections] = useState<Section[]>([]);
  const [course, setCourse] = useState<CourseSummary | null>(null);
  const [activeLesson, setActiveLesson] = useState<Lesson | null>(null);
  const [completedLessons, setCompletedLessons] = useState<string[]>([]);
  const [lastPositions, setLastPositions] = useState<Record<string, number>>({});
  const [enrollmentId, setEnrollmentId] = useState('');
  const [quizzesByLesson, setQuizzesByLesson] = useState<Record<string, string>>({});
  const [courseAttachments, setCourseAttachments] = useState<Attachment[]>([]);
  const [lessonAttachments, setLessonAttachments] = useState<Attachment[]>([]);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [instructor, setInstructor] = useState<Instructor | null>(null);
  const [tabLoading, setTabLoading] = useState(false);
  const [loading, setLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<PlayerTab>('lectures');
  const [moreSubTab, setMoreSubTab] = useState<MoreSubTab>('notes');
  const [notes, setNotes] = useState<Note[]>([]);
  const [newNote, setNewNote] = useState('');
  const [noteTimestamp, setNoteTimestamp] = useState(0);
  const [bookmarks, setBookmarks] = useState<BookmarkItem[]>([]);
  const [playbackSpeed, setPlaybackSpeed] = useState(1);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [showCompletionDialog, setShowCompletionDialog] = useState(false);
  const [showSpeedMenu, setShowSpeedMenu] = useState(false);
  const [userRating, setUserRating] = useState(0);
  const [reviewText, setReviewText] = useState('');
  const mediaStageRef = useRef<HTMLDivElement>(null);
  const progressRef = useRef({ position: 0, duration: 0, watchTime: 0 });
  const watchTimesRef = useRef<Record<string, number>>({});
  const userId = user?.id;

  const SPEED_OPTIONS = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

  useEffect(() => {
    if (authLoading || !courseId) return;
    if (!userId) { router.push('/login'); return; }
    const currentUserId = userId;

    async function fetchCourseData() {
      try {
        const { data: enrollData } = await supabase.from('enrollments').select('id')
          .eq('user_id', currentUserId).eq('course_id', courseId)
          .in('status', ['active', 'completed']).maybeSingle();
        if (!enrollData) { router.push(`/courses/${courseId}`); return; }
        setEnrollmentId(enrollData.id);

        const { data: courseData } = await supabase.from('courses')
          .select('instructor_id, title_ar, title_en, description_ar, description_en, rating, rating_count, rating_distribution, profiles!courses_instructor_id_fkey(id,name,avatar_url)')
          .eq('id', courseId).maybeSingle();
        if (courseData) {
          setCourse(courseData as unknown as CourseSummary);
          const { data: instructorData } = await supabase.from('instructor_profiles')
            .select('display_name, headline_ar, headline_en, avatar_url')
            .eq('instructor_id', courseData.instructor_id).limit(1).maybeSingle();
          setInstructor((instructorData as Instructor | null) || {
            display_name: (courseData as unknown as CourseSummary).profiles?.name,
            avatar_url: (courseData as unknown as CourseSummary).profiles?.avatar_url,
          });
        }

        const { data: courseFiles } = await supabase.from('course_attachments').select('*')
          .eq('course_id', courseId).order('sort_order');
        setCourseAttachments((courseFiles || []) as Attachment[]);

        const { data: sectionsData } = await supabase.from('sections').select('*')
          .eq('course_id', courseId).eq('is_published', true).order('sort_order');
        const fullSections = await Promise.all(((sectionsData || []) as Section[]).map(async (section) => {
          const { data } = await supabase.from('lessons').select('*')
            .eq('section_id', section.id).eq('is_published', true).order('sort_order');
          return { ...section, lessons: (data || []) as Lesson[] };
        }));
        setSections(fullSections);
        setActiveLesson(fullSections.find((s) => s.lessons.length)?.lessons[0] || null);

        const { data: progressData } = await supabase.from('lesson_progress')
          .select('lesson_id, is_completed, last_position, watch_time')
          .eq('user_id', currentUserId).eq('course_id', courseId);
        const positions: Record<string, number> = {};
        const times: Record<string, number> = {};
        (progressData || []).forEach((p) => {
          positions[p.lesson_id as string] = Number(p.last_position || 0);
          times[p.lesson_id as string] = Number(p.watch_time || 0);
        });
        setLastPositions(positions);
        watchTimesRef.current = times;
        setCompletedLessons((progressData || []).filter((p) => p.is_completed).map((p) => p.lesson_id as string));

        const { data: quizData } = await supabase.from('quizzes').select('id, lesson_id')
          .eq('course_id', courseId).eq('is_published', true);
        setQuizzesByLesson(Object.fromEntries((quizData || []).filter((q) => q.lesson_id).map((q) => [q.lesson_id, q.id])));

        const { data: notesData } = await supabase.from('notes').select('*')
          .eq('user_id', currentUserId).eq('course_id', courseId).order('created_at', { ascending: false });
        setNotes((notesData || []) as Note[]);

        const { data: bookmarksData } = await supabase.from('bookmarks').select('id, lesson_id, created_at, lessons(title_ar, title_en)')
          .eq('user_id', currentUserId).eq('course_id', courseId).order('created_at', { ascending: false });
        if (bookmarksData) {
          setBookmarks((bookmarksData as unknown as BookmarkItem[]).map((b: BookmarkItem & { lessons?: { title_ar?: string; title_en?: string } }) => ({
            id: b.id, lesson_id: b.lesson_id, created_at: b.created_at,
            lesson_title_ar: b.lessons?.title_ar, lesson_title_en: b.lessons?.title_en,
          })));
        }
      } catch (error) {
        console.error('Error fetching player data:', error);
      } finally {
        setLoading(false);
      }
    }
    fetchCourseData();
  }, [authLoading, courseId, router, userId]);

  useEffect(() => {
    if (!activeLesson || !courseId) return;
    let cancelled = false;
    const timer = window.setTimeout(() => setTabLoading(true), 0);
    Promise.all([
      supabase.from('lesson_attachments').select('*').eq('lesson_id', activeLesson.id).order('sort_order'),
      supabase.from('qa_questions').select('id,title,content,is_answered,answers_count,profiles(name)')
        .eq('course_id', courseId).eq('lesson_id', activeLesson.id).eq('is_visible', true)
        .order('created_at', { ascending: false }),
    ]).then(([filesResult, questionsResult]) => {
      if (cancelled) return;
      setLessonAttachments((filesResult.data || []) as Attachment[]);
      setQuestions((questionsResult.data as unknown as Question[]) || []);
      setTabLoading(false);
    });
    return () => { cancelled = true; window.clearTimeout(timer); };
  }, [activeLesson, courseId]);

  const saveProgress = useCallback(async (lessonId: string, isCompleted: boolean) => {
    if (!userId) return;
    const { position, watchTime } = progressRef.current;
    const total = (watchTimesRef.current[lessonId] || 0) + Math.max(0, watchTime);
    const { error } = await supabase.rpc('update_lesson_progress', {
      p_lesson_id: lessonId, p_watch_time: Math.round(total),
      p_last_position: Math.round(position), p_is_completed: isCompleted,
    });
    if (!error) { watchTimesRef.current[lessonId] = total; progressRef.current.watchTime = 0; }
  }, [userId]);

  const toggleCompleted = useCallback(async (lessonId: string) => {
    const completed = !completedLessons.includes(lessonId);
    await saveProgress(lessonId, completed);
    const newCompleted = completed ? [...completedLessons, lessonId] : completedLessons.filter((id) => id !== lessonId);
    setCompletedLessons(newCompleted);
    const totalLessons = sections.flatMap((s) => s.lessons).length;
    if (completed && newCompleted.length === totalLessons && totalLessons > 0) {
      setShowCompletionDialog(true);
    }
  }, [completedLessons, saveProgress, sections]);

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
    }, 30000);
    return () => window.clearInterval(interval);
  }, [activeLesson, completedLessons, saveProgress]);

  const handleAddNote = async () => {
    if (!userId || !activeLesson || !newNote.trim()) return;
    const { data } = await supabase.from('notes').insert({
      user_id: userId, course_id: courseId, lesson_id: activeLesson.id,
      content: newNote.trim(), timestamp: noteTimestamp,
    }).select('*').single();
    if (data) { setNotes([data as Note, ...notes]); setNewNote(''); setNoteTimestamp(0); }
  };

  const handleDeleteNote = async (noteId: string) => {
    await supabase.from('notes').delete().eq('id', noteId);
    setNotes(notes.filter((n) => n.id !== noteId));
  };

  const handleToggleBookmark = async () => {
    if (!userId || !activeLesson) return;
    const existing = bookmarks.find((b) => b.lesson_id === activeLesson.id);
    if (existing) {
      await supabase.from('bookmarks').delete().eq('id', existing.id);
      setBookmarks(bookmarks.filter((b) => b.id !== existing.id));
    } else {
      const { data } = await supabase.from('bookmarks').insert({
        user_id: userId, course_id: courseId, lesson_id: activeLesson.id,
      }).select('id, lesson_id, created_at, lessons(title_ar, title_en)').single();
      if (data) {
        const d = data as unknown as BookmarkItem & { lessons?: { title_ar?: string; title_en?: string } };
        setBookmarks([{ id: d.id, lesson_id: d.lesson_id, created_at: d.created_at, lesson_title_ar: d.lessons?.title_ar, lesson_title_en: d.lessons?.title_en }, ...bookmarks]);
      }
    }
  };

  const handleToggleFullscreen = () => {
    if (!mediaStageRef.current) return;
    if (!document.fullscreenElement) {
      mediaStageRef.current.requestFullscreen().then(() => setIsFullscreen(true)).catch(() => {});
    } else {
      document.exitFullscreen().then(() => setIsFullscreen(false)).catch(() => {});
    }
  };

  const isBookmarked = activeLesson ? bookmarks.some((b) => b.lesson_id === activeLesson.id) : false;

  const formatTimestamp = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${String(s).padStart(2, '0')}`;
  };

  if (loading) return <div className={styles.loadingState}><div className={styles.spinner} /><p>{t.loading}</p></div>;

  const flatLessons = sections.flatMap((section) => section.lessons.map((lesson) => ({ lesson, section })));
  const activeIndex = flatLessons.findIndex(({ lesson }) => lesson.id === activeLesson?.id);
  const activeSection = activeIndex >= 0 ? flatLessons[activeIndex].section : null;
  const previousLesson = activeIndex > 0 ? flatLessons[activeIndex - 1].lesson : null;
  const nextLesson = activeIndex >= 0 && activeIndex < flatLessons.length - 1 ? flatLessons[activeIndex + 1].lesson : null;
  const progress = flatLessons.length ? Math.round((completedLessons.length / flatLessons.length) * 100) : 0;
  const title = activeLesson ? (lang === 'ar' ? activeLesson.title_ar : activeLesson.title_en) : '';
  const sectionTitle = activeSection ? (lang === 'ar' ? activeSection.title_ar : activeSection.title_en) : '';
  const allAttachments = [
    ...(activeLesson?.file_url ? [{ id: `lesson-file-${activeLesson.id}`, file_name: activeLesson.file_name || 'Lesson file', file_name_ar: activeLesson.file_name || 'ملف الدرس', file_url: activeLesson.file_url }] : []),
    ...lessonAttachments, ...courseAttachments,
  ].filter((file, index, files) => files.findIndex((item) => item.file_url === file.file_url) === index);
  const assignments = activeSection?.lessons.filter((l) => l.type === 'assignment') || [];
  const instructorName = instructor?.display_name || course?.profiles?.name || (lang === 'ar' ? 'مدرس الكورس' : 'Course instructor');
  const instructorHeadline = lang === 'ar' ? instructor?.headline_ar || 'مدرس الكيمياء' : instructor?.headline_en || 'Chemistry teacher';
  const instructorAvatar = instructor?.avatar_url || course?.profiles?.avatar_url;
  const courseQuizzes = Object.entries(quizzesByLesson);
  const selectLesson = (lesson: Lesson | null) => { if (!lesson) return; setActiveLesson(lesson); if (window.innerWidth < 900) setSidebarOpen(false); };

  const ratingBuckets = (() => {
    const dist = course?.rating_distribution || {};
    const total = course?.rating_count || 0;
    const buckets = [];
    for (let s = 5; s >= 1; s--) {
      const count = dist[String(s)] || 0;
      const pct = total > 0 ? Math.round((count / total) * 100) : 0;
      buckets.push({ stars: s, count, percentage: pct });
    }
    return buckets;
  })();

  const tabLabels: Record<PlayerTab, { ar: string; en: string }> = {
    lectures: { ar: 'الدروس', en: 'Lectures' },
    more: { ar: 'المزيد', en: 'More' },
    qa: { ar: 'سؤال وجواب', en: 'Q&A' },
    quizzes: { ar: 'الاختبارات', en: 'Quizzes' },
    rating: { ar: 'التقييم', en: 'Rating' },
  };

  const moreSubTabLabels: Record<MoreSubTab, { ar: string; en: string }> = {
    notes: { ar: 'ملاحظات', en: 'Notes' },
    bookmarks: { ar: 'إشارات مرجعية', en: 'Bookmarks' },
    announcements: { ar: 'إعلانات', en: 'Announcements' },
    attachments: { ar: 'مرفقات', en: 'Attachments' },
  };

  return (
    <div ref={pageRef} className={styles.page}>
      <div className={styles.breadcrumbs}>
        <span>{lang === 'ar' ? 'الكورسات' : 'Courses'}</span>
        <ChevronLeft fontSize="small" />
        <span>{course ? (lang === 'ar' ? course.title_ar : course.title_en) : ''}</span>
        <ChevronLeft fontSize="small" />
        <strong>{title}</strong>
      </div>
      <button className={styles.sidebarToggle} onClick={() => setSidebarOpen(!sidebarOpen)}>
        <Menu fontSize="small" />
      </button>

      <div className={styles.layout}>
        <aside className={`${styles.sidebar} ${sidebarOpen ? styles.sidebarVisible : ''}`}>
          <section className={styles.progressCard}>
            <div className={styles.cardTitle}><BarChart fontSize="small" /><strong>{lang === 'ar' ? 'تقدم الكورس' : 'Course progress'}</strong></div>
            <b>{progress}%</b>
            <span>{lang === 'ar' ? 'اكتمال الكورس' : 'Course complete'}</span>
            <div className={styles.progressTrack}><i style={{ width: `${progress}%` }} /></div>
            <small>{completedLessons.length} {lang === 'ar' ? `من ${flatLessons.length} درس مكتمل` : `of ${flatLessons.length} lessons completed`}</small>
          </section>

          <section className={styles.curriculumCard}>
            <div className={styles.cardTitle}><VideoLibrary fontSize="small" /><strong>{lang === 'ar' ? 'محتوى الكورس' : 'Course content'}</strong></div>
            <div className={styles.curriculum}>
              {sections.map((section) => (
                <div key={section.id} className={styles.sectionGroup}>
                  <h4>{lang === 'ar' ? section.title_ar : section.title_en}</h4>
                  {section.lessons.map((lesson, index) => {
                    const isActive = lesson.id === activeLesson?.id;
                    const isDone = completedLessons.includes(lesson.id);
                    return (
                      <button key={lesson.id} onClick={() => selectLesson(lesson)} className={isActive ? styles.activeLesson : ''}>
                        <span>{isDone ? <CheckCircle fontSize="small" /> : isActive ? <PlayArrow fontSize="small" /> : <Lock fontSize="small" />}</span>
                        <strong>{lang === 'ar' ? lesson.title_ar : lesson.title_en}</strong>
                        <small>{lesson.video_duration ? `${Math.round(lesson.video_duration / 60)}:00` : `0${index + 1}`}</small>
                      </button>
                    );
                  })}
                </div>
              ))}
            </div>
          </section>
        </aside>

        <main className={styles.main}>
          {activeLesson ? (
            <>
              <section className={styles.mediaStage} ref={mediaStageRef}>
                <header className={styles.lessonHeader}>
                  <div className={styles.stageHeading}>
                    <span>{sectionTitle}</span>
                    <h1>{title}</h1>
                    <div>
                      <span><CheckCircle fontSize="small" />{completedLessons.includes(activeLesson.id) ? (lang === 'ar' ? 'مكتمل' : 'Completed') : (lang === 'ar' ? 'ضع علامة مكتمل' : 'Mark completed')}</span>
                      <span><Schedule fontSize="small" />{activeLesson.video_duration ? `${Math.round(activeLesson.video_duration / 60)} ${lang === 'ar' ? 'دقيقة' : 'min'}` : ''}</span>
                    </div>
                  </div>
                  <div className={styles.stageButtons}>
                    <button onClick={handleToggleBookmark} aria-label="Bookmark">
                      {isBookmarked ? <Bookmark fontSize="small" /> : <BookmarkBorder fontSize="small" />}
                    </button>
                    <button onClick={() => setShowSpeedMenu(!showSpeedMenu)} aria-label="Speed">
                      <Speed fontSize="small" />
                    </button>
                    <button onClick={handleToggleFullscreen} aria-label="Fullscreen">
                      {isFullscreen ? <FullscreenExit fontSize="small" /> : <Fullscreen fontSize="small" />}
                    </button>
                  </div>
                  {showSpeedMenu && (
                    <div className={styles.speedMenu}>
                      {SPEED_OPTIONS.map((s) => (
                        <button key={s} className={playbackSpeed === s ? styles.speedActive : ''} onClick={() => { setPlaybackSpeed(s); setShowSpeedMenu(false); }}>
                          {s}x
                        </button>
                      ))}
                    </div>
                  )}
                </header>
                <div className={styles.mediaContent}>
                  {activeLesson.type === 'video' && activeLesson.video_url && (
                    <VideoPlayer videoUrl={activeLesson.video_url} title={title} lessonId={activeLesson.id} startAt={lastPositions[activeLesson.id] || 0} onProgress={handleVideoProgress} onComplete={handleVideoComplete} playbackSpeed={playbackSpeed} />
                  )}
                  {activeLesson.type === 'article' && (
                    <div className={styles.articleCard}><h2>{title}</h2><div dangerouslySetInnerHTML={{ __html: sanitizeHtml(lang === 'ar' ? activeLesson.article_content_ar : activeLesson.article_content_en) }} /></div>
                  )}
                  {activeLesson.type === 'quiz' && (
                    <div className={styles.fallback}>
                      <AssignmentTurnedIn fontSize="large" />
                      <h2>{title}</h2>
                      {quizzesByLesson[activeLesson.id] && <Link href={`/quiz/${quizzesByLesson[activeLesson.id]}?enrollment=${enrollmentId}&courseId=${courseId}`}>{lang === 'ar' ? 'فتح الامتحان' : 'Open exam'}</Link>}
                    </div>
                  )}
                  {!['video', 'article', 'quiz'].includes(activeLesson.type) && (
                    <div className={styles.fallback}>
                      <Description fontSize="large" />
                      <h2>{title}</h2>
                      {activeLesson.file_url && <a href={activeLesson.file_url} target="_blank" rel="noreferrer">{lang === 'ar' ? 'تحميل الملف' : 'Download file'}</a>}
                    </div>
                  )}
                </div>
              </section>

              <div className={styles.infoGrid}>
                <section className={styles.infoCard}>
                  <div className={styles.tabs}>
                    {(['lectures', 'more', 'qa', 'quizzes', 'rating'] as const).map((tab) => (
                      <button key={tab} onClick={() => setActiveTab(tab)} className={activeTab === tab ? styles.activeTab : ''}>
                        {lang === 'ar' ? tabLabels[tab].ar : tabLabels[tab].en}
                      </button>
                    ))}
                  </div>
                  <div className={styles.tabPanel}>
                    {activeTab === 'lectures' && (
                      <div className={styles.lecturesTab}>
                        {tabLoading && <p>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</p>}
                        <div dangerouslySetInnerHTML={{ __html: sanitizeHtml((lang === 'ar' ? activeLesson.description_ar || activeLesson.article_content_ar : activeLesson.description_en || activeLesson.article_content_en) || (course ? (lang === 'ar' ? course.description_ar : course.description_en) : '') || (lang === 'ar' ? 'محتوى الدرس' : 'Lesson content')) }} />
                      </div>
                    )}

                    {activeTab === 'more' && (
                      <div>
                        <div className={styles.moreSubTabs}>
                          {(['notes', 'bookmarks', 'announcements', 'attachments'] as const).map((sub) => (
                            <button key={sub} onClick={() => setMoreSubTab(sub)} className={moreSubTab === sub ? styles.moreSubTabActive : ''}>
                              {lang === 'ar' ? moreSubTabLabels[sub].ar : moreSubTabLabels[sub].en}
                            </button>
                          ))}
                        </div>

                        {moreSubTab === 'notes' && (
                          <div className={styles.notesSection}>
                            <div className={styles.noteForm}>
                              <textarea className={styles.noteInput} value={newNote} onChange={(e) => setNewNote(e.target.value)} placeholder={lang === 'ar' ? 'اكتب ملاحظة...' : 'Write a note...'} rows={3} />
                              <div className={styles.noteFormActions}>
                                <input type="number" className={styles.timestampInput} value={noteTimestamp || ''} onChange={(e) => setNoteTimestamp(Number(e.target.value))} placeholder="0:00" min={0} />
                                <AppButton size="small" onClick={handleAddNote} startIcon={<Add fontSize="small" />}>
                                  {lang === 'ar' ? 'إضافة' : 'Add'}
                                </AppButton>
                              </div>
                            </div>
                            <div className={styles.notesList}>
                              {notes.length === 0 ? (
                                <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد ملاحظات بعد' : 'No notes yet'}</p>
                              ) : notes.map((note) => (
                                <div key={note.id} className={styles.noteItem}>
                                  <div className={styles.noteContent}>
                                    {note.timestamp > 0 && <span className={styles.noteTimestamp}>{formatTimestamp(note.timestamp)}</span>}
                                    <p>{note.content}</p>
                                  </div>
                                  <button className={styles.noteDelete} onClick={() => handleDeleteNote(note.id)} aria-label="Delete note">
                                    <Delete fontSize="small" />
                                  </button>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}

                        {moreSubTab === 'bookmarks' && (
                          <div className={styles.bookmarksList}>
                            {bookmarks.length === 0 ? (
                              <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد إشارات مرجعية' : 'No bookmarks yet'}</p>
                            ) : bookmarks.map((bm) => (
                              <button key={bm.id} className={styles.bookmarkItem} onClick={() => {
                                const lesson = flatLessons.find(({ lesson }) => lesson.id === bm.lesson_id)?.lesson;
                                if (lesson) selectLesson(lesson);
                              }}>
                                <Bookmark fontSize="small" />
                                <span>{lang === 'ar' ? bm.lesson_title_ar || bm.lesson_title_en : bm.lesson_title_en || bm.lesson_title_ar}</span>
                              </button>
                            ))}
                          </div>
                        )}

                        {moreSubTab === 'announcements' && (
                          <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد إعلانات حاليًا' : 'No announcements yet'}</p>
                        )}

                        {moreSubTab === 'attachments' && (
                          <div className={styles.resourceList}>
                            {allAttachments.length ? allAttachments.map((file) => (
                              <a href={file.file_url} target="_blank" rel="noreferrer" className={styles.fileItem} key={file.id}>
                                <Description fontSize="small" />
                                <span><strong>{lang === 'ar' ? file.file_name_ar || file.file_name : file.file_name}</strong><small>{file.file_type || (lang === 'ar' ? 'ملف مرفق' : 'Attachment')}</small></span>
                                <Download fontSize="small" />
                              </a>
                            )) : <p>{lang === 'ar' ? 'لا توجد ملفات مرفقة' : 'No attachments'}</p>}
                          </div>
                        )}
                      </div>
                    )}

                    {activeTab === 'qa' && (
                      <div className={styles.questionsBlock}>
                        {tabLoading && <p>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</p>}
                        {questions.length ? questions.slice(0, 5).map((question) => (
                          <article className={styles.questionItem} key={question.id}>
                            <HelpIcon fontSize="small" />
                            <div>
                              <strong>{question.title}</strong>
                              <p>{question.content}</p>
                              <small>{question.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')} · {question.is_answered ? (lang === 'ar' ? 'تمت الإجابة' : 'Answered') : `${question.answers_count || 0} ${lang === 'ar' ? 'إجابة' : 'answers'}`}</small>
                            </div>
                          </article>
                        )) : <p>{lang === 'ar' ? 'لا توجد أسئلة على هذا الدرس حتى الآن.' : 'No questions for this lesson yet.'}</p>}
                        <Link className={styles.qaLink} href={`/qa?courseId=${courseId}&lessonId=${activeLesson.id}`}>
                          {lang === 'ar' ? 'عرض الأسئلة أو إضافة سؤال' : 'View questions or ask'}
                          <ArrowBack fontSize="small" />
                        </Link>
                      </div>
                    )}

                    {activeTab === 'quizzes' && (
                      <div className={styles.quizzesTab}>
                        {courseQuizzes.length === 0 ? (
                          <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد اختبارات لهذا الكورس' : 'No quizzes for this course'}</p>
                        ) : courseQuizzes.map(([lessonId, quizId]) => {
                          const lesson = flatLessons.find(({ lesson }) => lesson.id === lessonId)?.lesson;
                          return (
                            <Link key={quizId} href={`/quiz/${quizId}?enrollment=${enrollmentId}&courseId=${courseId}`} className={styles.quizItem}>
                              <AssignmentTurnedIn fontSize="small" />
                              <span>{lesson ? (lang === 'ar' ? lesson.title_ar : lesson.title_en) : (lang === 'ar' ? 'اختبار' : 'Quiz')}</span>
                            </Link>
                          );
                        })}
                      </div>
                    )}

                    {activeTab === 'rating' && (
                      <div className={styles.ratingTab}>
                        {course && course.rating_count !== undefined && course.rating_count > 0 && (
                          <div className={styles.ratingSummary}>
                            <div className={styles.ratingBigScore}>
                              <span className={styles.ratingBigNumber}>{course.rating ? Number(course.rating).toFixed(1) : '5.0'}</span>
                              <RatingStars value={course.rating || 5} size="md" />
                              <span className={styles.ratingTotalCount}>{course.rating_count} {lang === 'ar' ? 'تقييم' : 'ratings'}</span>
                            </div>
                            <div className={styles.ratingBars}>
                              {ratingBuckets.map((b) => (
                                <div key={b.stars} className={styles.ratingBarRow}>
                                  <span>{b.stars}</span>
                                  <Star fontSize="small" className={styles.starIcon} />
                                  <div className={styles.ratingBarTrack}><div className={styles.ratingBarFill} style={{ width: `${b.percentage}%` }} /></div>
                                  <span className={styles.ratingBarPct}>{b.percentage}%</span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                        <div className={styles.writeReview}>
                          <h4>{lang === 'ar' ? 'اكتب تقييمك' : 'Write your review'}</h4>
                          <div className={styles.userRatingRow}>
                            <RatingStars value={userRating} size="lg" interactive onChange={setUserRating} />
                          </div>
                          <textarea className={styles.reviewTextarea} value={reviewText} onChange={(e) => setReviewText(e.target.value)} placeholder={lang === 'ar' ? 'شاركنا رأيك...' : 'Share your opinion...'} rows={3} />
                          <AppButton size="small" disabled={userRating === 0}>{lang === 'ar' ? 'إرسال' : 'Submit'}</AppButton>
                        </div>
                      </div>
                    )}
                  </div>
                </section>

                <aside className={styles.instructorCard}>
                  <div className={styles.avatar}>{instructorAvatar ? <img src={instructorAvatar} alt={instructorName} /> : <Person fontSize="medium" />}</div>
                  <div><strong>{instructorName}</strong><small>{instructorHeadline}</small></div>
                  <Link href={`/courses/${courseId}`}>{lang === 'ar' ? 'عرض تفاصيل الكورس' : 'View course details'}</Link>
                </aside>
              </div>

              <nav className={styles.lessonNav}>
                <button onClick={() => selectLesson(previousLesson)} disabled={!previousLesson}>
                  <ArrowForward fontSize="small" />{lang === 'ar' ? 'السابق' : 'Previous'}
                </button>
                <button onClick={() => { if (activeLesson) void toggleCompleted(activeLesson.id); }} className={styles.markCompleteBtn}>
                  <CheckCircle fontSize="small" />
                  {completedLessons.includes(activeLesson?.id || '') ? (lang === 'ar' ? 'مكتمل' : 'Completed') : (lang === 'ar' ? 'اكتمال' : 'Complete')}
                </button>
                <button onClick={() => selectLesson(nextLesson)} disabled={!nextLesson}>
                  {lang === 'ar' ? 'التالي' : 'Next'}<ArrowBack fontSize="small" />
                </button>
              </nav>
            </>
          ) : (
            <div className={styles.empty}>{lang === 'ar' ? 'اختر درسًا للبدء' : 'Select a lesson to start'}</div>
          )}
        </main>
      </div>

      <ResponsiveDialog
        open={showCompletionDialog}
        onClose={() => setShowCompletionDialog(false)}
        title={lang === 'ar' ? 'تهانينا! 🎉' : 'Congratulations! 🎉'}
        actions={<AppButton onClick={() => setShowCompletionDialog(false)}>{lang === 'ar' ? 'رائع!' : 'Awesome!'}</AppButton>}
      >
        <div className={styles.completionContent}>
          <EmojiEvents fontSize="large" className={styles.trophyIcon} />
          <p>{lang === 'ar' ? 'لقد أكملت جميع دروس الكورس! استمر في التفوق.' : 'You have completed all lessons! Keep up the great work.'}</p>
        </div>
      </ResponsiveDialog>
    </div>
  );
}
