'use client';

import { useEffect, useState, useMemo } from 'react';
import Link from 'next/link';
import { History, PlayCircle, MenuBook, OndemandVideo } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import { AppBackButton, ShimmerEffect, EmptyState } from '../../components/ui';
import { AppDateUtils } from '../../lib/formatters';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface LessonHistory {
  id: string;
  lesson_id: string;
  course_id: string;
  last_accessed_at: string;
  completed: boolean;
  lessons?: {
    id: string;
    title_ar?: string;
    title_en?: string;
    thumbnail_url?: string;
    duration_minutes?: number;
  };
  courses?: {
    id: string;
    title_ar?: string;
    title_en?: string;
  };
}

export default function HistoryPage() {
  const pageRef = usePageTransition();
  const { lang, user } = useApp();
  const [items, setItems] = useState<LessonHistory[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }

    async function fetchLessonHistory() {
      try {
        const { data, error } = await supabase
          .from('lesson_progress')
          .select(`
            id,
            lesson_id,
            course_id,
            last_accessed_at,
            completed,
            lessons (
              id,
              title_ar,
              title_en,
              thumbnail_url,
              duration_minutes
            ),
            courses (
              id,
              title_ar,
              title_en
            )
          `)
          .eq('user_id', user!.id)
          .order('last_accessed_at', { ascending: false })
          .limit(100);

        if (data && !error) {
          setItems(data as unknown as LessonHistory[]);
        }
      } catch (err) {
        console.error('Error fetching lesson history:', err);
        const { data } = await supabase
          .from('enrollments')
          .select('id, course_id, last_accessed_at, progress_percentage, status, courses(id, title_ar, title_en)')
          .eq('user_id', user!.id)
          .order('last_accessed_at', { ascending: false })
          .limit(50);

        if (data) {
          const mapped: LessonHistory[] = data
            .filter((e: Record<string, unknown>) => e.last_accessed_at)
            .map((e: Record<string, unknown>) => ({
              id: String(e.id),
              lesson_id: '',
              course_id: String(e.course_id),
              last_accessed_at: String(e.last_accessed_at),
              completed: e.progress_percentage === 100,
              courses: e.courses as LessonHistory['courses'],
            }));
          setItems(mapped);
        }
      } finally {
        setLoading(false);
      }
    }

    fetchLessonHistory();
  }, [user]);

  const grouped = useMemo(() => {
    const groups: Record<string, LessonHistory[]> = {};
    for (const item of items) {
      const group = AppDateUtils.getDateGroup(item.last_accessed_at, lang);
      if (!groups[group]) groups[group] = [];
      groups[group].push(item);
    }
    return groups;
  }, [items, lang]);

  if (loading) {
    return (
      <main className={styles.page}>
        <div className={styles.backRow}>
          <AppBackButton />
        </div>
        <FeaturePageHero
          icon={History}
          eyebrow="ACTIVITY"
          title={lang === 'ar' ? 'سجل التعلم' : 'Learning History'}
          subtitle={lang === 'ar' ? 'ارجع بسرعة لآخر الكورسات التي درستها وتابع تقدمك.' : 'Return to your recent learning activity.'}
        />
        <div className={styles.shimmerList}>
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className={styles.shimmerCard}>
              <ShimmerEffect width="56px" height="56px" borderRadius="md" />
              <div className={styles.shimmerBody}>
                <ShimmerEffect width="70%" height="14px" borderRadius="sm" />
                <ShimmerEffect width="50%" height="12px" borderRadius="sm" />
              </div>
            </div>
          ))}
        </div>
      </main>
    );
  }

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.backRow}>
        <AppBackButton />
      </div>

      <FeaturePageHero
        icon={History}
        eyebrow="ACTIVITY"
        title={lang === 'ar' ? 'سجل التعلم' : 'Learning History'}
        subtitle={lang === 'ar' ? 'ارجع بسرعة لآخر الدروس التي درستها وتابع تقدمك.' : 'Return to your recent lesson activity.'}
      />

      {items.length === 0 ? (
        <div className={styles.emptyWrap}>
          <EmptyState
            type="myLearning"
            title={lang === 'ar' ? 'لا يوجد نشاط تعليمي بعد' : 'No learning activity yet'}
            message={lang === 'ar' ? 'ابدأ بتصفح الكورسات وسيظهر نشاطك هنا' : 'Start browsing courses and your activity will appear here'}
          />
        </div>
      ) : (
        Object.entries(grouped).map(([dateGroup, groupItems]) => (
          <section key={dateGroup} className={styles.dateGroup}>
            <h3 className={styles.dateLabel}>{dateGroup}</h3>
            <div className={styles.lessonList}>
              {groupItems.map((item) => {
                const lesson = item.lessons;
                const course = item.courses;
                const lessonTitle = lesson
                  ? (lang === 'ar' ? lesson.title_ar : lesson.title_en || lesson.title_ar)
                  : null;
                const courseTitle = course
                  ? (lang === 'ar' ? course.title_ar : course.title_en || course.title_ar)
                  : (lang === 'ar' ? 'كورس' : 'Course');

                if (lessonTitle) {
                  return (
                    <Link
                      key={item.id}
                      href={`/learn/${item.course_id}`}
                      className={styles.lessonCard}
                    >
                      <div className={styles.lessonThumb}>
                        {lesson?.thumbnail_url ? (
                          <img
                            src={lesson.thumbnail_url}
                            alt=""
                            className={styles.lessonImg}
                            onError={(e) => { e.currentTarget.style.display = 'none'; e.currentTarget.nextElementSibling?.classList.remove(styles.hidden); }}
                          />
                        ) : (
                          <div className={styles.lessonPlaceholderIcon}>
                            <OndemandVideo fontSize="small" />
                          </div>
                        )}
                        {item.completed && (
                          <span className={styles.completedDot} />
                        )}
                      </div>
                      <div className={styles.lessonBody}>
                        <h4 className={styles.lessonTitle}>{lessonTitle}</h4>
                        <p className={styles.courseName}>{courseTitle}</p>
                        <span className={styles.timeAgo}>
                          {AppDateUtils.getRelativeTime(item.last_accessed_at, lang)}
                        </span>
                      </div>
                      <div className={styles.lessonAction}>
                        {item.completed ? (
                          <span className={styles.doneBadge}>
                            {lang === 'ar' ? 'مكتمل' : 'Done'}
                          </span>
                        ) : (
                          <PlayCircle className={styles.playIcon} />
                        )}
                      </div>
                    </Link>
                  );
                }

                return (
                  <Link
                    key={item.id}
                    href={`/learn/${item.course_id}`}
                    className={styles.lessonCard}
                  >
                    <div className={styles.lessonThumb}>
                      <div className={styles.lessonPlaceholderIcon}>
                        <MenuBook fontSize="small" />
                      </div>
                    </div>
                    <div className={styles.lessonBody}>
                      <h4 className={styles.lessonTitle}>{courseTitle}</h4>
                      <span className={styles.timeAgo}>
                        {AppDateUtils.getRelativeTime(item.last_accessed_at, lang)}
                      </span>
                    </div>
                    <div className={styles.lessonAction}>
                      <PlayCircle className={styles.playIcon} />
                    </div>
                  </Link>
                );
              })}
            </div>
          </section>
        ))
      )}
    </main>
  );
}
