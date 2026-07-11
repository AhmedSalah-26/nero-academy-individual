'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowLeft,
  ArrowRight,
  Science,
  MenuBook,
  Check,
  ChevronLeft,
  ChevronRight,
  Schedule,
  Favorite,
  Help as HelpIcon,
  EditNote,
  PlayArrow,
  Add,
  Search,
  Security,
  AutoAwesome,
  Star,
  EmojiEvents,
  Groups,
  VideoLibrary,
  Assessment,
} from '@mui/icons-material';
import { useApp } from '../context/AppContext';
import { supabase } from '../lib/supabaseClient';
import { getBaseCoursePrice, getEffectiveCoursePrice, hasCourseDiscount } from '../lib/pricing';
import { HomeScreen } from '../components/home';
import styles from './page.module.css';

interface Course {
  id: string;
  title_ar: string;
  title_en: string;
  subtitle_ar: string;
  subtitle_en: string;
  thumbnail_url: string;
  price: number;
  discount_price: number;
  is_free: boolean;
  pricing_options?: unknown;
  total_lessons: number;
  total_duration: number;
  enrolled_count: number;
  rating: number;
}

const testimonials = [
  {
    name: 'سلمى محمد',
    grade: 'الثانوية العامة',
    text: 'طريقة الشرح خلتني أفهم الفكرة قبل ما أحفظها، وحلي في الامتحانات اتحسن جدًا.',
  },
  {
    name: 'عمر خالد',
    grade: 'الصف الثالث الثانوي',
    text: 'المنصة منظمة، وكل درس قصير وواضح ومعاه أسئلة تثبت المعلومة مباشرة.',
  },
  {
    name: 'مريم أحمد',
    grade: 'الصف الثاني الثانوي',
    text: 'أكتر حاجة عجبتني المتابعة والرد على الأسئلة. بقيت داخلة الامتحان وأنا مطمنة.',
  },
];

const stats = [
  { icon: Groups, value: '+15K', label_ar: 'طالب كيمياء سجل معنا', label_en: 'chemistry students joined' },
  { icon: Schedule, value: '+200', label_ar: 'ساعة محتوى', label_en: 'content hours' },
  { icon: Star, value: '+98%', label_ar: 'نتائج مميزة', label_en: 'great results', color: 'var(--warning)' },
  { icon: EmojiEvents, value: '+10', label_ar: 'سنوات خبرة', label_en: 'years experience' },
];

const features = [
  { icon: VideoLibrary, title_ar: 'شرح بسيط ومركز', title_en: 'Simple & focused lessons', desc_ar: 'نفهم الفكرة من أساسها بأمثلة واضحة وتطبيق مباشر.', desc_en: 'Understand concepts from the ground up with clear examples.' },
  { icon: EditNote, title_ar: 'خطة مذاكرة منظمة', title_en: 'Organized study plan', desc_ar: 'جدول واضح يساعدك تخلص المنهج من غير تشتت.', desc_en: 'A clear schedule to finish the curriculum without distraction.' },
  { icon: Assessment, title_ar: 'نماذج امتحانات', title_en: 'Exam models', desc_ar: 'اختبارات بنفس النظام عشان تدخل الامتحان جاهز.', desc_en: 'Tests in the same format so you enter the exam prepared.' },
  { icon: Security, title_ar: 'متابعة وتقييم مستمر', title_en: 'Continuous tracking', desc_ar: 'تقارير دورية توضح مستواك ونقاط التحسن.', desc_en: 'Regular reports showing your level and improvement areas.' },
  { icon: HelpIcon, title_ar: 'تفاعل وإجابة للأسئلة', title_en: 'Q&A interaction', desc_ar: 'اسأل في أي جزئية وخد الإجابة التي توضحها.', desc_en: 'Ask about any part and get clarifying answers.' },
  { icon: Science, title_ar: 'مراجعات ليلة الامتحان', title_en: 'Last-minute reviews', desc_ar: 'ملخصات مركزة لأهم الأفكار والنقاط المتوقعة.', desc_en: 'Focused summaries of key concepts and expected points.' },
];

