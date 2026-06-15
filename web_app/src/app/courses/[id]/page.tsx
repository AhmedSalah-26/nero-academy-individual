'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { ReviewsSection } from '../../../components/ReviewsSection';
import { Play, Check, ChevronDown, ChevronUp, Clock, BookOpen, Star, ShoppingCart } from 'lucide-react';
import styles from './page.module.css';

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
  currency: string;
  total_lessons: number;
  total_duration: number;
  enrolled_count: number;
  rating: number;
  requirements: string[];
  objectives: string[];
  target_audience: string[];
}

export default function CourseDetailsPage() {
  const { id } = useParams();
  const router = useRouter();
  const { lang, t, cart, addToCart, enrolledCourseIds } = useApp();
  
  const [course, setCourse] = useState<CourseDetails | null>(null);
  const [sections, setSections] = useState<Section[]>([]);
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [isEnrolledLocal, setIsEnrolledLocal] = useState(false);

  useEffect(() => {
    if (!id) return;

    async function fetchCourseDetails() {
      try {
        // Fetch course
        const { data: courseData, error: courseError } = await supabase
          .from('courses')
          .select('*')
          .eq('id', id)
          .single();

        if (courseData && !courseError) {
          // Normalize JSONB arrays
          const parsedCourse = {
            ...courseData,
            requirements: typeof courseData.requirements === 'string' ? JSON.parse(courseData.requirements) : (courseData.requirements || []),
            objectives: typeof courseData.objectives === 'string' ? JSON.parse(courseData.objectives) : (courseData.objectives || []),
            target_audience: typeof courseData.target_audience === 'string' ? JSON.parse(courseData.target_audience) : (courseData.target_audience || []),
          };
          setCourse(parsedCourse as CourseDetails);
        }

        // Fetch sections
        const { data: sectionsData, error: sectionsError } = await supabase
          .from('sections')
          .select('*')
          .eq('course_id', id)
          .eq('is_published', true)
          .order('sort_order', { ascending: true });

        if (sectionsData && !sectionsError) {
          const fetchedSections = sectionsData as Section[];
          
          // Fetch lessons for each section
          const sectionsWithLessons = await Promise.all(
            fetchedSections.map(async (sec) => {
              const { data: lessonsData } = await supabase
                .from('lessons')
                .select('id, title_ar, title_en, type, video_duration, is_preview')
                .eq('section_id', sec.id)
                .eq('is_published', true)
                .order('sort_order', { ascending: true });
              
              return {
                ...sec,
                lessons: (lessonsData || []) as Lesson[],
              };
            })
          );

          setSections(sectionsWithLessons);
          
          // Expand first section by default
          if (sectionsWithLessons.length > 0) {
            setExpandedSections({ [sectionsWithLessons[0].id]: true });
          }
        }

        // Check if user is enrolled
        const { data: { session } } = await supabase.auth.getSession();
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
  }, [id]);

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
  const hasDiscount = course.discount_price && course.discount_price < course.price;
  // Use both local DB check and global context for instant UI updates
  const isEnrolled = isEnrolledLocal || enrolledCourseIds.includes(course.id);
  
  return (
    <div className="container fade-in">
      <div className={styles.courseHeader}>
        <div className={styles.headerMain}>
          <h1 className={styles.title}>
            {lang === 'ar' ? course.title_ar : course.title_en}
          </h1>
          <p className={styles.subtitle}>
            {lang === 'ar' ? course.subtitle_ar : course.subtitle_en}
          </p>

          <div className={styles.statsRow}>
            <div className={styles.statItem}>
              <Star size={16} className={styles.starIcon} />
              <span>{course.rating ? Number(course.rating).toFixed(1) : '5.0'}</span>
            </div>
            <div className={styles.statItem}>
              <BookOpen size={16} />
              <span>{course.total_lessons || 0} {t.lessonsCount}</span>
            </div>
            <div className={styles.statItem}>
              <Clock size={16} />
              <span>{course.total_duration || 0} {t.durationMinutes}</span>
            </div>
          </div>
        </div>
      </div>

      <div className={styles.contentGrid}>
        <div className={styles.leftCol}>
          {/* Video Preview / Image */}
          <div className={`${styles.mediaSection} glass`}>
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
                <BookOpen size={64} className={styles.placeholderIcon} />
              </div>
            )}
          </div>

          {/* Description */}
          <div className={`${styles.cardSection} glass`}>
            <h2 className={styles.sectionTitle}>{t.courseDetails}</h2>
            <div 
              className={styles.description}
              dangerouslySetInnerHTML={{ __html: lang === 'ar' ? course.description_ar : course.description_en }}
            />
          </div>

          {/* Objectives */}
          {course.objectives && course.objectives.length > 0 && (
            <div className={`${styles.cardSection} glass`}>
              <h2 className={styles.sectionTitle}>{t.objectives}</h2>
              <div className={styles.objectivesGrid}>
                {course.objectives.map((obj, index) => (
                  <div key={index} className={styles.objectiveItem}>
                    <Check size={18} className={styles.checkIcon} />
                    <span>{obj}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Curriculum */}
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
                        {isOpen ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
                      </div>
                    </button>

                    {isOpen && (
                      <div className={styles.lessonsList}>
                        {section.lessons.map((lesson) => (
                          <div key={lesson.id} className={styles.lessonItem}>
                            <div className={styles.lessonInfo}>
                              <Play size={14} className={styles.playIcon} />
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

          {/* Reviews */}
          <div className={`${styles.cardSection} glass`}>
            <ReviewsSection courseId={id as string} isEnrolled={isEnrolled} />
          </div>
        </div>

        {/* Sidebar panel */}
        <div className={styles.rightCol}>
          <div className={`${styles.sidebarCard} glass`}>
            <div className={styles.pricingContainer}>
              {course.is_free ? (
                <span className={styles.price}>{t.free}</span>
              ) : (
                <div className={styles.prices}>
                  {hasDiscount ? (
                    <>
                      <span className={styles.price}>
                        {course.discount_price} {t.egp}
                      </span>
                      <span className={styles.oldPrice}>
                        {course.price} {t.egp}
                      </span>
                    </>
                  ) : (
                    <span className={styles.price}>
                      {course.price} {t.egp}
                    </span>
                  )}
                </div>
              )}
            </div>

            <div className={styles.sidebarActions}>
              {isEnrolled ? (
                <Link href={`/learn/${course.id}`} className={`${styles.primaryBtn} gradient-bg`}>
                  {lang === 'ar' ? 'ابدأ التعلم الآن' : 'Start Learning Now'}
                </Link>
              ) : (
                <>
                  <button 
                    onClick={() => addToCart(course.id)} 
                    disabled={inCart}
                    className={`${styles.cartBtn} ${inCart ? styles.disabledBtn : ''}`}
                  >
                    <ShoppingCart size={18} />
                    <span>{inCart ? t.addedToCart : t.addToCart}</span>
                  </button>
                  <button onClick={handleBuyNow} className={`${styles.primaryBtn} gradient-bg`}>
                    {t.buyNow}
                  </button>
                </>
              )}
            </div>

            <div className={styles.sidebarSpecs}>
              {course.requirements && course.requirements.length > 0 && (
                <div className={styles.specGroup}>
                  <h4 className={styles.specTitle}>{t.requirements}</h4>
                  <ul className={styles.specList}>
                    {course.requirements.map((req, i) => (
                      <li key={i}>{req}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
