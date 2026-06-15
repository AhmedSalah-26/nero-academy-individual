'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { PlayCircle, Award, BookOpen, AlertCircle } from 'lucide-react';
import styles from './page.module.css';

interface EnrolledCourse {
  id: string; // enrollment id
  course_id: string;
  progress_percentage: number;
  completed_lessons: number;
  status: string;
  courses: {
    title_ar: string;
    title_en: string;
    subtitle_ar: string;
    subtitle_en: string;
    thumbnail_url: string;
    total_lessons: number;
  };
}

export default function MyLearningPage() {
  const { lang, t, user, loading: authLoading } = useApp();
  const router = useRouter();

  const [enrollments, setEnrollments] = useState<EnrolledCourse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      router.push('/login?redirect=/my-learning');
      return;
    }
    const currentUser = user;

    async function fetchMyEnrollments() {
      try {
        // Query enrollments with course details
        const { data, error } = await supabase
          .from('enrollments')
          .select(`
            id,
            course_id,
            progress_percentage,
            completed_lessons,
            status,
            courses (
              title_ar,
              title_en,
              subtitle_ar,
              subtitle_en,
              thumbnail_url,
              total_lessons
            )
          `)
          .eq('user_id', currentUser.id)
          .in('status', ['active', 'completed']);

        if (data && !error) {
          setEnrollments(data as unknown as EnrolledCourse[]);
        }
      } catch (err) {
        console.error('Error fetching enrollments:', err);
      } finally {
        setLoading(false);
      }
    }

    fetchMyEnrollments();
  }, [authLoading, user, router]);

  if (authLoading || loading) {
    return (
      <div className={styles.loadingState}>
        <div className={styles.spinner}></div>
        <p>{t.loading}</p>
      </div>
    );
  }

  return (
    <div className="container fade-in">
      <div className={styles.dashboardHeader}>
        <div>
          <h1 className={styles.pageTitle}>{t.myLearningTitle}</h1>
          <p className={styles.subtext}>
            {lang === 'ar' 
              ? 'تابع تقدمك الدراسي وأكمل دوراتك التدريبية' 
              : 'Track your academic progress and complete your training courses'}
          </p>
        </div>
      </div>

      {enrollments.length === 0 ? (
        <div className={`${styles.emptyContainer} glass`}>
          <AlertCircle size={48} className={styles.emptyIcon} />
          <h2>{lang === 'ar' ? 'لست مسجلاً في أي كورس حالياً' : 'You are not enrolled in any courses yet.'}</h2>
          <Link href="/" className={`${styles.browseBtn} gradient-bg`}>
            {lang === 'ar' ? 'استكشف المقررات المتاحة' : 'Explore Available Courses'}
          </Link>
        </div>
      ) : (
        <div className={styles.coursesGrid}>
          {enrollments.map((enroll) => {
            const courseDetails = enroll.courses;
            const isCompleted = enroll.status === 'completed' || enroll.progress_percentage >= 100;

            return (
              <div key={enroll.id} className={`${styles.courseCard} glass animate-hover`}>
                {courseDetails.thumbnail_url ? (
                  <img 
                    src={courseDetails.thumbnail_url} 
                    alt={lang === 'ar' ? courseDetails.title_ar : courseDetails.title_en}
                    className={styles.cardImg}
                  />
                ) : (
                  <div className={styles.placeholderImg}>
                    <BookOpen size={40} className={styles.placeholderIcon} />
                  </div>
                )}

                <div className={styles.cardBody}>
                  <div className={styles.badgeRow}>
                    {isCompleted ? (
                      <span className={`${styles.statusBadge} ${styles.completedBadge}`}>
                        <Award size={12} />
                        <span>{t.completed}</span>
                      </span>
                    ) : (
                      <span className={`${styles.statusBadge} ${styles.activeBadge}`}>
                        {lang === 'ar' ? 'مستمر' : 'In Progress'}
                      </span>
                    )}
                  </div>

                  <h3 className={styles.courseTitle}>
                    {lang === 'ar' ? courseDetails.title_ar : courseDetails.title_en}
                  </h3>

                  <p className={styles.courseSubtitle}>
                    {lang === 'ar' ? courseDetails.subtitle_ar : courseDetails.subtitle_en}
                  </p>

                  <div className={styles.progressSection}>
                    <div className={styles.progressInfo}>
                      <span className={styles.progressLabel}>{t.progress}</span>
                      <span className={styles.progressValue}>
                        {Math.round(enroll.progress_percentage)}%
                      </span>
                    </div>
                    <div className={styles.progressBarBg}>
                      <div 
                        className={styles.progressBarFill} 
                        style={{ width: `${enroll.progress_percentage}%` }}
                      ></div>
                    </div>
                    <div className={styles.lessonsCount}>
                      {enroll.completed_lessons} / {courseDetails.total_lessons || 0} {t.lessonsCount}
                    </div>
                  </div>

                  <Link 
                    href={`/learn/${enroll.course_id}`} 
                    className={`${styles.playBtn} gradient-bg`}
                  >
                    <PlayCircle size={18} />
                    <span>{t.continueLearning}</span>
                  </Link>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