export default function HomePage() {
  const {
    lang,
    user,
    cart,
    wishlist,
    addToCart,
    addToWishlist,
    removeFromWishlist,
    enrolledCourseIds,
  } = useApp();
  const [courses, setCourses] = useState<Course[]>([]);
  const [loadingCourses, setLoadingCourses] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [visibleSections, setVisibleSections] = useState<Set<string>>(new Set());
  const sectionRefs = useRef<Map<string, HTMLElement | null>>(new Map());

  const setSectionRef = useCallback((id: string, el: HTMLElement | null) => {
    sectionRefs.current.set(id, el);
  }, []);

  useEffect(() => {
    async function fetchCourses() {
      try {
        const { data, error } = await supabase
          .from('courses')
          .select('*')
          .eq('is_published', true)
          .eq('is_active', true)
          .limit(6);

        if (!error) setCourses((data || []) as Course[]);
      } finally {
        setLoadingCourses(false);
      }
    }

    fetchCourses();
  }, []);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.getAttribute('data-section-id');
            if (id) {
              setVisibleSections((prev) => new Set([...prev, id]));
            }
          }
        });
      },
      { threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
    );

    sectionRefs.current.forEach((el) => {
      if (el) observer.observe(el);
    });

    return () => observer.disconnect();
  }, []);

  const normalizedQuery = searchQuery.trim().toLowerCase();
  const filteredCourses = courses.filter((course) => {
    const title = lang === 'ar' ? course.title_ar : course.title_en;
    const subtitle = lang === 'ar' ? course.subtitle_ar : course.subtitle_en;
    return (
      !normalizedQuery ||
      title?.toLowerCase().includes(normalizedQuery) ||
      subtitle?.toLowerCase().includes(normalizedQuery)
    );
  });

  const arrow = lang === 'ar' ? <ArrowLeft fontSize="small" /> : <ArrowRight fontSize="small" />;

  if (user) return <HomeScreen />;

  return (
    <div className={styles.page}>
      {/* Hero Section */}
      <section className={styles.hero}>
        <div className={styles.heroBg}>
          <div className={styles.heroBgGradient} />
          <div className={styles.heroBgGrid} />
        </div>
        
        <div className={styles.heroContent}>
          <div className={`${styles.heroText} animate-fade-up`}>
            <div className={styles.heroBadge}>
              <AutoAwesome fontSize="small" />
              <span>{lang === 'ar' ? 'كيمياء مفهومة، خطوة بخطوة' : 'Chemistry, clearly explained'}</span>
            </div>
            
            <h1>
              {lang === 'ar' ? (
                <>
                  اوعي تنسي.<br />
                  <span>تزود معرفتك بالكيمياء.</span>
                </>
              ) : (
                <>
                  Never forget to boost your chemistry knowledge.
                </>
              )}
            </h1>
            
            <p>
              {lang === 'ar'
                ? 'شرح كيمياء بسيط، تدريب ذكي، ومراجعات مركزة تساعدك تدخل الامتحان وأنت واثق.'
                : 'Clear lessons, smart practice, and steady support to help you enter every exam with confidence.'}
            </p>
            
            <div className={styles.heroButtons}>
              <Link href={user ? '/my-learning' : '/login'} className={styles.primaryBtn}>
                <PlayArrow fontSize="inherit" />
                {lang === 'ar' ? 'ابدأ التعلم الآن' : 'Start learning'}
              </Link>
              <a href="#courses" className={styles.secondaryBtn}>
                {lang === 'ar' ? 'استكشف الكورسات' : 'Explore courses'}
                {arrow}
              </a>
            </div>
          </div>

          <div className={styles.heroVisual}>
            <div className={styles.visualOrb} />
            <div className={styles.visualRing} />
            <div className={styles.teacherContainer}>
              <Image
                src="/ahmed-yahia-hero.png"
                alt={lang === 'ar' ? 'مستر أحمد يحيى' : 'Ahmed Yahia'}
                fill
                priority
                sizes="(max-width: 760px) 78vw, 520px"
                className={styles.teacherImg}
              />
            </div>
            
            <div className={`${styles.floatingCard} ${styles.floatingCard1}`}>
              <div className={styles.cardIcon}><VideoLibrary fontSize="small" /></div>
              <div>
                <strong>{lang === 'ar' ? '+150 درس' : '+150 Lessons'}</strong>
                <small>{lang === 'ar' ? 'محتوى تفاعلي' : 'Interactive content'}</small>
              </div>
            </div>
            
            <div className={`${styles.floatingCard} ${styles.floatingCard2}`}>
              <div className={styles.cardIcon}><Star fontSize="small" sx={{ color: 'var(--warning)' }} /></div>
              <div>
                <strong>{lang === 'ar' ? '4.9/5' : '4.9/5'}</strong>
                <small>{lang === 'ar' ? 'تقييم الطلاب' : 'Student rating'}</small>
              </div>
            </div>
          </div>
        </div>

        <div className={`${styles.heroStats} animate-fade-up`}>
          {stats.map((stat, index) => (
            <div key={index} className={styles.statItem}>
              <div className={styles.statIcon}>
                <stat.icon fontSize="small" sx={stat.color ? { color: stat.color } : undefined} />
              </div>
              <div className={styles.statContent}>
                <strong>{stat.value}</strong>
                <small>{lang === 'ar' ? stat.label_ar : stat.label_en}</small>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Courses Section */}
      <section id="courses" className={`${styles.section} ${styles.coursesSection}`} data-section-id="courses">
        <div className={styles.sectionHeader}>
          <div className={styles.sectionLabel}>
            <span>{lang === 'ar' ? 'ابدأ من مستواك' : 'Start at your level'}</span>
          </div>
          <h2>{lang === 'ar' ? 'الكورسات المتاحة' : 'Available courses'}</h2>
          <p>{lang === 'ar' ? 'محتوى مرتب، شرح مركز، وتدريب بعد كل فكرة.' : 'Structured content, focused teaching, and practice after every idea.'}</p>
        </div>

        <div className={styles.searchWrapper}>
          <Search fontSize="small" className={styles.searchIcon} />
          <input
            type="search"
            placeholder={lang === 'ar' ? 'ابحث باسم الكورس...' : 'Search courses...'}
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
          />
          <kbd>/</kbd>
        </div>

        {loadingCourses ? (
          <div className={styles.loadingState}>
            <div className={styles.spinner} />
            <span>{lang === 'ar' ? 'جاري تجهيز الكورسات...' : 'Preparing courses...'}</span>
          </div>
        ) : filteredCourses.length === 0 ? (
          <div className={styles.emptyState}>
            <MenuBook fontSize="large" />
            <span>{lang === 'ar' ? 'لا توجد كورسات مطابقة حاليًا.' : 'No matching courses yet.'}</span>
          </div>
        ) : (
          <div className={styles.coursesGrid}>
            {filteredCourses.map((course, index) => {
              const inCart = cart.includes(course.id);
              const isWishlisted = wishlist.includes(course.id);
              const isEnrolled = enrolledCourseIds.includes(course.id);
              const basePrice = getBaseCoursePrice(course);
              const effectivePrice = getEffectiveCoursePrice(course);
              const hasDiscount = hasCourseDiscount(course);
              const title = lang === 'ar' ? course.title_ar : course.title_en;
              const subtitle = lang === 'ar' ? course.subtitle_ar : course.subtitle_en;

              return (
                <Link href={isEnrolled ? `/learn/${course.id}` : `/courses/${course.id}`} className={styles.courseCard} key={course.id}>
                  <div className={styles.courseImage}>
                    {course.thumbnail_url ? (
                      <img src={course.thumbnail_url} alt={title} onError={(event) => { event.currentTarget.style.display = 'none'; }} />
                    ) : (
                      <div className={styles.coursePlaceholder}>
                        <Science fontSize="large" />
                      </div>
                    )}
                    <div className={styles.courseBadge}>0{index + 1}</div>
                    <button
                      type="button"
                      className={`${styles.wishlistBtn} ${isWishlisted ? styles.wishlistActive : ''}`}
                      onClick={(e) => { e.preventDefault(); e.stopPropagation(); isWishlisted ? removeFromWishlist(course.id) : addToWishlist(course.id); }}
                      aria-label={isWishlisted ? 'Remove from wishlist' : 'Add to wishlist'}
                    >
                      <Favorite fontSize="small" sx={{ color: isWishlisted ? 'var(--error)' : 'var(--text-muted)' }} />
                    </button>
                  </div>
                  
                  <div className={styles.courseContent}>
                    <div className={styles.courseMeta}>
                      <span><MenuBook fontSize="small" /> {course.total_lessons || 0}</span>
                      <span><Schedule fontSize="small" /> {course.total_duration || 0}min</span>
                    </div>
                    <h3>{title}</h3>
                    <p>{subtitle}</p>
                    
                    <div className={styles.courseFooter}>
                      <div className={styles.coursePrice}>
                        {course.is_free ? (
                          <strong>{lang === 'ar' ? 'مجاني' : 'Free'}</strong>
                        ) : (
                          <>
                            <strong>{effectivePrice} {lang === 'ar' ? 'ج.م' : 'EGP'}</strong>
                            {hasDiscount && <del>{basePrice}</del>}
                          </>
                        )}
                      </div>
                      {isEnrolled ? (
                        <div className={styles.actionBtn}>
                          <PlayArrow fontSize="inherit" />
                        </div>
                      ) : (
                        <button
                          type="button"
                          className={styles.actionBtn}
                          onClick={(e) => { e.preventDefault(); e.stopPropagation(); addToCart(course.id); }}
                          disabled={inCart}
                        >
                          {inCart ? <Check fontSize="small" /> : <Add fontSize="small" />}
                        </button>
                      )}
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        )}

        <div className={styles.sectionFooter}>
          <Link href="/search" className={styles.viewAllBtn}>
            {lang === 'ar' ? 'عرض كل الكورسات' : 'View all courses'}
            {arrow}
          </Link>
        </div>
      </section>

      {/* Grades Section */}
      <section className={`${styles.section} ${styles.gradesSection}`} data-section-id="grades">
        <div className={styles.gradesContent}>
          <div className={styles.sectionLabel}>
            <span>{lang === 'ar' ? 'اختار مرحلتك' : 'Choose your grade'}</span>
          </div>
          <h2>{lang === 'ar' ? 'السنوات الدراسية' : 'School years'}</h2>
          <p>{lang === 'ar' ? 'كل محتوى سنتك في مكان واحد، مرتب من أول درس لآخر مراجعة.' : 'Everything for your school year, organized from the first lesson to final revision.'}</p>
          <Link href="/search" className={styles.primaryBtn}>
            {lang === 'ar' ? 'شاهد كل الكورسات' : 'See all courses'}
            {arrow}
          </Link>
        </div>

        <div className={styles.gradesGrid}>
          {[
            [
              '01',
              lang === 'ar' ? 'الصف الأول الثانوي' : '1st Secondary Grade',
              lang === 'ar' ? 'علوم متكاملة وتأسيس قوي' : 'Integrated Science & Strong Foundation',
            ],
            [
              '02',
              lang === 'ar' ? 'الصف الثاني الثانوي' : '2nd Secondary Grade',
              lang === 'ar' ? 'شرح المنهج وتدريب متدرج' : 'Curriculum Explanation & Gradual Practice',
            ],
            [
              '03',
              lang === 'ar' ? 'الصف الثالث الثانوي' : '3rd Secondary Grade',
              lang === 'ar' ? 'شرح ومراجعات وليالي الامتحان' : 'Explanations, Revisions & Exam Nights',
            ],
          ].map(([number, title, description], idx) => (
            <Link href="/search" className={styles.gradeCard} key={number}>
              <div className={styles.gradeNumber}>{number}</div>
              <div className={styles.gradeContent}>
                <h3>{title}</h3>
                <p>{description}</p>
              </div>
              <div className={styles.gradeArrow}>{arrow}</div>
            </Link>
          ))}
        </div>
      </section>

      {/* Features Section */}
      <section id="method" className={`${styles.section} ${styles.featuresSection}`} data-section-id="features">
        <div className={styles.featuresHeader}>
          <div className={styles.sectionLabel}>
            <span>{lang === 'ar' ? 'ليه تختار منصتنا؟' : 'Why choose us?'}</span>
          </div>
          <h2>{lang === 'ar' ? 'إيه اللي هتلاقيه على المنصة؟' : 'What will you find on the platform?'}</h2>
          <p>{lang === 'ar' ? 'منظومة مذاكرة متكاملة تساعدك تفهم وتطبق وتتابع مستواك.' : 'A complete study system that helps you understand, practice, and track progress.'}</p>
        </div>

        <div className={styles.featuresGrid}>
          {features.map((feature, idx) => (
            <div className={styles.featureCard} key={idx}>
              <div className={styles.featureIcon}>
                <feature.icon fontSize="medium" />
              </div>
              <h3>{lang === 'ar' ? feature.title_ar : feature.title_en}</h3>
              <p>{lang === 'ar' ? feature.desc_ar : feature.desc_en}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Testimonials Section */}
      <section id="reviews" className={`${styles.section} ${styles.testimonialsSection}`} data-section-id="testimonials">
        <div className={styles.sectionHeader}>
          <div className={styles.sectionLabel}>
            <span>{lang === 'ar' ? 'من قلب الفصل' : 'From the classroom'}</span>
          </div>
          <h2>{lang === 'ar' ? 'طلاب فهموا، فتفوقوا' : 'Students who understood, then excelled'}</h2>
        </div>

        <div className={styles.testimonialsGrid}>
          {testimonials.map((review, index) => (
            <article key={review.name} className={styles.testimonialCard}>
              <div className={styles.testimonialHeader}>
                <div className={styles.testimonialAvatar}>{review.name.charAt(0)}</div>
                <div className={styles.testimonialInfo}>
                  <h4>{review.name}</h4>
                  <span>{review.grade}</span>
                </div>
                <div className={styles.testimonialNumber}>0{index + 1}</div>
              </div>
              <div className={styles.testimonialStars}>
                {Array.from({ length: 5 }).map((_, star) => (
                  <Star key={star} fontSize="small" sx={{ color: 'var(--warning)' }} />
                ))}
              </div>
              <p>"{review.text}"</p>
            </article>
          ))}
        </div>
      </section>

      {/* CTA Section */}
      <section className={styles.ctaSection}>
        <div className={styles.ctaContent}>
          <div className={styles.ctaBadge}>
            <Groups fontSize="small" />
            <span>{lang === 'ar' ? 'انضم لطلابنا اليوم' : 'Join our students today'}</span>
          </div>
          <h2>{lang === 'ar' ? 'جاهز تخلي الكيمياء أسهل مادة عندك؟' : 'Ready to make chemistry your easiest subject?'}</h2>
          <Link href={user ? '/my-learning' : '/login'} className={styles.ctaBtn}>
            {lang === 'ar' ? 'ابدأ مجانًا' : 'Start for free'}
            {arrow}
          </Link>
        </div>
      </section>
    </div>
  );
}
