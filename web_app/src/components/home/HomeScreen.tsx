'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { BannerCarousel } from './BannerCarousel';
import { CategoryChips } from './CategoryChips';
import { FlashSaleSection } from './FlashSaleSection';
import { CourseSection } from './CourseSection';
import { ContinueLearningCard } from './ContinueLearningCard';
import { ParentPortalCard } from './ParentPortalCard';
import { VerticalCourseCard, type CourseData } from './VerticalCourseCard';
import { HomeSkeleton } from './HomeSkeleton';
import { SectionHeader } from './SectionHeader';
import styles from './HomeScreen.module.css';

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

interface Category {
  id: string;
  name_ar?: string;
  name_en?: string;
  icon_name?: string;
}

export function HomeScreen() {
  const { lang, user, profile, addToWishlist, removeFromWishlist, wishlist } = useApp();
  const [loading, setLoading] = useState(true);
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCat, setSelectedCat] = useState<string | null>(null);
  const [featuredCourses, setFeaturedCourses] = useState<CourseData[]>([]);
  const [popularCourses, setPopularCourses] = useState<CourseData[]>([]);
  const [newCourses, setNewCourses] = useState<CourseData[]>([]);
  const [flashSaleCourses, setFlashSaleCourses] = useState<CourseData[]>([]);
  const [recommendedCourses, setRecommendedCourses] = useState<CourseData[]>([]);
  const [enrollments, setEnrollments] = useState<Enrollment[]>([]);
  const [flashSaleEnd, setFlashSaleEnd] = useState<string | undefined>();

  useEffect(() => {
    let cancelled = false;

    async function fetchHomeData() {
      try {
        const queries: Promise<void>[] = [];

        const catQ = supabase.from('categories').select('*').eq('is_active', true).order('sort_order').limit(10);
        queries.push(Promise.resolve(catQ).then(({ data }) => { if (!cancelled && data) setCategories(data as Category[]); }));

        const featQ = supabase.from('courses').select('*').eq('is_published', true).eq('is_active', true).eq('is_featured', true).limit(6);
        queries.push(Promise.resolve(featQ).then(({ data }) => { if (!cancelled && data) setFeaturedCourses(data as CourseData[]); }));

        const popQ = supabase.from('courses').select('*').eq('is_published', true).eq('is_active', true).order('enrolled_count', { ascending: false }).limit(6);
        queries.push(Promise.resolve(popQ).then(({ data }) => { if (!cancelled && data) setPopularCourses(data as CourseData[]); }));

        const newQ = supabase.from('courses').select('*').eq('is_published', true).eq('is_active', true).order('created_at', { ascending: false }).limit(5);
        queries.push(Promise.resolve(newQ).then(({ data }) => { if (!cancelled && data) setNewCourses(data as CourseData[]); }));

        const flashQ = supabase.from('courses').select('*').eq('is_published', true).eq('is_active', true).eq('is_flash_sale', true).limit(6);
        queries.push(Promise.resolve(flashQ).then(({ data }) => {
          if (!cancelled && data) {
            setFlashSaleCourses(data as CourseData[]);
            let earliest: string | undefined;
            for (const c of data as CourseData[]) {
              if (c.flash_sale_end && (!earliest || c.flash_sale_end < earliest)) {
                earliest = c.flash_sale_end;
              }
            }
            setFlashSaleEnd(earliest);
          }
        }));

        const recQ = supabase.from('courses').select('*').eq('is_published', true).eq('is_active', true).limit(6);
        queries.push(Promise.resolve(recQ).then(({ data }) => { if (!cancelled && data) setRecommendedCourses(data as CourseData[]); }));

        if (user?.id) {
          const enrollQ = supabase
            .from('enrollments')
            .select(`id,course_id,progress_percentage,completed_lessons,courses(title_ar,title_en,subtitle_ar,subtitle_en,thumbnail_url,total_lessons)`)
            .eq('user_id', user.id)
            .in('status', ['active', 'completed'])
            .order('updated_at', { ascending: false })
            .limit(4);
          queries.push(Promise.resolve(enrollQ).then(({ data }) => {
            if (!cancelled && data) setEnrollments(data as unknown as Enrollment[]);
          }));
        }

        await Promise.allSettled(queries);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    fetchHomeData();
    return () => { cancelled = true; };
  }, [user?.id]);

  const handleWishlistToggle = useCallback(
    async (courseId: string) => {
      if (wishlist.includes(courseId)) {
        await removeFromWishlist(courseId);
      } else {
        await addToWishlist(courseId);
      }
    },
    [wishlist, addToWishlist, removeFromWishlist]
  );

  const firstName = profile?.name?.split(' ')[0] || user?.email?.split('@')[0] || '';

  if (loading) {
    return (
      <main className={styles.page}>
        <div className={styles.heroShimmer} />
        <HomeSkeleton />
      </main>
    );
  }

  const firstNameAr = lang === 'ar' ? `أهلاً ${firstName}` : `Hello, ${firstName}`;

  return (
    <main className={styles.page}>
      <section className={styles.hero}>
        <div className={styles.heroContent}>
          <p className={styles.heroGreeting}>{firstNameAr}</p>
          <p className={styles.heroSubtitle}>
            {lang === 'ar'
              ? 'كل مذاكرتك ومتابعة تقدمك ومجتمعك في مكان واحد.'
              : 'Your learning, progress, and community in one place.'}
          </p>
        </div>
        <Link href="/search" className={styles.searchBar}>
          <span className={styles.searchIcon}>🔍</span>
          <span className={styles.searchPlaceholder}>
            {lang === 'ar' ? 'ابحث عن درس، امتحان، مذكرة ...' : 'Search for lessons, exams, notes...'}
          </span>
          <span className={styles.tuneIcon}>⚙</span>
        </Link>
      </section>

      <BannerCarousel />

      {categories.length > 0 && (
        <div className={styles.section}>
          <CategoryChips categories={categories} selectedId={selectedCat} onSelect={setSelectedCat} />
        </div>
      )}

      {flashSaleCourses.length > 0 && (
        <div className={styles.section}>
          <FlashSaleSection endTime={flashSaleEnd}>
            <div className={styles.horizontalScroll}>
              {flashSaleCourses.map((course) => (
                <VerticalCourseCard
                  key={course.id}
                  course={course}
                  isWishlisted={wishlist.includes(course.id)}
                  onWishlistToggle={() => handleWishlistToggle(course.id)}
                />
              ))}
            </div>
          </FlashSaleSection>
        </div>
      )}

      {featuredCourses.length > 0 && (
        <CourseSection
          title={lang === 'ar' ? 'الكورسات المميزة' : 'Featured Courses'}
          courses={featuredCourses}
          locale={lang}
          onSeeAll="/courses"
          onWishlistToggle={handleWishlistToggle}
        />
      )}

      {popularCourses.length > 0 && (
        <CourseSection
          title={lang === 'ar' ? 'الأكثر شعبية' : 'Popular Courses'}
          courses={popularCourses}
          locale={lang}
          onSeeAll="/courses"
          onWishlistToggle={handleWishlistToggle}
        />
      )}

      {newCourses.length > 0 && (
        <CourseSection
          title={lang === 'ar' ? 'وصل حديثاً' : 'New Arrivals'}
          courses={newCourses}
          locale={lang}
          isVertical
          onSeeAll="/courses"
          onWishlistToggle={handleWishlistToggle}
        />
      )}

      {recommendedCourses.length > 0 && (
        <div className={styles.section}>
          <SectionHeader
            title={lang === 'ar' ? 'موصى به لك' : 'Recommended for You'}
            subtitle={lang === 'ar' ? 'بناءً على اهتماماتك' : 'Based on your interests'}
            icon={<span className={styles.aiIcon}>✨</span>}
            seeAllHref="/courses"
          />
          <div className={styles.horizontalScroll}>
            {recommendedCourses.map((course) => (
              <VerticalCourseCard
                key={course.id}
                course={course}
                isWishlisted={wishlist.includes(course.id)}
                onWishlistToggle={() => handleWishlistToggle(course.id)}
              />
            ))}
          </div>
        </div>
      )}

      {enrollments.length > 0 && (
        <div className={styles.section}>
          <SectionHeader
            title={lang === 'ar' ? 'متابعة التعلم' : 'Continue Learning'}
            icon={<span className={styles.continueIcon}>▶</span>}
            seeAllHref="/my-learning"
          />
          <div className={styles.horizontalScroll}>
            {enrollments.map((enrollment) => {
              const course = enrollment.courses;
              const title = lang === 'ar' ? course.title_ar : course.title_en;
              return (
                <ContinueLearningCard
                  key={enrollment.id}
                  id={enrollment.course_id}
                  title={title}
                  thumbnailUrl={course.thumbnail_url}
                  progress={enrollment.progress_percentage}
                  completedLessons={enrollment.completed_lessons}
                  totalLessons={course.total_lessons}
                />
              );
            })}
          </div>
        </div>
      )}

      <div className={styles.section}>
        <ParentPortalCard />
      </div>

      <div className={styles.bottomSpacer} />
    </main>
  );
}
