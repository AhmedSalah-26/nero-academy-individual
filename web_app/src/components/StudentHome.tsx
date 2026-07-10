'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowBack,
  Notifications,
  MenuBook,
  ChevronLeft,
  AssignmentTurnedIn,
  Schedule,
  Favorite,
  History,
  Help as HelpIcon,
  Forum,
  PlayArrow,
  Search,
  AutoAwesome,
  EmojiEvents,
} from '@mui/icons-material';
import { useApp } from '../context/AppContext';
import { supabase } from '../lib/supabaseClient';
import styles from './StudentHome.module.css';

interface Enrollment {
  id: string;
  course_id: string;
  progress_percentage: number;
  completed_lessons: number;
  courses: {
    title_ar: string;
    title_en: string;
    subtitle_ar: string;
    subtitle_en: string;
    thumbnail_url: string;
    total_lessons: number;
  };
}

const actions = [
  { href: '/courses', labelAr: 'كل الكورسات', labelEn: 'All courses', icon: Search },
  { href: '/my-learning', labelAr: 'كورساتي', labelEn: 'My learning', icon: MenuBook },
  { href: '/forums', labelAr: 'المجتمع', labelEn: 'Community', icon: Forum },
  { href: '/exams', labelAr: 'الامتحانات', labelEn: 'Exams', icon: AssignmentTurnedIn },
  { href: '/qa', labelAr: 'الأسئلة', labelEn: 'Questions', icon: HelpIcon },
  { href: '/wishlist', labelAr: 'المفضلة', labelEn: 'Wishlist', icon: Favorite },
  { href: '/history', labelAr: 'سجل التعلم', labelEn: 'History', icon: History },
  { href: '/notifications', labelAr: 'التنبيهات', labelEn: 'Notifications', icon: Notifications },
];

const actionDescriptions = {
  '/courses': {
    ar: 'تصفح محتوى السنة الدراسية',
    en: 'Browse your school-year content',
  },
  '/my-learning': {
    ar: 'الكورسات المشترك بها',
    en: 'Your enrolled courses',
  },
  '/forums': {
    ar: 'ناقش واسأل زملاءك',
    en: 'Discuss with classmates',
  },
  '/exams': {
    ar: 'اختبر فهمك بسرعة',
    en: 'Test your understanding',
  },
  '/qa': {
    ar: 'اسأل في أي جزئية',
    en: 'Ask about any topic',
  },
  '/wishlist': {
    ar: 'الكورسات المحفوظة',
    en: 'Saved courses',
  },
  '/history': {
    ar: 'تابع آخر تقدمك',
    en: 'Track your latest progress',
  },
  '/notifications': {
    ar: 'آخر التحديثات المهمة',
    en: 'Important updates',
  },
} as const;

