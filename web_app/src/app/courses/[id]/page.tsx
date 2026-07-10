'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { ReviewsSection } from '../../../components/ReviewsSection';
import { RatingDistribution, PricingOptionsSheet } from '../../../components/ui';
import {
  PlayArrow,
  Check,
  ExpandMore,
  ExpandLess,
  Schedule,
  MenuBook,
  Star,
  ShoppingCart,
  Lock,
  Article,
  Quiz,
  CardMembership,
  Share,
  Flag,
} from '@mui/icons-material';
import styles from './page.module.css';
import { sanitizeHtml } from '../../../lib/sanitize';
import { usePageTransition } from '../../../lib/animations';
import { getBaseCoursePrice, getEffectiveCoursePrice, hasCourseDiscount } from '../../../lib/pricing';

interface Lesson {
  id: string;
  title_ar: string;
  title_en: string;
  type: string;
  video_duration: number;
  is_preview: boolean;
}

interface Section {
  id: string;
  title_ar: string;
  title_en: string;
  sort_order: number;
  lessons: Lesson[];
}

interface PricingOption {
  label: string;
  price: number;
  duration_days?: number;
  originalPrice?: number;
}

interface CourseDetails {
  id: string;
  title_ar: string;
  title_en: string;
  subtitle_ar: string;
  subtitle_en: string;
  description_ar: string;
  description_en: string;
  thumbnail_url: string;
  preview_video_url: string;
  price: number;
  discount_price: number;
  is_free: boolean;
  pricing_options: PricingOption[];
  currency: string;
  total_lessons: number;
  total_duration: number;
  total_quizzes: number;
  has_certificate: boolean;
  enrolled_count: number;
  rating: number;
  rating_count: number;
  rating_distribution: Record<string, number>;
  requirements: string[];
  objectives: string[];
  target_audience: string[];
}

const LESSON_TYPE_ICONS: Record<string, React.ReactNode> = {};

function LessonTypeIcon({ type }: { type: string }) {
  switch (type) {
    case 'article':
    case 'text':
      return <Article fontSize="small" />;
    case 'quiz':
    case 'exam':
      return <Quiz fontSize="small" />;
    default:
      return <PlayArrow fontSize="small" />;
  }
}

