'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowBack, ArrowForward, Bookmark, BookmarkBorder, CheckCircle, ChevronLeft,
  AssignmentTurnedIn, Download, Description, VideoLibrary, Lock, Menu,
  Help as HelpIcon, PlayArrow, Star,
  Speed, Fullscreen, FullscreenExit, EmojiEvents, Delete, Add,
  Facebook, WhatsApp, Telegram,
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
  group_links?: GroupLinks | null;
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
  timestamp?: number;
  timestamp_seconds?: number;
  created_at: string;
}

interface BookmarkItem {
  id: string;
  lesson_id: string;
  lesson_title_ar?: string;
  lesson_title_en?: string;
  created_at: string;
}

interface QuizItem {
  id: string;
  section_id?: string | null;
  lesson_id?: string | null;
  title_ar: string;
  title_en?: string | null;
  description_ar?: string | null;
  description_en?: string | null;
  passing_score?: number | null;
  time_limit?: number | null;
  max_attempts?: number | null;
  available_from?: string | null;
  available_until?: string | null;
  total_questions?: number;
  quiz_questions?: { count: number }[];
}

interface GroupLinks {
  whatsapp?: string | null;
  telegram?: string | null;
  facebook?: string | null;
}

type PlayerTab = 'more' | 'attachments' | 'qa' | 'quizzes' | 'rating';
type MoreSubTab = 'notes' | 'bookmarks' | 'announcements';

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
  const [quizzes, setQuizzes] = useState<QuizItem[]>([]);
  const [groupLinks, setGroupLinks] = useState<GroupLinks>({});
  const [courseAttachments, setCourseAttachments] = useState<Attachment[]>([]);
  const [lessonAttachments, setLessonAttachments] = useState<Attachment[]>([]);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [instructor, setInstructor] = useState<Instructor | null>(null);
  const [tabLoading, setTabLoading] = useState(false);
  const [loading, setLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<PlayerTab>('more');
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
  const [submittingReview, setSubmittingReview] = useState(false);
  const [reviewMessage, setReviewMessage] = useState('');
  const [activeBottomSheet, setActiveBottomSheet] = useState<'notes' | 'bookmarks' | 'announcements' | 'attachments' | null>(null);
  const [mounted, setMounted] = useState(false);
  const mediaStageRef = useRef<HTMLDivElement>(null);
  const progressRef = useRef({ position: 0, duration: 0, watchTime: 0 });
  const watchTimesRef = useRef<Record<string, number>>({});
  const userId = user?.id;

  const SPEED_OPTIONS = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

  useEffect(() => {
    setMounted(true);
  }, []);

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
          .select('instructor_id, title_ar, title_en, description_ar, description_en, rating, rating_count, group_links, profiles!courses_instructor_id_fkey(id,name,avatar_url)')
          .eq('id', courseId).maybeSingle();
        if (courseData) {
          const { data: reviewsData } = await supabase
            .from('course_reviews')
            .select('rating')
            .eq('course_id', courseId);

          const ratingDist: Record<string, number> = { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 };
          if (reviewsData) {
            reviewsData.forEach((review) => {
              const rating = String(review.rating);
              if (ratingDist[rating] !== undefined) {
                ratingDist[rating] += 1;
              }
            });
          }

          const { data: userReviewData } = await supabase
            .from('course_reviews')
            .select('rating, review')
            .eq('course_id', courseId)
            .eq('user_id', currentUserId)
            .maybeSingle();
          if (userReviewData) {
            setUserRating(Number(userReviewData.rating || 0));
            setReviewText(userReviewData.review || '');
          }

          setCourse({ ...courseData, rating_distribution: ratingDist } as unknown as CourseSummary);
          const { data: paidEnrollmentData } = await supabase
            .from('enrollments')
            .select('id, parent_enrollments!inner(payment_status)')
            .eq('id', enrollData.id)
            .eq('course_id', courseId)
            .in('status', ['active', 'completed'])
            .eq('parent_enrollments.payment_status', 'paid')
            .maybeSingle();
          setGroupLinks(paidEnrollmentData ? (((courseData as unknown as CourseSummary).group_links || {}) as GroupLinks) : {});
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

        const { data: progressData } = await supabase.from('lesson_progress')
          .select('lesson_id, is_completed, last_position, watch_time')
          .eq('enrollment_id', enrollData.id);
        const positions: Record<string, number> = {};
        const times: Record<string, number> = {};
        (progressData || []).forEach((p) => {
          positions[p.lesson_id as string] = Number(p.last_position || 0);
          times[p.lesson_id as string] = Number(p.watch_time || 0);
        });
        setLastPositions(positions);
        watchTimesRef.current = times;
        setCompletedLessons((progressData || []).filter((p) => p.is_completed).map((p) => p.lesson_id as string));

        const requestedLessonId = new URLSearchParams(window.location.search).get('lesson') || new URLSearchParams(window.location.search).get('lessonId');
        const flatLoadedLessons = fullSections.flatMap((section) => section.lessons);
        const requestedLesson = requestedLessonId ? flatLoadedLessons.find((lesson) => lesson.id === requestedLessonId) : null;
        const completedLessonSet = new Set((progressData || []).filter((p) => p.is_completed).map((p) => p.lesson_id as string));
        const firstIncompleteLesson = flatLoadedLessons.find((lesson) => !completedLessonSet.has(lesson.id));
        setActiveLesson(requestedLesson || firstIncompleteLesson || flatLoadedLessons[0] || null);

        const { data: quizData } = await supabase.from('quizzes').select('*, quiz_questions(count)')
          .eq('course_id', courseId).eq('is_published', true).order('created_at');
        setQuizzes(((quizData || []) as QuizItem[]).map((quiz) => ({
          ...quiz,
          total_questions: quiz.quiz_questions?.[0]?.count ?? quiz.total_questions ?? 0,
        })));

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
    if (!activeLesson || !courseId || !userId) return;
    let cancelled = false;
    const timer = window.setTimeout(() => setTabLoading(true), 0);
    Promise.all([
      supabase.from('lesson_attachments').select('*').eq('lesson_id', activeLesson.id).order('sort_order'),
      supabase.from('qa_questions').select('id,title,content,is_answered,answers_count,profiles(name)')
        .eq('course_id', courseId).eq('lesson_id', activeLesson.id).eq('is_visible', true)
        .order('created_at', { ascending: false }),
      supabase.from('notes').select('*')
        .eq('user_id', userId).eq('lesson_id', activeLesson.id).order('timestamp_seconds', { ascending: true }),
    ]).then(([filesResult, questionsResult, notesResult]) => {
      if (cancelled) return;
      setLessonAttachments((filesResult.data || []) as Attachment[]);
      setQuestions((questionsResult.data as unknown as Question[]) || []);
      setNotes((notesResult.data || []) as Note[]);
      setTabLoading(false);
    });
    return () => { cancelled = true; window.clearTimeout(timer); };
  }, [activeLesson, courseId, userId]);

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
      content: newNote.trim(), timestamp_seconds: noteTimestamp,
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

  const refreshRatings = async () => {
    if (!courseId) return;
    const { data: reviewsData } = await supabase
      .from('course_reviews')
      .select('rating')
      .eq('course_id', courseId);
    const ratingDist: Record<string, number> = { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 };
    let totalScore = 0;
    (reviewsData || []).forEach((review) => {
      const value = Number(review.rating || 0);
      if (value >= 1 && value <= 5) {
        ratingDist[String(value)] += 1;
        totalScore += value;
      }
    });
    const count = reviewsData?.length || 0;
    setCourse((previous) => previous ? {
      ...previous,
      rating: count ? totalScore / count : previous.rating,
      rating_count: count,
      rating_distribution: ratingDist,
    } : previous);
  };

  const handleSubmitReview = async () => {
    if (!userId || !courseId || userRating <= 0 || submittingReview) return;
    setSubmittingReview(true);
    setReviewMessage('');
    try {
      const payload = {
        user_id: userId,
        course_id: String(courseId),
        rating: userRating,
        review: reviewText.trim() || null,
      };
      const { data: existingReview } = await supabase
        .from('course_reviews')
        .select('id')
        .eq('user_id', userId)
        .eq('course_id', courseId)
        .maybeSingle();

      const result = existingReview?.id
        ? await supabase.from('course_reviews').update(payload).eq('id', existingReview.id)
        : await supabase.from('course_reviews').insert(payload);
      if (result.error) throw result.error;

      await refreshRatings();
      setReviewMessage(lang === 'ar' ? 'تم حفظ تقييمك' : 'Your rating was saved');
    } catch (error) {
      console.error('Failed to submit review:', error);
      setReviewMessage(lang === 'ar' ? 'تعذر حفظ التقييم، حاول مرة أخرى' : 'Could not save your rating');
    } finally {
      setSubmittingReview(false);
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
  const instructorName = instructor?.display_name || course?.profiles?.name || (lang === 'ar' ? 'مدرس الكورس' : 'Course instructor');
  const instructorHeadline = lang === 'ar' ? instructor?.headline_ar || 'مدرس الكيمياء' : instructor?.headline_en || 'Chemistry teacher';
  const quizzesByLesson = Object.fromEntries(quizzes.filter((quiz) => quiz.lesson_id).map((quiz) => [quiz.lesson_id as string, quiz.id]));
  const sectionQuizzes = quizzes.filter((quiz) => quiz.section_id && !quiz.lesson_id);
  const lessonQuizzes = quizzes.filter((quiz) => quiz.lesson_id);
  const generalQuizzes = quizzes.filter((quiz) => !quiz.section_id && !quiz.lesson_id);
  const hasGroupLinks = Boolean(groupLinks.whatsapp || groupLinks.telegram || groupLinks.facebook);
  const selectLesson = (lesson: Lesson | null) => {
    if (!lesson) return;
    setActiveLesson(lesson);
    window.history.replaceState(null, '', `/learn/${courseId}?lesson=${lesson.id}`);
    if (window.innerWidth < 900) setSidebarOpen(false);
  };

  const handleCompleteAndNext = async () => {
    if (!activeLesson) return;
    if (!completedLessons.includes(activeLesson.id)) {
      await toggleCompleted(activeLesson.id);
    }
    if (nextLesson) {
      selectLesson(nextLesson);
    }
  };

  const getQuizTitle = (quiz: QuizItem) => (lang === 'ar' ? quiz.title_ar : quiz.title_en || quiz.title_ar);
  const getQuizMeta = (quiz: QuizItem) => {
    const questionCount = quiz.total_questions ?? quiz.quiz_questions?.[0]?.count ?? 0;
    const time = quiz.time_limit ? `${quiz.time_limit} ${lang === 'ar' ? 'دقيقة' : 'min'}` : (lang === 'ar' ? 'بدون حد' : 'No limit');
    return `${questionCount} ${lang === 'ar' ? 'سؤال' : 'questions'} • ${time} • ${lang === 'ar' ? 'النجاح' : 'Pass'} ${quiz.passing_score ?? 70}%`;
  };

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
    more: { ar: 'المزيد', en: 'More' },
    attachments: { ar: 'المرفقات', en: 'Attachments' },
    qa: { ar: 'الأسئلة', en: 'Questions' },
    quizzes: { ar: 'الاختبارات', en: 'Quizzes' },
    rating: { ar: 'التقييم', en: 'Rating' },
  };

  const getNoteTimestamp = (note: Note) => note.timestamp_seconds ?? note.timestamp ?? 0;

  const moreSubTabLabels: Record<MoreSubTab, { ar: string; en: string }> = {
    notes: { ar: 'ملاحظات', en: 'Notes' },
    bookmarks: { ar: 'إشارات مرجعية', en: 'Bookmarks' },
    announcements: { ar: 'إعلانات', en: 'Announcements' },
  };

  const sectionsWithQuizzes = sections.map((sec) => {
    const secQuizzes = sectionQuizzes.filter((q) => q.section_id === sec.id);
    return { section: sec, quizzes: secQuizzes };
  }).filter((item) => item.quizzes.length > 0);

  const flatLessonsWithQuizzes = flatLessons.map(({ lesson, section }) => {
    const lesQuizzes = lessonQuizzes.filter((q) => q.lesson_id === lesson.id);
    return { lesson, section, quizzes: lesQuizzes };
  }).filter((item) => item.quizzes.length > 0);

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

          {activeLesson && (
            <div className={styles.sidebarNav}>
              <button
                onClick={() => selectLesson(previousLesson)}
                disabled={!previousLesson}
                className={styles.sidebarNavBtn}
                aria-label={lang === 'ar' ? 'السابق' : 'Previous'}
              >
                {lang === 'ar' ? <ArrowForward fontSize="small" /> : <ArrowBack fontSize="small" />}
                <span>{lang === 'ar' ? 'السابق' : 'Previous'}</span>
              </button>

              {!nextLesson ? (
                <button
                  onClick={() => { if (activeLesson) void toggleCompleted(activeLesson.id); }}
                  className={`${styles.sidebarNavBtn} ${styles.sidebarNavComplete} ${completedLessons.includes(activeLesson.id) ? styles.sidebarNavCompleteDone : ''}`}
                  aria-label={completedLessons.includes(activeLesson.id) ? (lang === 'ar' ? 'مكتمل ✓' : 'Completed ✓') : (lang === 'ar' ? 'إكمال' : 'Complete')}
                >
                  <CheckCircle fontSize="small" />
                  <span>{completedLessons.includes(activeLesson.id) ? (lang === 'ar' ? 'مكتمل' : 'Completed') : (lang === 'ar' ? 'إكمال' : 'Complete')}</span>
                </button>
              ) : (
                <button
                  onClick={handleCompleteAndNext}
                  className={`${styles.sidebarNavBtn} ${styles.sidebarNavNext}`}
                  aria-label={lang === 'ar' ? 'التالي' : 'Next'}
                >
                  <span>{lang === 'ar' ? 'التالي' : 'Next'}</span>
                  {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
                </button>
              )}
            </div>
          )}
        </aside>

        <main className={styles.main}>
          {activeLesson ? (
            <section className={styles.mediaStage} ref={mediaStageRef}>
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
          ) : (
            <section className={styles.mediaStage}>
              <div className={styles.emptyStagePlaceholder}>
                <VideoLibrary fontSize="large" className={styles.placeholderIcon} />
                <h2>{course ? (lang === 'ar' ? course.title_ar : course.title_en) : (lang === 'ar' ? 'محتوى الكورس' : 'Course content')}</h2>
                <p>{lang === 'ar' ? 'اختر درساً من القائمة للبدء في المشاهدة والتعلم.' : 'Select a lesson from the sidebar to start learning.'}</p>
              </div>
            </section>
          )}


          {activeLesson && (
            <section className={styles.lessonMetaCard}>
              <button className={styles.bookmarkButton} onClick={handleToggleBookmark} aria-label="Bookmark">
                {isBookmarked ? <Bookmark fontSize="medium" /> : <BookmarkBorder fontSize="medium" />}
              </button>
              <div className={styles.lessonMetaText}>
                <span>{sectionTitle ? `${sectionTitle} • ${lang === 'ar' ? 'المحاضرة' : 'Lecture'} ${Math.max(activeIndex + 1, 1)}` : `${lang === 'ar' ? 'المحاضرة' : 'Lecture'} ${Math.max(activeIndex + 1, 1)}`}</span>
                <h1>{title}</h1>
                <small>{instructorName} • {instructorHeadline}</small>
              </div>
            </section>
          )}

          {hasGroupLinks && (
            <section className={styles.shareRow} aria-label={lang === 'ar' ? 'روابط مجموعات الكورس' : 'Course groups'}>
              {groupLinks.whatsapp && (
                <a className={styles.whatsappButton} href={groupLinks.whatsapp} target="_blank" rel="noreferrer">
                  <WhatsApp fontSize="small" />
                  WhatsApp
                </a>
              )}
              {groupLinks.telegram && (
                <a className={styles.telegramButton} href={groupLinks.telegram} target="_blank" rel="noreferrer">
                  <Telegram fontSize="small" />
                  Telegram
                </a>
              )}
              {groupLinks.facebook && (
                <a className={styles.facebookButton} href={groupLinks.facebook} target="_blank" rel="noreferrer">
                  <Facebook fontSize="small" />
                  Facebook
                </a>
              )}
            </section>
          )}

          <div className={styles.infoGrid}>
            <section className={styles.infoCard}>
              <div className={styles.tabs}>
                {(['more', 'qa', 'quizzes', 'rating'] as const).map((tab) => (
                  <button key={tab} onClick={() => setActiveTab(tab)} className={activeTab === tab ? styles.activeTab : ''}>
                    {lang === 'ar' ? tabLabels[tab].ar : tabLabels[tab].en}
                  </button>
                ))}
              </div>
              <div className={styles.tabPanel}>

                {/* ── MORE TAB ── */}
                {activeTab === 'more' && (
                  <div className={styles.moreList}>

                    {/* Notes row */}
                    <button className={styles.moreRow} onClick={() => setActiveBottomSheet('notes')}>
                      <span className={styles.moreRowChevron} />
                      <span className={styles.moreRowLabel}>{lang === 'ar' ? 'الملاحظات' : 'Notes'}</span>
                      <span className={styles.moreRowIcon} style={{ background: 'color-mix(in srgb,var(--primary) 13%,transparent)', color: 'var(--primary)' }}>
                        <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M3 18h12v-2H3v2zm0-5h12v-2H3v2zm0-7v2h12V6H3zm14 9.34V7h-2v11.34l-1.17-1.17-1.41 1.41L16 21.17l3.59-3.59-1.42-1.41L17 17.34z"/></svg>
                      </span>
                    </button>

                    {/* Bookmarks row */}
                    <button className={styles.moreRow} onClick={() => setActiveBottomSheet('bookmarks')}>
                      <span className={styles.moreRowChevron} />
                      <span className={styles.moreRowLabel}>{lang === 'ar' ? 'الإشارات المرجعية' : 'Bookmarks'}</span>
                      <span className={styles.moreRowIcon} style={{ background: 'color-mix(in srgb,#f59e0b 13%,transparent)', color: '#f59e0b' }}>
                        <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M17 3H7c-1.1 0-2 .9-2 2v16l7-3 7 3V5c0-1.1-.9-2-2-2z"/></svg>
                      </span>
                    </button>

                    {/* Announcements row */}
                    <button className={styles.moreRow} onClick={() => setActiveBottomSheet('announcements')}>
                      <span className={styles.moreRowChevron} />
                      <span className={styles.moreRowLabel}>{lang === 'ar' ? 'الإعلانات' : 'Announcements'}</span>
                      <span className={styles.moreRowIcon} style={{ background: 'color-mix(in srgb,#ef4444 13%,transparent)', color: '#ef4444' }}>
                        <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M18 11v2h4v-2h-4zm-2 6.61c.96.71 2.21 1.65 3.2 2.39.4-.53.8-1.07 1.2-1.6-.99-.74-2.24-1.68-3.2-2.4-.4.54-.8 1.08-1.2 1.61zM20.4 5.6c-.4-.53-.8-1.07-1.2-1.6-.99.74-2.24 1.68-3.2 2.4.4.53.8 1.07 1.2 1.6.96-.72 2.21-1.65 3.2-2.4zM4 9c-1.1 0-2 .9-2 2v2c0 1.1.9 2 2 2h1v4h2v-4h1l5 3V6L8 9H4zm11.5 3c0-1.33-.58-2.53-1.5-3.35v6.69c.92-.81 1.5-2.01 1.5-3.34z"/></svg>
                      </span>
                    </button>

                    {/* Attachments row */}
                    <button className={styles.moreRow} onClick={() => setActiveBottomSheet('attachments')}>
                      <span className={styles.moreRowChevron} />
                      <span className={styles.moreRowLabel}>{lang === 'ar' ? 'المرفقات' : 'Attachments'}</span>
                      <span className={styles.moreRowIcon} style={{ background: 'color-mix(in srgb,#10b981 13%,transparent)', color: '#10b981' }}>
                        <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M16.5 6v11.5c0 2.21-1.79 4-4 4s-4-1.79-4-4V5c0-1.38 1.12-2.5 2.5-2.5s2.5 1.12 2.5 2.5v10.5c0 .55-.45 1-1 1s-1-.45-1-1V6H10v9.5c0 1.38 1.12 2.5 2.5 2.5s2.5-1.12 2.5-2.5V5c0-2.21-1.79-4-4-4S7 2.79 7 5v12.5c0 3.04 2.46 5.5 5.5 5.5s5.5-2.46 5.5-5.5V6h-1.5z"/></svg>
                      </span>
                    </button>

                  </div>
                )}

                {/* ── Q&A TAB ── */}
                {activeTab === 'qa' && (
                  <div className={styles.questionsBlock}>
                    {tabLoading && <p className={styles.emptyNotes}>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</p>}
                    {!tabLoading && (
                      <>
                        {questions.length ? (
                          <div className={styles.questionsList}>
                            {questions.slice(0, 5).map((question) => (
                              <article className={styles.questionItem} key={question.id}>
                                <HelpIcon fontSize="small" />
                                <div>
                                  <strong>{question.title}</strong>
                                  <p>{question.content}</p>
                                  <small>{question.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')} · {question.is_answered ? (lang === 'ar' ? 'تمت الإجابة' : 'Answered') : `${question.answers_count || 0} ${lang === 'ar' ? 'إجابة' : 'answers'}`}</small>
                                </div>
                              </article>
                            ))}
                          </div>
                        ) : (
                          <div className={styles.emptyQuestionsState}>
                            <div className={styles.emptyQuestionsIcon}>
                              <HelpIcon fontSize="large" />
                            </div>
                            <h4>{lang === 'ar' ? 'لا توجد أسئلة بعد' : 'No questions yet'}</h4>
                            <p>{lang === 'ar' ? 'كن أول من يطرح سؤالاً لمناقشة المحاضرة مع زملائك والمعلم.' : 'Be the first to ask a question to discuss the lecture with others.'}</p>
                          </div>
                        )}
                        <Link className={styles.qaLink} href={`/qa?courseId=${courseId}${activeLesson ? `&lessonId=${activeLesson.id}` : ''}`}>
                          <span>{lang === 'ar' ? 'عرض الأسئلة أو إضافة سؤال' : 'View questions or ask'}</span>
                          {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
                        </Link>
                      </>
                    )}
                  </div>
                )}

                {activeTab === 'quizzes' && (
                  <div className={styles.quizzesTab}>
                    {quizzes.length === 0 ? (
                      <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد اختبارات لهذا الكورس' : 'No quizzes for this course'}</p>
                    ) : (
                      <>
                        {/* Section quizzes accordion */}
                        {sectionsWithQuizzes.length > 0 && (
                          <div className={styles.quizAccordionGroup}>
                            <div className={styles.quizAccordionHeader}>
                              <div className={styles.quizAccordionTitle}>
                                <strong>{lang === 'ar' ? 'اختبارات السيكشنات' : 'Section Quizzes'}</strong>
                                <small>{lang === 'ar' ? 'اختبارات مرتبطة بسيكشن كامل' : 'Quizzes tied to full sections'}</small>
                              </div>
                            </div>
                            <div className={styles.quizAccordionCards}>
                              {sectionsWithQuizzes.map(({ section, quizzes }) => {
                                const sectionTitle = lang === 'ar' ? section.title_ar : section.title_en || section.title_ar;
                                return (
                                  <details key={section.id} className={styles.quizCard}>
                                    <summary className={styles.quizCardHeader}>
                                      <span className={styles.quizCardChevron} />
                                      <div className={styles.quizCardMeta}>
                                        <strong>{sectionTitle}</strong>
                                        <small>{quizzes.length} {lang === 'ar' ? 'اختبار' : 'quizzes'}</small>
                                      </div>
                                    </summary>
                                    <div className={styles.quizCardContent}>
                                      {quizzes.map((quiz) => (
                                        <Link key={quiz.id} href={`/quiz/${quiz.id}?enrollment=${enrollmentId}&courseId=${courseId}&title=${encodeURIComponent(course ? (lang === 'ar' ? course.title_ar : course.title_en) : '')}`} className={styles.quizLinkRow}>
                                          <span>
                                            <strong>{getQuizTitle(quiz)}</strong>
                                            <small>{getQuizMeta(quiz)}</small>
                                          </span>
                                        </Link>
                                      ))}
                                    </div>
                                  </details>
                                );
                              })}
                            </div>
                          </div>
                        )}

                        {/* Lesson quizzes accordion */}
                        {flatLessonsWithQuizzes.length > 0 && (
                          <div className={styles.quizAccordionGroup}>
                            <div className={styles.quizAccordionHeader}>
                              <div className={styles.quizAccordionTitle}>
                                <strong>{lang === 'ar' ? 'اختبارات الدروس' : 'Lesson Quizzes'}</strong>
                                <small>{lang === 'ar' ? 'اختبارات مرتبطة بدرس محدد' : 'Quizzes tied to specific lessons'}</small>
                              </div>
                            </div>
                            <div className={styles.quizAccordionCards}>
                              {flatLessonsWithQuizzes.map(({ lesson, quizzes }) => {
                                const lessonTitle = lang === 'ar' ? lesson.title_ar : lesson.title_en || lesson.title_ar;
                                return (
                                  <details key={lesson.id} className={styles.quizCard}>
                                    <summary className={styles.quizCardHeader}>
                                      <span className={styles.quizCardChevron} />
                                      <div className={styles.quizCardMeta}>
                                        <strong>{lessonTitle}</strong>
                                        <small>{quizzes.length} {lang === 'ar' ? 'اختبار' : 'quizzes'}</small>
                                      </div>
                                    </summary>
                                    <div className={styles.quizCardContent}>
                                      {quizzes.map((quiz) => (
                                        <Link key={quiz.id} href={`/quiz/${quiz.id}?enrollment=${enrollmentId}&courseId=${courseId}&title=${encodeURIComponent(course ? (lang === 'ar' ? course.title_ar : course.title_en) : '')}${quiz.lesson_id ? `&lesson=${quiz.lesson_id}` : ''}`} className={styles.quizLinkRow}>
                                          <span>
                                            <strong>{getQuizTitle(quiz)}</strong>
                                            <small>{getQuizMeta(quiz)}</small>
                                          </span>
                                        </Link>
                                      ))}
                                    </div>
                                  </details>
                                );
                              })}
                            </div>
                          </div>
                        )}

                        {/* General quizzes accordion (Direct list of items) */}
                        {generalQuizzes.length > 0 && (
                          <div className={styles.quizAccordionGroup}>
                            <div className={styles.quizAccordionHeader}>
                              <div className={styles.quizAccordionTitle}>
                                <strong>{lang === 'ar' ? 'اختبار شامل' : 'Course Quizzes'}</strong>
                                <small>{lang === 'ar' ? 'اختبارات عامة للكورس' : 'General course quizzes'}</small>
                              </div>
                            </div>
                            <div className={styles.quizAccordionCards}>
                              {generalQuizzes.map((quiz) => (
                                <Link key={quiz.id} href={`/quiz/${quiz.id}?enrollment=${enrollmentId}&courseId=${courseId}&title=${encodeURIComponent(course ? (lang === 'ar' ? course.title_ar : course.title_en) : '')}`} className={styles.quizLinkRow} style={{ marginBottom: '8px', display: 'flex' }}>
                                  <span>
                                    <strong>{getQuizTitle(quiz)}</strong>
                                    <small>{getQuizMeta(quiz)}</small>
                                  </span>
                                </Link>
                              ))}
                            </div>
                          </div>
                        )}
                        <Link className={styles.qaLink} href="/exams">
                          <span>{lang === 'ar' ? 'عرض جميع الاختبارات' : 'View all quizzes'}</span>
                          {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
                        </Link>
                      </>
                    )}
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
                      <AppButton size="small" disabled={userRating === 0 || submittingReview} onClick={handleSubmitReview}>
                        {submittingReview ? (lang === 'ar' ? 'جاري الحفظ...' : 'Saving...') : (lang === 'ar' ? 'إرسال' : 'Submit')}
                      </AppButton>
                      {reviewMessage && <p className={styles.reviewMessage}>{reviewMessage}</p>}
                    </div>
                  </div>
                )}
              </div>
            </section>

          </div>
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

      {/* Custom Bottom Sheet */}
      {mounted && activeBottomSheet && createPortal(
        <>
          <div className={styles.bottomSheetBackdrop} onClick={() => setActiveBottomSheet(null)} />
          <div className={`${styles.bottomSheet} ${styles.bottomSheetOpen}`}>
            <div className={styles.bottomSheetHeader}>
              <div className={styles.bottomSheetHandle} />
              <button className={styles.bottomSheetClose} onClick={() => setActiveBottomSheet(null)}>×</button>
              <h3>
                {activeBottomSheet === 'notes' && (lang === 'ar' ? 'الملاحظات' : 'Notes')}
                {activeBottomSheet === 'bookmarks' && (lang === 'ar' ? 'الإشارات المرجعية' : 'Bookmarks')}
                {activeBottomSheet === 'announcements' && (lang === 'ar' ? 'الإعلانات' : 'Announcements')}
                {activeBottomSheet === 'attachments' && (lang === 'ar' ? 'المرفقات' : 'Attachments')}
              </h3>
            </div>
            <div className={styles.bottomSheetContent}>
              {activeBottomSheet === 'notes' && (
                <div className={styles.notesSection}>
                  {activeLesson && (
                    <div className={styles.noteForm}>
                      <textarea className={styles.noteInput} value={newNote} onChange={(e) => setNewNote(e.target.value)} placeholder={lang === 'ar' ? 'اكتب ملاحظة...' : 'Write a note...'} rows={3} />
                      <div className={styles.noteFormActions}>
                        <AppButton size="small" onClick={handleAddNote} startIcon={<Add fontSize="small" />}>
                          {lang === 'ar' ? 'إضافة' : 'Add'}
                        </AppButton>
                      </div>
                    </div>
                  )}
                  <div className={styles.notesList}>
                    {notes.length === 0 ? (
                      <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد ملاحظات بعد' : 'No notes yet'}</p>
                    ) : notes.map((note) => (
                      <div key={note.id} className={styles.noteItem}>
                        <div className={styles.noteContent}>
                          {getNoteTimestamp(note) > 0 && <span className={styles.noteTimestamp}>{formatTimestamp(getNoteTimestamp(note))}</span>}
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

              {activeBottomSheet === 'bookmarks' && (
                <div className={styles.bookmarksList}>
                  {bookmarks.length === 0 ? (
                    <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد إشارات مرجعية' : 'No bookmarks yet'}</p>
                  ) : bookmarks.map((bm) => (
                    <button key={bm.id} className={styles.bookmarkItem} onClick={() => {
                      const lesson = flatLessons.find(({ lesson }) => lesson.id === bm.lesson_id)?.lesson;
                      if (lesson) selectLesson(lesson);
                      setActiveBottomSheet(null);
                    }}>
                      <Bookmark fontSize="small" />
                      <span>{lang === 'ar' ? bm.lesson_title_ar || bm.lesson_title_en : bm.lesson_title_en || bm.lesson_title_ar}</span>
                    </button>
                  )) }
                </div>
              )}

              {activeBottomSheet === 'announcements' && (
                <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد إعلانات حاليًا' : 'No announcements yet'}</p>
              )}

              {activeBottomSheet === 'attachments' && (
                <div className={styles.resourceList}>
                  {allAttachments.length ? allAttachments.map((file) => (
                    <a href={file.file_url} target="_blank" rel="noreferrer" className={styles.fileItem} key={file.id}>
                      <Description fontSize="small" />
                      <span><strong>{lang === 'ar' ? file.file_name_ar || file.file_name : file.file_name}</strong><small>{file.file_type || (lang === 'ar' ? 'ملف مرفق' : 'Attachment')}</small></span>
                      <Download fontSize="small" />
                    </a>
                  )) : <p className={styles.emptyNotes}>{lang === 'ar' ? 'لا توجد ملفات مرفقة' : 'No attachments'}</p>}
                </div>
              )}
            </div>
          </div>
        </>
      , document.body)}
    </div>
  );
}