export function StudentHome() {
  const { lang, user, profile } = useApp();
  const [enrollments, setEnrollments] = useState<Enrollment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user?.id) return;
    let cancelled = false;

    supabase
      .from('enrollments')
      .select(`
        id,
        course_id,
        progress_percentage,
        completed_lessons,
        courses (
          title_ar,
          title_en,
          subtitle_ar,
          subtitle_en,
          thumbnail_url,
          total_lessons
        )
      `)
      .eq('user_id', user.id)
      .in('status', ['active', 'completed'])
      .order('updated_at', { ascending: false })
      .limit(4)
      .then(({ data }) => {
        if (!cancelled) {
          setEnrollments((data || []) as unknown as Enrollment[]);
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [user?.id]);

  const firstName = profile?.name?.split(' ')[0] || user?.email?.split('@')[0] || '';
  return (
    <main className={styles.page}>
      <section className={styles.welcome}>
        <div className={styles.welcomeCopy}>
          <span><AutoAwesome fontSize="small" />{lang === 'ar' ? 'جاهز نكمل؟' : 'Ready to continue?'}</span>
          <h1>{lang === 'ar' ? `أهلاً ${firstName}` : `Welcome, ${firstName}`}</h1>
          <p>{lang === 'ar' ? 'كل مذاكرتك ومتابعة تقدمك ومجتمعك في مكان واحد.' : 'Your learning, progress, and community in one place.'}</p>
          <div className={styles.welcomeActions}>
            <Link href="/my-learning"><PlayArrow fontSize="small" />{lang === 'ar' ? 'أكمل التعلم' : 'Continue learning'}</Link>
            <Link href="/courses">{lang === 'ar' ? 'استكشف الكورسات' : 'Explore courses'}<ArrowBack fontSize="small" /></Link>
          </div>
        </div>
        <div className={styles.welcomeVisual} aria-hidden="true">
          <div className={styles.teacherGlow} />
          <div className={styles.teacherImage}>
            <Image
              src="/dr_unexpected_final.png"
              alt=""
              fill
              sizes="(max-width: 900px) 260px, 360px"
              priority
            />
          </div>
        </div>
      </section>

      <section className={styles.quickSection}>
        <div className={styles.sectionTitle}>
          <div><span>{lang === 'ar' ? 'وصول سريع' : 'Quick access'}</span><h2>{lang === 'ar' ? 'كل أدواتك' : 'Your tools'}</h2></div>
        </div>
        <div className={styles.actionsGrid}>
          {actions.map(({ href, labelAr, labelEn, icon: Icon }) => {
            const description = actionDescriptions[href as keyof typeof actionDescriptions];

            return (
              <Link href={href} key={href} className={styles.actionCard}>
                <span><Icon fontSize="small" /></span>
                <strong>{lang === 'ar' ? labelAr : labelEn}</strong>
                <small>{lang === 'ar' ? description.ar : description.en}</small>
                <ChevronLeft fontSize="small" />
              </Link>
            );
          })}
        </div>
      </section>

      <section className={styles.learningSection}>
        <div className={styles.sectionTitle}>
          <div><span>{lang === 'ar' ? 'ارجع من حيث توقفت' : 'Pick up where you left off'}</span><h2>{lang === 'ar' ? 'تابع التعلم' : 'Continue learning'}</h2></div>
          <Link href="/my-learning">{lang === 'ar' ? 'عرض الكل' : 'View all'}<ArrowBack fontSize="small" /></Link>
        </div>

        {loading ? (
          <div className={styles.empty}>{lang === 'ar' ? 'جاري تجهيز كورساتك...' : 'Preparing your courses...'}</div>
        ) : enrollments.length ? (
          <div className={styles.courseGrid}>
            {enrollments.map((enrollment) => {
              const course = enrollment.courses;
              const title = lang === 'ar' ? course.title_ar : course.title_en;
              return (
                <Link href={`/learn/${enrollment.course_id}`} className={styles.courseCard} key={enrollment.id}>
                  <div className={styles.courseImage}>
                    <MenuBook fontSize="medium" />
                    {course.thumbnail_url && <img src={course.thumbnail_url} alt={title} onError={(event) => { event.currentTarget.style.display = 'none'; }} />}
                    <div className={styles.playOverlay}><PlayArrow fontSize="small" /></div>
                  </div>
                  <div className={styles.courseBody}>
                    <h3>{title}</h3>
                    <div className={styles.courseMeta}><span><Schedule fontSize="small" />{enrollment.completed_lessons}/{course.total_lessons || 0}</span><strong>{Math.round(enrollment.progress_percentage || 0)}%</strong></div>
                    <div className={styles.track}><i style={{ width: `${enrollment.progress_percentage || 0}%` }} /></div>
                  </div>
                </Link>
              );
            })}
          </div>
        ) : (
          <div className={styles.empty}>
            <EmojiEvents fontSize="large" />
            <strong>{lang === 'ar' ? 'ابدأ أول كورس وخلّي تقدمك يظهر هنا' : 'Start your first course to see progress here'}</strong>
            <Link href="/courses">{lang === 'ar' ? 'تصفح الكورسات' : 'Browse courses'}</Link>
          </div>
        )}
      </section>
    </main>
  );
}