export default function CourseDetailsPage() {
  const { id } = useParams();
  const router = useRouter();
  const pageRef = usePageTransition();
  const { lang, t, cart, addToCart, enrolledCourseIds } = useApp();

  const [course, setCourse] = useState<CourseDetails | null>(null);
  const [sections, setSections] = useState<Section[]>([]);
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [isEnrolledLocal, setIsEnrolledLocal] = useState(false);
  const [showPricingSheet, setShowPricingSheet] = useState(false);
  const [selectedPricingId, setSelectedPricingId] = useState<string | undefined>(undefined);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!id) return;

    async function fetchCourseDetails() {
      try {
        const { data: courseData, error: courseError } = await supabase
          .from('courses')
          .select('*')
          .eq('id', id)
          .single();

        if (courseData && !courseError) {
          const parsedOptions = typeof courseData.pricing_options === 'string' ? JSON.parse(courseData.pricing_options) : (courseData.pricing_options || []);
          
          // Fetch rating distribution from course_reviews (mirrors Flutter getRatingSummary)
          const { data: reviewsData } = await supabase
            .from('course_reviews')
            .select('rating')
            .eq('course_id', id);

          const ratingDist: Record<string, number> = { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 };
          if (reviewsData) {
            reviewsData.forEach((rev) => {
              const r = String(rev.rating);
              if (ratingDist[r] !== undefined) {
                ratingDist[r] += 1;
              }
            });
          }

          const parsedCourse = {
            ...courseData,
            requirements: typeof courseData.requirements === 'string' ? JSON.parse(courseData.requirements) : (courseData.requirements || []),
            objectives: typeof courseData.objectives === 'string' ? JSON.parse(courseData.objectives) : (courseData.objectives || []),
            target_audience: typeof courseData.target_audience === 'string' ? JSON.parse(courseData.target_audience) : (courseData.target_audience || []),
            rating_distribution: ratingDist,
            pricing_options: parsedOptions,
            total_quizzes: courseData.total_quizzes || 0,
            has_certificate: courseData.has_certificate ?? true,
            rating_count: courseData.rating_count || 0,
          };
          setCourse(parsedCourse as CourseDetails);
          if (parsedOptions && parsedOptions.length > 0) {
            setSelectedPricingId(parsedOptions[0].label);
          }
        }

        // ── Step 1: Direct query (mirrors Flutter mobile approach) ──
        // Works fully for enrolled users. Non-enrolled users see only is_preview lessons due to RLS.
        const { data: sectionsData } = await supabase
          .from('sections')
          .select(`
            id, title_ar, title_en, sort_order,
            lessons(
              id, title_ar, title_en, type, video_duration, is_preview, sort_order
            )
          `)
          .eq('course_id', id)
          .eq('is_published', true)
          .order('sort_order', { ascending: true });

        let directSections: Section[] = [];
        if (sectionsData && sectionsData.length > 0) {
          directSections = (sectionsData as Array<{
            id: string;
            title_ar: string;
            title_en: string;
            sort_order: number;
            lessons: Array<{
              id: string;
              title_ar: string;
              title_en: string;
              type: string;
              video_duration: number;
              is_preview: boolean;
              sort_order: number;
            }>;
          }>).map((sec) => ({
            id: sec.id,
            title_ar: sec.title_ar,
            title_en: sec.title_en,
            sort_order: sec.sort_order,
            lessons: (sec.lessons || []).sort((a, b) => a.sort_order - b.sort_order),
          }));
        }

        // ── Step 2: RPC fallback (mirrors Flutter _hydratePublicCurriculumIfNeeded) ──
        // The SECURITY DEFINER RPC bypasses RLS and returns ALL published lessons,
        // including locked ones. We always call it and use results if they contain
        // more lessons than the direct query (RLS may have filtered non-preview lessons).
        try {
          const { data: rpcData, error: rpcError } = await supabase.rpc('get_course_details', {
            p_course_id: id,
            p_locale: lang,
          });

          if (rpcError) {
            console.warn('[CourseDetails] RPC fallback failed:', rpcError.message);
          }

          if (rpcData && !rpcError) {
            const rpcSections: Array<{
              id: string;
              title: string;
              lessons: Array<{
                id: string;
                title: string;
                type: string;
                duration: number;
                is_preview: boolean;
              }>;
            }> = rpcData.sections || [];

            const rpcLessonsCount = rpcSections.reduce((acc, sec) => acc + (sec.lessons?.length || 0), 0);
            const directLessonsCount = directSections.reduce((acc, sec) => acc + sec.lessons.length, 0);

            // Use RPC result if it has more lessons (i.e. it bypassed RLS)
            if (rpcSections.length > 0 && rpcLessonsCount > directLessonsCount) {
              directSections = rpcSections.map((sec, secIdx) => ({
                id: sec.id,
                title_ar: sec.title,
                title_en: sec.title,
                sort_order: secIdx,
                lessons: (sec.lessons || []).map((lesson) => ({
                  id: lesson.id,
                  title_ar: lesson.title,
                  title_en: lesson.title,
                  type: lesson.type || 'video',
                  video_duration: lesson.duration || 0,
                  is_preview: lesson.is_preview || false,
                })),
              }));
            }
          }
        } catch (rpcErr) {
          console.warn('[CourseDetails] RPC call threw:', rpcErr);
        }

        if (directSections.length > 0) {
          setSections(directSections);
          setExpandedSections((prev) =>
            Object.keys(prev).length === 0 ? { [directSections[0].id]: true } : prev
          );
        }

        const { data } = await supabase.auth.getSession();
        const session = data?.session;
        if (session?.user) {
          const { data: enrollData } = await supabase
            .from('enrollments')
            .select('id')
            .eq('user_id', session.user.id)
            .eq('course_id', id)
            .in('status', ['active', 'completed'])
            .maybeSingle();

          if (enrollData) {
            setIsEnrolledLocal(true);
          }
        }
      } catch (err) {
        console.error('Error fetching course details:', err);
      } finally {
        setLoading(false);
      }
    }

    fetchCourseDetails();
  }, [id, lang]);

  const toggleSection = (sectionId: string) => {
    setExpandedSections((prev) => ({
      ...prev,
      [sectionId]: !prev[sectionId],
    }));
  };

  const handleBuyNow = async () => {
    if (!course) return;
    await addToCart(course.id);
    router.push('/cart');
  };

  const handleShare = async () => {
    const url = window.location.href;
    try {
      if (navigator.share) {
        await navigator.share({ title: lang === 'ar' ? course?.title_ar : course?.title_en, url });
      } else {
        await navigator.clipboard.writeText(url);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      }
    } catch {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const ratingBuckets = useMemo(() => {
    const dist = course?.rating_distribution || {};
    const total = course?.rating_count || 0;
    const buckets = [];
    for (let s = 5; s >= 1; s--) {
      const key = String(s);
      const count = dist[key] || 0;
      const pct = total > 0 ? Math.round((count / total) * 100) : 0;
      buckets.push({ stars: s, count, percentage: pct });
    }
    return buckets;
  }, [course?.rating_distribution, course?.rating_count]);

  if (loading) {
    return (
      <div className={styles.loadingState}>
        <div className={styles.spinner}></div>
        <p>{t.loading}</p>
      </div>
    );
  }

  if (!course) {
    return (
      <div className="container text-center py-10">
        <h2>Course Not Found</h2>
      </div>
    );
  }

  const inCart = cart.includes(course.id);
  const basePrice = getBaseCoursePrice(course);
  const effectivePrice = getEffectiveCoursePrice(course);
  const hasDiscount = hasCourseDiscount(course);
  const isEnrolled = isEnrolledLocal || enrolledCourseIds.includes(course.id);
  const isFree = course.is_free;
  const hasMultiplePricing = course.pricing_options && course.pricing_options.length > 0;
  const totalHours = Math.round((course.total_duration || 0) / 60 * 10) / 10;

  const ctaState = isEnrolled
    ? 'continueLearning'
    : isFree
    ? 'getForFree'
    : inCart
    ? 'goToCart'
    : 'addToCart';

  return (
    <div ref={pageRef} className="container fade-in">
      {/* ── Top Hero: image + info card side by side ── */}
      <div className={styles.topHero}>
        {/* Left: media */}
        <div className={`${styles.topMedia} glass`}>
          {course.preview_video_url ? (
            <div className={styles.videoWrapper}>
              <iframe
                src={course.preview_video_url.replace('watch?v=', 'embed/')}
                title="Course Preview"
                frameBorder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className={styles.videoIframe}
              ></iframe>
            </div>
          ) : course.thumbnail_url ? (
            <img src={course.thumbnail_url} alt={course.title_ar} className={styles.courseImg} />
          ) : (
            <div className={styles.imagePlaceholder}>
              <MenuBook fontSize="large" className={styles.placeholderIcon} />
            </div>
          )}
        </div>

        {/* Right: info card */}
        <div className={`${styles.topInfo} glass`}>
          <h1 className={styles.title}>
            {lang === 'ar' ? course.title_ar : course.title_en}
          </h1>
          <p className={styles.subtitle}>
            {lang === 'ar' ? course.subtitle_ar : course.subtitle_en}
          </p>
          <div className={styles.statsRow}>
            <div className={styles.statItem}>
              <Star fontSize="small" className={styles.starIcon} />
              <span>{course.rating ? Number(course.rating).toFixed(1) : '5.0'}</span>
            </div>
            <div className={styles.statItem}>
              <MenuBook fontSize="small" />
              <span>{course.total_lessons || 0} {t.lessonsCount}</span>
            </div>
            <div className={styles.statItem}>
              <Schedule fontSize="small" />
              <span>{Math.round((course.total_duration || 0) / 60 * 10) / 10} {t.hours}</span>
            </div>
          </div>
          <div className={styles.headerActions}>
            <button className={styles.iconActionBtn} onClick={handleShare} type="button">
              <Share fontSize="small" />
              <span>{copied ? t.copied : t.share}</span>
            </button>
            <button className={styles.iconActionBtn} type="button">
              <Flag fontSize="small" />
              <span>{t.report}</span>
            </button>
          </div>
        </div>
      </div>

      {/* ── Price + CTA bar below ── */}
      <div className={`${styles.priceBanner} glass`}>
        <div className={styles.priceBannerLeft}>
          {isFree ? (
            <span className={styles.price}>{t.free}</span>
          ) : hasMultiplePricing ? (
            <div className={styles.pricingOptionsList}>
              {course.pricing_options.map((opt) => (
                <button
                  key={opt.label}
                  type="button"
                  className={`${styles.pricingOptionCard} ${selectedPricingId === opt.label ? styles.pricingOptionSelected : ''}`}
                  onClick={() => setSelectedPricingId(opt.label)}
                >
                  <span className={styles.pricingOptionLabel}>{opt.label}</span>
                  <span className={styles.pricingOptionPrice}>
                    {opt.price === 0 ? (lang === 'ar' ? 'مجاني' : 'Free') : `${opt.price} ${t.egp}`}
                    {opt.originalPrice && opt.originalPrice > opt.price && (
                      <span className={styles.pricingOptionOldPrice}>{opt.originalPrice} {t.egp}</span>
                    )}
                  </span>
                  {opt.duration_days && (
                    <span className={styles.pricingOptionDuration}>
                      <Schedule fontSize="inherit" />
                      {lang === 'ar'
                        ? `مدة الوصول: ${opt.duration_days} يوم`
                        : `Access for ${opt.duration_days} days`}
                    </span>
                  )}
                </button>
              ))}
            </div>
          ) : (
            <div className={styles.prices}>
              {hasDiscount ? (
                <>
                  <span className={styles.price}>{effectivePrice} {t.egp}</span>
                  <span className={styles.oldPrice}>{basePrice} {t.egp}</span>
                </>
              ) : (
                <span className={styles.price}>{effectivePrice} {t.egp}</span>
              )}
            </div>
          )}
        </div>
        <div className={styles.priceBannerActions}>
          {ctaState === 'continueLearning' && (
            <Link href={`/learn/${course.id}`} className={`${styles.primaryBtn} gradient-bg`}>{t.continueLearning}</Link>
          )}
          {ctaState === 'getForFree' && (
            <button onClick={handleBuyNow} className={`${styles.primaryBtn} gradient-bg`}>{lang === 'ar' ? 'احصل عليه مجاناً' : 'Get for Free'}</button>
          )}
          {ctaState === 'goToCart' && (
            <Link href="/cart" className={`${styles.primaryBtn} gradient-bg`}>{lang === 'ar' ? 'الذهاب للسلة' : 'Go to Cart'}</Link>
          )}
          {ctaState === 'addToCart' && (
            <button onClick={() => addToCart(course.id)} className={`${styles.primaryBtn} gradient-bg`}>
              <ShoppingCart fontSize="small" />
              <span>{t.addToCart}</span>
            </button>
          )}
        </div>
      </div>

      <div className={styles.contentGrid}>
        <div className={styles.leftCol}>

          <div className={`${styles.statsGridCard} glass`}>
            <div className={styles.statsGrid}>
              <div className={styles.statsGridItem}>
                <div className={styles.statsGridIconWrap}>
                  <MenuBook fontSize="small" />
                </div>
                <span className={styles.statsGridValue}>{course.total_lessons || 0}</span>
                <span className={styles.statsGridLabel}>{t.lessons}</span>
              </div>
              <div className={styles.statsGridItem}>
                <div className={styles.statsGridIconWrap}>
                  <Schedule fontSize="small" />
                </div>
                <span className={styles.statsGridValue}>{totalHours}</span>
                <span className={styles.statsGridLabel}>{t.hours}</span>
              </div>
              <div className={styles.statsGridItem}>
                <div className={styles.statsGridIconWrap}>
                  <Quiz fontSize="small" />
                </div>
                <span className={styles.statsGridValue}>{course.total_quizzes || 0}</span>
                <span className={styles.statsGridLabel}>{t.quizzes}</span>
              </div>
              <div className={styles.statsGridItem}>
                <div className={styles.statsGridIconWrap}>
                  <CardMembership fontSize="small" />
                </div>
                <span className={styles.statsGridValue}>
                  {course.has_certificate ? (lang === 'ar' ? 'نعم' : 'Yes') : (lang === 'ar' ? 'لا' : 'No')}
                </span>
                <span className={styles.statsGridLabel}>{t.certificate}</span>
              </div>
            </div>
          </div>

          <div className={`${styles.cardSection} glass`}>
            <h2 className={styles.sectionTitle}>{t.courseDetails}</h2>
            <div
              className={styles.description}
              dangerouslySetInnerHTML={{ __html: sanitizeHtml(lang === 'ar' ? course.description_ar : course.description_en) }}
            />
          </div>

          {course.objectives && course.objectives.length > 0 && (
            <div className={`${styles.objectivesCard} glass`}>
              <h2 className={styles.sectionTitle}>{t.objectives}</h2>
              <div className={styles.objectivesGrid}>
                {course.objectives.map((obj, index) => (
                  <div key={index} className={styles.objectiveItem}>
                    <Check fontSize="small" className={styles.checkIcon} />
                    <span>{obj}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className={`${styles.cardSection} glass`}>
            <h2 className={styles.sectionTitle}>{t.curriculum}</h2>
            <div className={styles.sectionsList}>
              {sections.map((section) => {
                const isOpen = !!expandedSections[section.id];
                return (
                  <div key={section.id} className={styles.sectionItem}>
                    <button
                      onClick={() => toggleSection(section.id)}
                      className={styles.sectionTrigger}
                    >
                      <span className={styles.sectionTitleText}>
                        {lang === 'ar' ? section.title_ar : section.title_en}
                      </span>
                      <div className={styles.sectionMeta}>
                        <span className={styles.lessonsCountBadge}>
                          {section.lessons.length} {t.lessonsCount}
                        </span>
                        {isOpen ? <ExpandLess fontSize="small" /> : <ExpandMore fontSize="small" />}
                      </div>
                    </button>

                    {isOpen && (
                      <div className={styles.lessonsList}>
                        {section.lessons.map((lesson) => (
                          <div key={lesson.id} className={styles.lessonItem}>
                            <div className={styles.lessonInfo}>
                              <span className={`${styles.lessonTypeIcon} ${!isEnrolled && !lesson.is_preview ? styles.lockedIcon : ''}`}>
                                {!isEnrolled && !lesson.is_preview ? (
                                  <Lock fontSize="small" />
                                ) : (
                                  <LessonTypeIcon type={lesson.type} />
                                )}
                              </span>
                              <span className={styles.lessonTitleText}>
                                {lang === 'ar' ? lesson.title_ar : lesson.title_en}
                              </span>
                            </div>
                            <div className={styles.lessonMeta}>
                              {lesson.is_preview && (
                                <span className={styles.previewTag}>
                                  {lang === 'ar' ? 'معاينة' : 'Preview'}
                                </span>
                              )}
                              {lesson.video_duration > 0 && (
                                <span className={styles.lessonDuration}>
                                  {Math.floor(lesson.video_duration / 60)}:
                                  {String(lesson.video_duration % 60).padStart(2, '0')}
                                </span>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {course.rating_count > 0 && (
            <div className={`${styles.cardSection} glass`}>
              <h2 className={styles.sectionTitle}>
                {lang === 'ar' ? 'توزيع التقييمات' : 'Rating Distribution'}
              </h2>
              <div className={styles.ratingDistSummary}>
                <div className={styles.ratingBigScore}>
                  <span className={styles.ratingBigNumber}>
                    {course.rating ? Number(course.rating).toFixed(1) : '5.0'}
                  </span>
                  <span className={styles.ratingOutOf}>/5.0</span>
                </div>
                <span className={styles.ratingTotalCount}>
                  {course.rating_count} {lang === 'ar' ? 'تقييم' : 'ratings'}
                </span>
              </div>
              <RatingDistribution buckets={ratingBuckets} />
            </div>
          )}

          <div className={`${styles.cardSection} glass`}>
            <ReviewsSection courseId={id as string} isEnrolled={isEnrolled} />
          </div>
        </div>
      </div>

      {hasMultiplePricing && (
        <PricingOptionsSheet
          open={showPricingSheet}
          onClose={() => setShowPricingSheet(false)}
          options={course.pricing_options}
          selectedId={selectedPricingId}
          onSelect={setSelectedPricingId}
        />
      )}
    </div>
  );
}
