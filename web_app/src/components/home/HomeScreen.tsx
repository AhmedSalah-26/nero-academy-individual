'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import {
  ArrowForward,
  AutoAwesome,
  CardMembership,
  EmojiEvents,
  FavoriteBorder,
  Forum,
  History,
  LocalFireDepartment,
  MenuBook,
  Quiz,
  School,
  Star,
  WorkspacePremium,
  Code,
  DesignServices,
  BusinessCenter,
  Campaign,
  CameraAlt,
  GraphicEq,
  Language,
  HealthAndSafety,
  Smartphone,
  Science,
  Calculate,
  FolderOpen,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { BannerCarousel } from './BannerCarousel';

function getCategoryConfig(iconName?: string) {
  switch (iconName?.toLowerCase()) {
    case 'code':
      return { icon: <Code fontSize="medium" />, color: '#2563EB' };
    case 'design':
      return { icon: <DesignServices fontSize="medium" />, color: '#8B5CF6' };
    case 'business':
      return { icon: <BusinessCenter fontSize="medium" />, color: '#059669' };
    case 'marketing':
      return { icon: <Campaign fontSize="medium" />, color: '#D97706' };
    case 'photography':
      return { icon: <CameraAlt fontSize="medium" />, color: '#DC2626' };
    case 'music':
      return { icon: <GraphicEq fontSize="medium" />, color: '#7C3AED' };
    case 'academics':
    case 'school':
      return { icon: <School fontSize="medium" />, color: '#0891B2' };
    case 'language':
    case 'languages':
      return { icon: <Language fontSize="medium" />, color: '#4F46E5' };
    case 'health':
      return { icon: <HealthAndSafety fontSize="medium" />, color: '#16A34A' };
    case 'mobile':
    case 'smartphone':
      return { icon: <Smartphone fontSize="medium" />, color: '#E11D48' };
    case 'science':
      return { icon: <Science fontSize="medium" />, color: '#F59E0B' };
    case 'math':
      return { icon: <Calculate fontSize="medium" />, color: '#0EA5E9' };
    default:
      return { icon: <FolderOpen fontSize="medium" />, color: '#64748B' };
  }
}
import { FlashSaleSection } from './FlashSaleSection';
import { CourseSection } from './CourseSection';
import { ContinueLearningCard } from './ContinueLearningCard';
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
  const activeEnrollments = enrollments.filter((item) => item.progress_percentage < 100);
  const completedLessons = enrollments.reduce((sum, item) => sum + (item.completed_lessons || 0), 0);
  const totalLessons = enrollments.reduce((sum, item) => sum + (item.courses?.total_lessons || 0), 0);
  const averageProgress = enrollments.length
    ? Math.round(enrollments.reduce((sum, item) => sum + (item.progress_percentage || 0), 0) / enrollments.length)
    : 0;
  const level = Math.max(1, Math.ceil((completedLessons + enrollments.length) / 5));
  const points = completedLessons * 25 + enrollments.length * 100;
  const nextLevelTarget = Math.max((level + 1) * 250, 250);
  const levelProgress = Math.min(100, Math.round((points / nextLevelTarget) * 100));
  const primaryEnrollment = enrollments[0];
  const continueHref = '/my-learning';
  const heroProgress = Math.max(averageProgress, activeEnrollments.length ? 12 : 0);
  const profileInitial = (firstName || user?.email || 'S').trim().charAt(0).toUpperCase();
  const displayName = profile?.name || firstName || user?.email?.split('@')[0] || 'Student';
  const statItems = [
    {
      icon: <LocalFireDepartment />,
      value: activeEnrollments.length || enrollments.length,
      label: lang === 'ar' ? 'كورسات نشطة' : 'Active courses',
      hint: lang === 'ar' ? 'استمر في التعلم' : 'Keep learning',
      tone: 'warm',
    },
    {
      icon: <MenuBook />,
      value: completedLessons,
      label: lang === 'ar' ? 'دروس مكتملة' : 'Completed lessons',
      hint: totalLessons ? `${lang === 'ar' ? 'من' : 'of'} ${totalLessons}` : lang === 'ar' ? 'ابدأ أول درس' : 'Start a lesson',
      tone: 'green',
    },
    {
      icon: <WorkspacePremium />,
      value: averageProgress ? `${averageProgress}%` : '0%',
      label: lang === 'ar' ? 'متوسط التقدم' : 'Average progress',
      hint: lang === 'ar' ? 'على كل كورساتك' : 'Across courses',
      tone: 'violet',
    },
    {
      icon: <Star />,
      value: points,
      label: lang === 'ar' ? 'النقاط' : 'Points',
      hint: `${lang === 'ar' ? 'المستوى' : 'Level'} ${level}`,
      tone: 'blue',
    },
  ];
  const quickActions = [
    { href: '/my-learning', icon: <MenuBook />, label: lang === 'ar' ? 'دروسي' : 'My Courses' },
    { href: '/exams', icon: <Quiz />, label: lang === 'ar' ? 'الاختبارات' : 'Exams' },
    { href: '/wishlist', icon: <FavoriteBorder />, label: lang === 'ar' ? 'المفضلة' : 'Wishlist' },
    { href: '/forums', icon: <Forum />, label: lang === 'ar' ? 'المنتدى' : 'Forum' },
    { href: '/history', icon: <History />, label: lang === 'ar' ? 'السجل' : 'History' },
  ];

  return (
    <main className={styles.page}>
      <div className={styles.dashboardShell}>
        <div className={styles.mainColumn}>
          <section className={styles.hero}>
            <div className={styles.heroContent}>
              <span className={styles.heroEyebrow}>
                <AutoAwesome fontSize="small" />
                {lang === 'ar' ? 'لوحة تعلمك اليومية' : 'Your daily learning hub'}
              </span>
              <h1 className={styles.heroGreeting}>{firstNameAr}</h1>
              <p className={styles.heroSubtitle}>
                {lang === 'ar'
                  ? 'كل مذاكرتك ومتابعة تقدمك ومجتمعك في مكان واحد.'
                  : 'Your learning, progress, and community in one place.'}
              </p>
              <div className={styles.heroActions}>
                <Link href={continueHref} className={styles.primaryHeroButton}>
                  <span>{lang === 'ar' ? 'استكمل التعلم' : 'Continue learning'}</span>
                  <ArrowForward fontSize="small" />
                </Link>
                <Link href="/courses" className={styles.secondaryHeroButton}>
                  <School fontSize="small" />
                  <span>{lang === 'ar' ? 'استكشف الكورسات' : 'Explore courses'}</span>
                </Link>
              </div>
              <div className={styles.heroProgressCard}>
                <div>
                  <span className={styles.progressLabel}>{lang === 'ar' ? 'تقدمك هذا الأسبوع' : 'Weekly progress'}</span>
                  <strong>{heroProgress}%</strong>
                </div>
                <div className={styles.progressTrack}>
                  <span style={{ width: `${heroProgress}%` }} />
                </div>
                <p>{lang === 'ar' ? 'أنت على الطريق الصحيح' : 'You are on the right track'}</p>
              </div>
            </div>
            <div className={styles.heroVisual} aria-hidden="true">
              <img src="/transparent_hero.png" alt="" />
            </div>
          </section>



          <section className={styles.statsGrid} aria-label={lang === 'ar' ? 'إحصائيات التعلم' : 'Learning statistics'}>
            {statItems.map((stat) => (
              <article key={stat.label} className={`${styles.statCard} ${styles[stat.tone]}`}>
                <span className={styles.statIcon}>{stat.icon}</span>
                <div>
                  <strong>{stat.value}</strong>
                  <span>{stat.label}</span>
                  <small>{stat.hint}</small>
                </div>
              </article>
            ))}
          </section>

          <div className={styles.bannerWrapper}>
            <BannerCarousel />
          </div>

          {categories.length > 0 && (
            <div className={styles.section}>
              <SectionHeader
                title={lang === 'ar' ? 'الأقسام الرئيسية' : 'Main Categories'}
                seeAllHref="/categories"
              />
              <div className={styles.categoriesGrid}>
                {categories.map((cat) => {
                  const cfg = getCategoryConfig(cat.icon_name);
                  const alphaColor = cfg.color + '26'; // 15% opacity overlay

                  return (
                    <Link
                      key={cat.id}
                      href={`/search?category=${cat.id}`}
                      className={styles.homeCategoryCard}
                    >
                      <div
                        className={styles.homeIconContainer}
                        style={{ backgroundColor: alphaColor, color: cfg.color }}
                      >
                        {cfg.icon}
                      </div>
                      <span className={styles.homeCategoryName}>
                        {lang === 'ar' ? cat.name_ar : cat.name_en}
                      </span>
                    </Link>
                  );
                })}
              </div>
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

          {popularCourses.length > 0 && (
            <CourseSection
              title={lang === 'ar' ? 'الأكثر شعبية' : 'Popular Courses'}
              courses={popularCourses}
              locale={lang}
              onSeeAll="/courses"
              onWishlistToggle={handleWishlistToggle}
            />
          )}

          {enrollments.length > 0 && (
            <div className={styles.section}>
              <SectionHeader
                title={lang === 'ar' ? 'تابع التعلم' : 'Continue Learning'}
                icon={<span className={styles.continueIcon}>▶</span>}
                seeAllHref="/my-learning"
              />
              <div className={styles.continueGrid}>
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

          {featuredCourses.length > 0 && (
            <CourseSection
              title={lang === 'ar' ? 'الكورسات المميزة' : 'Featured Courses'}
              courses={featuredCourses}
              locale={lang}
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
        </div>

        <aside className={styles.sidebar} aria-label={lang === 'ar' ? 'لوحة الطالب الجانبية' : 'Student side panel'}>
          <section className={styles.profileCard}>
            <div className={styles.avatarWrap}>
              {profile?.avatar_url ? <img src={profile.avatar_url} alt={displayName} /> : <span>{profileInitial}</span>}
              <i />
            </div>
            <h2>{displayName}</h2>
            <div className={styles.profileStats}>
              <div>
                <strong>{enrollments.length}</strong>
                <span>{lang === 'ar' ? 'عدد الدورات' : 'Courses'}</span>
              </div>
              <div>
                <strong>{Math.round((completedLessons * 1.2 + 1) * 10) / 10}</strong>
                <span>{lang === 'ar' ? 'ساعات الاستخدام' : 'Usage Hours'}</span>
              </div>
            </div>
          </section>

          <section className={styles.offerCard}>
            <div className={styles.giftIcon}>🎁</div>
            <div>
              <span>{lang === 'ar' ? 'عرض خاص' : 'Special offer'}</span>
              <strong>{lang === 'ar' ? 'خصومات على الكورسات' : 'Course discounts'}</strong>
            </div>
            <Link href="/courses">{lang === 'ar' ? 'استكشف العروض' : 'Explore'}</Link>
          </section>

          <section className={styles.quickPanel}>
            <h2>{lang === 'ar' ? 'الوصول السريع' : 'Quick Access'}</h2>
            <div className={styles.quickLinks}>
              {quickActions.map((item) => (
                <Link key={item.href} href={item.href}>
                  <span>{item.label}</span>
                  {item.icon}
                </Link>
              ))}
            </div>
          </section>

          <section className={styles.communityCard}>
            <Forum />
            <h2>{lang === 'ar' ? 'انضم إلى مجتمع شهاب Tech' : 'Join Sehap Tech community'}</h2>
            <p>{lang === 'ar' ? 'تفاعل، اسأل، شارك وتعلم مع الآخرين.' : 'Ask, share, and learn with other students.'}</p>
            <Link href="/forums">{lang === 'ar' ? 'دخول المنتدى' : 'Open forum'}</Link>
          </section>
        </aside>
      </div>

      <div className={styles.bottomSpacer} />
    </main>
  );
}
