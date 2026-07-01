'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowLeft,
  ArrowRight,
  Atom,
  Award,
  BookOpen,
  Check,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Heart,
  MessageCircleQuestion,
  NotebookPen,
  Play,
  Plus,
  Search,
  ShieldCheck,
  Sparkles,
  Star,
  Trophy,
  Users,
  Video,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { supabase } from '../lib/supabaseClient';
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

  const arrow = lang === 'ar' ? <ArrowLeft size={18} /> : <ArrowRight size={18} />;

  if (user) return <HomeScreen />;

  return (
    <div className={styles.page}>
      <section className={styles.hero}>
        <div className={styles.heroCopy}>
          <div className={styles.eyebrow}>
            <Sparkles size={16} />
            {lang === 'ar' ? 'كيمياء مفهومة، خطوة بخطوة' : 'Chemistry, clearly explained'}
          </div>
          <h1>
            {lang === 'ar' ? (
              <>
                افهم الكيمياء.
                <span>حقق الدرجة.</span>
              </>
            ) : (
              <>
                Understand chemistry.
                <span>Earn the grade.</span>
              </>
            )}
          </h1>
          <p>
            {lang === 'ar'
              ? 'شرح بسيط، تدريب ذكي، ومتابعة مستمرة تساعدك تدخل الامتحان وأنت واثق.'
              : 'Clear lessons, smart practice, and steady support to help you enter every exam with confidence.'}
          </p>
          <div className={styles.heroActions}>
            <Link href={user ? '/my-learning' : '/login'} className={styles.primaryButton}>
              <Play size={17} fill="currentColor" />
              {lang === 'ar' ? 'ابدأ التعلم الآن' : 'Start learning'}
            </Link>
            <a href="#courses" className={styles.textButton}>
              {lang === 'ar' ? 'استكشف الكورسات' : 'Explore courses'}
              {arrow}
            </a>
          </div>
          <p className={styles.teacherNote}>{lang === 'ar' ? 'د/ أحمد الشيخ • مدرس الكيمياء للمرحلة الثانوية' : 'Dr. Ahmed El-Sheikh • High school chemistry teacher'}</p>
        </div>

        <div className={styles.heroVisual}>
          <div className={styles.teacherHalo} />
          <div className={styles.teacherFrame}>
            <Image
              src="/chemistry-teacher-v2.png"
              alt={lang === 'ar' ? 'مدرس الكيمياء أحمد الشيخ' : 'Chemistry teacher Ahmed El-Sheikh'}
              fill
              priority
              sizes="(max-width: 760px) 78vw, 520px"
              className={styles.teacherImage}
            />
          </div>
          <div className={styles.teacherBadge}>
            <span><Award size={22} /></span>
            <div>
              <strong>{lang === 'ar' ? 'مدرس الكيمياء للمرحلة الثانوية' : 'High school chemistry teacher'}</strong>
              <small>{lang === 'ar' ? 'خبرة أكثر من 10 سنوات' : 'More than 10 years of experience'}</small>
            </div>
          </div>
        </div>

        <div className={styles.heroStats}>
          <div><span><Users size={24} /></span><strong>+15K</strong><small>{lang === 'ar' ? 'طالب سجل معنا' : 'students joined'}</small></div>
          <div><span><Clock3 size={24} /></span><strong>+200</strong><small>{lang === 'ar' ? 'ساعة محتوى' : 'content hours'}</small></div>
          <div><span><Star size={24} /></span><strong>+98%</strong><small>{lang === 'ar' ? 'نتائج مميزة' : 'great results'}</small></div>
          <div><span><Award size={24} /></span><strong>+10</strong><small>{lang === 'ar' ? 'سنوات خبرة' : 'years experience'}</small></div>
        </div>
      </section>

      <section id="courses" className={styles.section}>
        <div className={styles.sectionHeading}>
          <div>
            <span>{lang === 'ar' ? 'ابدأ من مستواك' : 'Start at your level'}</span>
            <h2>{lang === 'ar' ? 'الكورسات المتاحة' : 'Available courses'}</h2>
            <p>{lang === 'ar' ? 'محتوى مرتب، شرح مركز، وتدريب بعد كل فكرة.' : 'Structured content, focused teaching, and practice after every idea.'}</p>
          </div>
          <Link href="/search" className={styles.outlineButton}>
            {lang === 'ar' ? 'عرض كل الكورسات' : 'View all courses'}
            {arrow}
          </Link>
        </div>

        <label className={styles.searchBox}>
          <Search size={19} />
          <input
            type="search"
            placeholder={lang === 'ar' ? 'ابحث باسم الكورس...' : 'Search courses...'}
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
          />
          <kbd>/</kbd>
        </label>

        {loadingCourses ? (
          <div className={styles.emptyState}>{lang === 'ar' ? 'جاري تجهيز الكورسات...' : 'Preparing courses...'}</div>
        ) : filteredCourses.length === 0 ? (
          <div className={styles.emptyState}>
            <BookOpen size={28} />
            {lang === 'ar' ? 'لا توجد كورسات مطابقة حاليًا.' : 'No matching courses yet.'}
          </div>
        ) : (
          <div className={styles.courseGrid}>
            {filteredCourses.map((course, index) => {
              const inCart = cart.includes(course.id);
              const isWishlisted = wishlist.includes(course.id);
              const isEnrolled = enrolledCourseIds.includes(course.id);
              const hasDiscount = course.discount_price > 0 && course.discount_price < course.price;
              const title = lang === 'ar' ? course.title_ar : course.title_en;
              const subtitle = lang === 'ar' ? course.subtitle_ar : course.subtitle_en;

              return (
                <article className={styles.courseCard} key={course.id}>
                  <div className={styles.courseMedia}>
                    {course.thumbnail_url ? (
                      <img src={course.thumbnail_url} alt={title} onError={(event) => { event.currentTarget.style.display = 'none'; }} />
                    ) : (
                      <div className={styles.coursePlaceholder}><Atom size={48} /></div>
                    )}
                    <span className={styles.courseNumber}>0{index + 1}</span>
                    <button
                      type="button"
                      className={`${styles.favoriteButton} ${isWishlisted ? styles.favoriteActive : ''}`}
                      onClick={() => isWishlisted ? removeFromWishlist(course.id) : addToWishlist(course.id)}
                      aria-label={isWishlisted ? 'Remove from wishlist' : 'Add to wishlist'}
                    >
                      <Heart size={18} fill={isWishlisted ? 'currentColor' : 'none'} />
                    </button>
                  </div>
                  <div className={styles.courseBody}>
                    <div className={styles.courseMeta}>
                      <span><BookOpen size={14} /> {course.total_lessons || 0} {lang === 'ar' ? 'درس' : 'lessons'}</span>
                      <span><Clock3 size={14} /> {course.total_duration || 0} {lang === 'ar' ? 'دقيقة' : 'min'}</span>
                    </div>
                    <h3>{title}</h3>
                    <p>{subtitle}</p>
                    <div className={styles.courseFooter}>
                      <div className={styles.price}>
                        {course.is_free ? (
                          <strong>{lang === 'ar' ? 'مجاني' : 'Free'}</strong>
                        ) : (
                          <>
                            <strong>{hasDiscount ? course.discount_price : course.price} {lang === 'ar' ? 'ج.م' : 'EGP'}</strong>
                            {hasDiscount && <del>{course.price} {lang === 'ar' ? 'ج.م' : 'EGP'}</del>}
                          </>
                        )}
                      </div>
                      {isEnrolled ? (
                        <Link href={`/learn/${course.id}`} className={styles.cardAction}>
                          <Play size={16} fill="currentColor" />
                        </Link>
                      ) : (
                        <button className={styles.cardAction} onClick={() => addToCart(course.id)} disabled={inCart}>
                          {inCart ? <Check size={17} /> : <Plus size={17} />}
                        </button>
                      )}
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </section>

      <section className={`${styles.section} ${styles.gradesSection}`}>
        <div className={styles.gradesCopy}>
          <span>{lang === 'ar' ? 'اختار مرحلتك' : 'Choose your grade'}</span>
          <h2>{lang === 'ar' ? 'السنوات الدراسية' : 'School years'}</h2>
          <p>{lang === 'ar' ? 'كل محتوى سنتك في مكان واحد، مرتب من أول درس لآخر مراجعة.' : 'Everything for your school year, organized from the first lesson to final revision.'}</p>
          <Link href="/search" className={styles.primaryButton}>{lang === 'ar' ? 'شاهد كل الكورسات' : 'See all courses'} {arrow}</Link>
        </div>
        <div className={styles.gradeList}>
          {[
            ['01', 'الصف الأول الثانوي', 'علوم متكاملة وتأسيس قوي'],
            ['02', 'الصف الثاني الثانوي', 'شرح المنهج وتدريب متدرج'],
            ['03', 'الصف الثالث الثانوي', 'شرح ومراجعات وليالي الامتحان'],
          ].map(([number, title, description]) => (
            <Link href="/search" className={styles.gradeItem} key={number}>
              <b>{number}</b><div><h3>{title}</h3><p>{description}</p></div>{arrow}
            </Link>
          ))}
        </div>
      </section>

      <section id="method" className={`${styles.section} ${styles.journey}`}>
        <div className={styles.journeyIntro}>
          <span>{lang === 'ar' ? 'ليه تختار منصتنا؟' : 'Why choose us?'}</span>
          <h2>{lang === 'ar' ? 'إيه اللي هتلاقيه على المنصة؟' : 'What will you find on the platform?'}</h2>
          <p>{lang === 'ar' ? 'منظومة مذاكرة متكاملة تساعدك تفهم وتطبق وتتابع مستواك.' : 'A complete study system that helps you understand, practice, and track progress.'}</p>
        </div>
        <div className={styles.steps}>
          <article><span><Video size={20} /></span><h3>شرح بسيط ومركز</h3><p>نفهم الفكرة من أساسها بأمثلة واضحة وتطبيق مباشر.</p></article>
          <article><span><NotebookPen size={20} /></span><h3>خطة مذاكرة منظمة</h3><p>جدول واضح يساعدك تخلص المنهج من غير تشتت.</p></article>
          <article><span><Trophy size={20} /></span><h3>نماذج امتحانات</h3><p>اختبارات بنفس النظام عشان تدخل الامتحان جاهز.</p></article>
          <article><span><ShieldCheck size={20} /></span><h3>متابعة وتقييم مستمر</h3><p>تقارير دورية توضح مستواك ونقاط التحسن.</p></article>
          <article><span><MessageCircleQuestion size={20} /></span><h3>تفاعل وإجابة للأسئلة</h3><p>اسأل في أي جزئية وخد الإجابة التي توضحها.</p></article>
          <article><span><Atom size={20} /></span><h3>مراجعات ليلة الامتحان</h3><p>ملخصات مركزة لأهم الأفكار والنقاط المتوقعة.</p></article>
        </div>
      </section>

      <section id="reviews" className={`${styles.section} ${styles.reviews}`}>
        <div className={styles.sectionHeading}>
          <div>
            <span>{lang === 'ar' ? 'من قلب الفصل' : 'From the classroom'}</span>
            <h2>{lang === 'ar' ? 'طلاب فهموا، فتفوقوا' : 'Students who understood, then excelled'}</h2>
          </div>
          <div className={styles.reviewArrows}>
            <button aria-label="Previous"><ChevronRight size={19} /></button>
            <button aria-label="Next"><ChevronLeft size={19} /></button>
          </div>
        </div>
        <div className={styles.reviewGrid}>
          {testimonials.map((review, index) => (
            <article key={review.name} className={styles.reviewCard}>
              <div className={styles.reviewTop}>
                <span>{review.name.charAt(0)}</span>
                <div><h3>{review.name}</h3><small>{review.grade}</small></div>
                <b>0{index + 1}</b>
              </div>
              <div className={styles.stars}>{Array.from({ length: 5 }).map((_, star) => <Star key={star} size={14} fill="currentColor" />)}</div>
              <p>“{review.text}”</p>
            </article>
          ))}
        </div>
      </section>

      <section className={styles.cta}>
        <div>
          <span><Users size={17} /> {lang === 'ar' ? 'انضم لطلابنا اليوم' : 'Join our students today'}</span>
          <h2>{lang === 'ar' ? 'جاهز تخلي الكيمياء أسهل مادة عندك؟' : 'Ready to make chemistry your easiest subject?'}</h2>
        </div>
        <Link href={user ? '/my-learning' : '/login'} className={styles.ctaButton}>
          {lang === 'ar' ? 'ابدأ مجانًا' : 'Start for free'}
          {arrow}
        </Link>
      </section>
    </div>
  );
}
