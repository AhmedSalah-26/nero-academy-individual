'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { PlayCircle, EmojiEvents, MenuBook, Schedule, Lock, TrendingUp } from '@mui/icons-material';
import { ShimmerEffect, EmptyState, FilterChips, SectionHeader, RatingStars } from '../../components/ui';
import { NumberUtils, AppDateUtils } from '../../lib/formatters';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface EnrolledCourse {
  id: string;
  course_id: string;
  progress_percentage: number;
  completed_lessons: number;
  status: string;
  expiry_date?: string;
  last_accessed_at?: string;
  courses: {
    title_ar: string;
    title_en: string;
    subtitle_ar: string;
    subtitle_en: string;
    thumbnail_url: string;
    total_lessons: number;
    rating?: number;
    rating_count?: number;
  };
}

interface RecommendedCourse {
  id: string;
  title_ar: string;
  title_en: string;
  thumbnail_url: string;
  price: number;
  discount_price: number;
  is_free: boolean;
  rating?: number;
}

const PAGE_SIZE = 20;

export default function MyLearningPage() {
  const pageRef = usePageTransition();
  const { lang, t, user, loading: authLoading } = useApp();
  const router = useRouter();

  const [enrollments, setEnrollments] = useState<EnrolledCourse[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string[]>(['in-progress']);
  const [page, setPage] = useState(1);
  const [recommended, setRecommended] = useState<RecommendedCourse[]>([]);
  const loadMoreRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      router.push('/login?redirect=/my-learning');
      return;
    }
    const currentUser = user;

    async function fetchMyEnrollments() {
      try {
        const { data, error } = await supabase
          .from('enrollments')
          .select(`
            id,
            course_id,
            progress_percentage,
            completed_lessons,
            status,
            expiry_date,
            last_accessed_at,
            courses (
              title_ar,
              title_en,
              subtitle_ar,
              subtitle_en,
              thumbnail_url,
              total_lessons,
              rating,
              rating_count
            )
          `)
          .eq('user_id', currentUser.id)
          .in('status', ['active', 'completed', 'expired', 'inactive'])
          .order('last_accessed_at', { ascending: false });

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

  const enrolledCourseIds = enrollments.map((e) => e.course_id);

  useEffect(() => {
    if (enrolledCourseIds.length === 0) return;
    async function fetchRecommended() {
      try {
        const { data } = await supabase
          .from('courses')
          .select('id, title_ar, title_en, thumbnail_url, price, discount_price, is_free, rating')
          .not('id', 'in', `(${enrolledCourseIds.join(',')})`)
          .eq('is_published', true)
          .limit(4);
        if (data) setRecommended(data as RecommendedCourse[]);
      } catch {}
    }
    fetchRecommended();
  }, [enrolledCourseIds.length]);

  const filtered = React.useMemo(() => {
    const currentFilter = filter[0] || 'in-progress';
    if (currentFilter === 'in-progress') return enrollments.filter((e) => e.status === 'active' && e.progress_percentage < 100);
    if (currentFilter === 'completed') return enrollments.filter((e) => e.status === 'completed' || e.progress_percentage >= 100);
    return enrollments;
  }, [enrollments, filter]);

  const paginated = filtered.slice(0, page * PAGE_SIZE);
  const hasMore = filtered.length > page * PAGE_SIZE;

  const continueCourse = React.useMemo(() => {
    const active = enrollments.filter((e) => e.status === 'active' && e.progress_percentage < 100);
    if (!active.length) return null;
    active.sort((a, b) => {
      const aTime = a.last_accessed_at ? new Date(a.last_accessed_at).getTime() : 0;
      const bTime = b.last_accessed_at ? new Date(b.last_accessed_at).getTime() : 0;
      return bTime - aTime;
    });
    return active[0];
  }, [enrollments]);

  useEffect(() => {
    if (!loadMoreRef.current || !hasMore) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          setPage((prev) => prev + 1);
        }
      },
      { threshold: 0.1 }
    );
    observer.observe(loadMoreRef.current);
    return () => observer.disconnect();
  }, [hasMore]);

  const getStatusBadge = (enroll: EnrolledCourse) => {
    const isCompleted = enroll.status === 'completed' || enroll.progress_percentage >= 100;
    const isExpired = enroll.status === 'expired' || (enroll.expiry_date && new Date(enroll.expiry_date) < new Date());
    const isInactive = enroll.status === 'inactive';

    if (isCompleted) {
      return (
        <span className={`${styles.statusBadge} ${styles.completedBadge}`}>
          <EmojiEvents fontSize="small" />
          <span>{t.completed}</span>
        </span>
      );
    }
    if (isExpired) {
      return (
        <span className={`${styles.statusBadge} ${styles.expiredBadge}`}>
          <Lock fontSize="small" />
          <span>{lang === 'ar' ? 'منتهي' : 'Expired'}</span>
        </span>
      );
    }
    if (isInactive) {
      return (
        <span className={`${styles.statusBadge} ${styles.inactiveBadge}`}>
          <Schedule fontSize="small" />
          <span>{lang === 'ar' ? 'غير نشط' : 'Inactive'}</span>
        </span>
      );
    }
    return (
      <span className={`${styles.statusBadge} ${styles.activeBadge}`}>
        <TrendingUp fontSize="small" />
        <span>{lang === 'ar' ? 'مستمر' : 'In Progress'}</span>
      </span>
    );
  };

  const inProgressCount = enrollments.filter((e) => e.status === 'active' && e.progress_percentage < 100).length;
  const completedCount = enrollments.filter((e) => e.status === 'completed' || e.progress_percentage >= 100).length;

  const filterChips = [
    { id: 'in-progress', label: t.inProgress, count: inProgressCount },
    { id: 'completed', label: t.completedTab, count: completedCount },
    { id: 'all', label: t.all, count: enrollments.length },
  ];

  if (authLoading || loading) {
    return (
      <div className={styles.loadingState}>
        <div className={styles.shimmerGrid}>
          <div className={styles.shimmerContinue}>
            <ShimmerEffect width="100%" height="140px" borderRadius="lg" />
          </div>
          {[1, 2, 3].map((i) => (
            <div key={i} className={styles.shimmerCard}>
              <ShimmerEffect width="100%" height="170px" borderRadius="lg" />
              <div className={styles.shimmerCardBody}>
                <ShimmerEffect width="60%" height="14px" borderRadius="sm" />
                <ShimmerEffect width="80%" height="16px" borderRadius="sm" />
                <ShimmerEffect width="100%" height="8px" borderRadius="sm" />
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div ref={pageRef} className="container fade-in">
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

      {continueCourse && (
        <div className={`${styles.continueCard} glass`}>
          <div className={styles.continueThumb}>
            {continueCourse.courses.thumbnail_url ? (
              <img
                src={continueCourse.courses.thumbnail_url}
                alt={lang === 'ar' ? continueCourse.courses.title_ar : continueCourse.courses.title_en}
                className={styles.continueImg}
              />
            ) : (
              <div className={styles.continuePlaceholder}>
                <PlayCircle fontSize="large" />
              </div>
            )}
            <div className={styles.continueOverlay}>
              <PlayCircle className={styles.continuePlayIcon} />
            </div>
          </div>
          <div className={styles.continueBody}>
            <span className={styles.continueLabel}>
              {lang === 'ar' ? 'واصل التعلم' : 'Continue Learning'}
            </span>
            <h3 className={styles.continueTitle}>
              {lang === 'ar' ? continueCourse.courses.title_ar : continueCourse.courses.title_en}
            </h3>
            <div className={styles.continueProgress}>
              <div className={styles.continueProgressInfo}>
                <span>{t.progress}</span>
                <span>{Math.round(continueCourse.progress_percentage)}%</span>
              </div>
              <div className={styles.continueProgressBar}>
                <div
                  className={styles.continueProgressFill}
                  style={{ width: `${continueCourse.progress_percentage}%` }}
                />
              </div>
            </div>
            {getStatusBadge(continueCourse)}
            <Link
              href={`/learn/${continueCourse.course_id}`}
              className={`${styles.continueBtn} gradient-bg`}
            >
              <PlayCircle fontSize="small" />
              <span>{t.continueLearning}</span>
            </Link>
            {continueCourse.last_accessed_at && (
              <span className={styles.continueTime}>
                {lang === 'ar' ? 'آخر نشاط: ' : 'Last activity: '}
                {AppDateUtils.getRelativeTime(continueCourse.last_accessed_at, lang)}
              </span>
            )}
          </div>
        </div>
      )}

      {enrollments.length === 0 ? (
        <div className={styles.emptyContainer}>
          <EmptyState
            type="myLearning"
            title={lang === 'ar' ? 'لست مسجلاً في أي كورس حالياً' : 'Not enrolled in any courses yet'}
            message={lang === 'ar' ? 'استكشف المقررات المتاحة وابدأ رحلة التعلم' : 'Explore available courses and start your learning journey'}
            actionLabel={lang === 'ar' ? 'استكشف المقررات' : 'Explore Courses'}
            onAction={() => router.push('/')}
          />
        </div>
      ) : (
        <>
          <div className={styles.filterRow}>
            <FilterChips items={filterChips} selected={filter} onChange={setFilter} />
          </div>

          {filtered.length === 0 ? (
            <div className={styles.noResults}>
              <EmptyState type="search" title={t.noResults} compact />
            </div>
          ) : (
            <div className={styles.coursesGrid}>
              {paginated.map((enroll) => {
                const courseDetails = enroll.courses;
                const isExpired = enroll.status === 'expired' || (enroll.expiry_date && new Date(enroll.expiry_date) < new Date());

                return (
                  <div key={enroll.id} className={`${styles.courseCard} glass animate-hover`}>
                    <div className={styles.cardMedia}>
                      <MenuBook fontSize="large" className={styles.placeholderIcon} />
                      {courseDetails.thumbnail_url && (
                        <img
                          src={courseDetails.thumbnail_url}
                          alt={lang === 'ar' ? courseDetails.title_ar : courseDetails.title_en}
                          className={styles.cardImg}
                          onError={(event) => { event.currentTarget.style.display = 'none'; }}
                        />
                      )}
                      {isExpired && <div className={styles.expiredOverlay} />}
                    </div>

                    <div className={styles.cardBody}>
                      <div className={styles.badgeRow}>
                        {getStatusBadge(enroll)}
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
                          />
                        </div>
                        <div className={styles.lessonsCount}>
                          {enroll.completed_lessons} / {courseDetails.total_lessons || 0} {t.lessonsCount}
                        </div>
                      </div>

                      {!isExpired && (
                        <Link
                          href={`/learn/${enroll.course_id}`}
                          className={`${styles.playBtn} gradient-bg`}
                        >
                          <PlayCircle fontSize="small" />
                          <span>{t.continueLearning}</span>
                        </Link>
                      )}
                    </div>
                  </div>
                );
              })}

              {hasMore && <div ref={loadMoreRef} className={styles.loadMoreSentinel} />}
            </div>
          )}
        </>
      )}

      {recommended.length > 0 && (
        <section className={styles.recommendedSection}>
          <SectionHeader
            title={lang === 'ar' ? 'كورسات مقترحة لك' : 'Recommended For You'}
            subtitle={lang === 'ar' ? 'بناءً على اهتماماتك' : 'Based on your interests'}
          />
          <div className={styles.recommendedGrid}>
            {recommended.map((course) => (
              <Link
                key={course.id}
                href={`/courses/${course.id}`}
                className={styles.recommendedCard}
              >
                <div className={styles.recMedia}>
                  {course.thumbnail_url ? (
                    <img src={course.thumbnail_url} alt="" className={styles.recImg} />
                  ) : (
                    <div className={styles.recPlaceholder}>
                      <MenuBook fontSize="large" />
                    </div>
                  )}
                </div>
                <div className={styles.recBody}>
                  <h4 className={styles.recTitle}>
                    {lang === 'ar' ? course.title_ar : course.title_en}
                  </h4>
                  {course.rating != null && course.rating > 0 && (
                    <RatingStars value={course.rating} size="xs" showValue />
                  )}
                  <span className={styles.recPrice}>
                    {course.is_free
                      ? t.free
                      : NumberUtils.formatPrice(course.discount_price || course.price, lang)
                    }
                  </span>
                </div>
              </Link>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
