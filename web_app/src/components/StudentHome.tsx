'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowLeft,
  Bell,
  BookOpen,
  ChevronLeft,
  ClipboardCheck,
  Clock3,
  Heart,
  History,
  MessageCircleQuestion,
  MessagesSquare,
  Play,
  Search,
  Sparkles,
  Trophy,
} from 'lucide-react';
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
  { href: '/my-learning', labelAr: 'كورساتي', labelEn: 'My learning', icon: BookOpen },
  { href: '/forums', labelAr: 'المجتمع', labelEn: 'Community', icon: MessagesSquare },
  { href: '/exams', labelAr: 'الامتحانات', labelEn: 'Exams', icon: ClipboardCheck },
  { href: '/qa', labelAr: 'الأسئلة', labelEn: 'Questions', icon: MessageCircleQuestion },
  { href: '/wishlist', labelAr: 'المفضلة', labelEn: 'Wishlist', icon: Heart },
  { href: '/history', labelAr: 'سجل التعلم', labelEn: 'History', icon: History },
  { href: '/notifications', labelAr: 'التنبيهات', labelEn: 'Notifications', icon: Bell },
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
          <span><Sparkles size={16} />{lang === 'ar' ? 'جاهز نكمل؟' : 'Ready to continue?'}</span>
          <h1>{lang === 'ar' ? `أهلاً ${firstName}` : `Welcome, ${firstName}`}</h1>
          <p>{lang === 'ar' ? 'كل مذاكرتك ومتابعة تقدمك ومجتمعك في مكان واحد.' : 'Your learning, progress, and community in one place.'}</p>
          <div className={styles.welcomeActions}>
            <Link href="/my-learning"><Play size={16} fill="currentColor" />{lang === 'ar' ? 'أكمل التعلم' : 'Continue learning'}</Link>
            <Link href="/courses">{lang === 'ar' ? 'استكشف الكورسات' : 'Explore courses'}<ArrowLeft size={16} /></Link>
          </div>
        </div>
        <div className={styles.welcomeVisual} aria-hidden="true">
          <div className={styles.teacherGlow} />
          <div className={styles.teacherImage}>
            <Image
              src="/home_hero_cutout.png"
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
                <span><Icon size={20} /></span>
                <strong>{lang === 'ar' ? labelAr : labelEn}</strong>
                <small>{lang === 'ar' ? description.ar : description.en}</small>
                <ChevronLeft size={15} />
              </Link>
            );
          })}
        </div>
      </section>

      <section className={styles.learningSection}>
        <div className={styles.sectionTitle}>
          <div><span>{lang === 'ar' ? 'ارجع من حيث توقفت' : 'Pick up where you left off'}</span><h2>{lang === 'ar' ? 'تابع التعلم' : 'Continue learning'}</h2></div>
          <Link href="/my-learning">{lang === 'ar' ? 'عرض الكل' : 'View all'}<ArrowLeft size={15} /></Link>
        </div>

        {loading ? (
          <div className={styles.empty}>{lang === 'ar' ? 'جاري تجهيز كورساتك...' : 'Preparing your courses...'}</div>
        ) : enrollments.length ? (
          <div className={styles.courseGrid}>
            {enrollments.map((enrollment) => {
              const course = enrollment.courses;
              const title = lang === 'ar' ? course.title_ar : course.title_en;
              return (
                <article className={styles.courseCard} key={enrollment.id}>
                  <div className={styles.courseImage}>
                    <BookOpen size={36} />
                    {course.thumbnail_url && <img src={course.thumbnail_url} alt={title} onError={(event) => { event.currentTarget.style.display = 'none'; }} />}
                    <Link href={`/learn/${enrollment.course_id}`}><Play size={17} fill="currentColor" /></Link>
                  </div>
                  <div className={styles.courseBody}>
                    <h3>{title}</h3>
                    <div className={styles.courseMeta}><span><Clock3 size={13} />{enrollment.completed_lessons}/{course.total_lessons || 0}</span><strong>{Math.round(enrollment.progress_percentage || 0)}%</strong></div>
                    <div className={styles.track}><i style={{ width: `${enrollment.progress_percentage || 0}%` }} /></div>
                  </div>
                </article>
              );
            })}
          </div>
        ) : (
          <div className={styles.empty}>
            <Trophy size={30} />
            <strong>{lang === 'ar' ? 'ابدأ أول كورس وخلّي تقدمك يظهر هنا' : 'Start your first course to see progress here'}</strong>
            <Link href="/courses">{lang === 'ar' ? 'تصفح الكورسات' : 'Browse courses'}</Link>
          </div>
        )}
      </section>
    </main>
  );
}
