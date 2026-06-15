'use client';

import { useEffect, useMemo, useState, Suspense } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Search, SlidersHorizontal, Star, Clock, Users, X } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { useFadeIn, useStagger } from '../../lib/animations';
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
  total_duration: number;
  enrolled_count: number;
  rating: number;
  level: string;
  language: string;
  category_id: string;
}

interface Category {
  id: string;
  name_ar: string;
  name_en: string;
}

function SearchContent() {
  const { lang, t, cart, addToCart, enrolledCourseIds } = useApp();
  const searchParams = useSearchParams();
  const initialQuery = searchParams.get('q') || '';
  const [courses, setCourses] = useState<Course[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState(initialQuery);
  const [showFilters, setShowFilters] = useState(false);

  const [filters, setFilters] = useState({
    category: 'all',
    price: 'all',
    level: 'all',
    rating: 'all',
    duration: 'all',
    language: 'all',
    sort: 'popular',
  });

  const heroRef = useFadeIn<HTMLDivElement>();
  const gridRef = useStagger<HTMLDivElement>('[class*="courseCard"]');

  useEffect(() => {
    async function load() {
      const [coursesRes, categoriesRes] = await Promise.all([
        supabase.from('courses').select('*').eq('is_published', true).eq('is_active', true),
        supabase.from('categories').select('id, name_ar, name_en').eq('is_active', true),
      ]);
      setCourses((coursesRes.data || []) as Course[]);
      setCategories((categoriesRes.data || []) as Category[]);
      setLoading(false);
    }
    load();
  }, []);

  const normalizedQuery = query.trim().toLowerCase();

  const filtered = useMemo(() => {
    let list = courses.filter((c) => {
      const title = lang === 'ar' ? c.title_ar : c.title_en;
      const subtitle = lang === 'ar' ? c.subtitle_ar : c.subtitle_en;
      const matchesQuery =
        !normalizedQuery ||
        title?.toLowerCase().includes(normalizedQuery) ||
        subtitle?.toLowerCase().includes(normalizedQuery);

      const matchesCategory = filters.category === 'all' || c.category_id === filters.category;
      const matchesLevel = filters.level === 'all' || c.level === filters.level;
      const matchesLanguage = filters.language === 'all' || c.language === filters.language;

      let matchesPrice = true;
      if (filters.price === 'free') matchesPrice = c.is_free;
      else if (filters.price === 'paid') matchesPrice = !c.is_free;
      else if (filters.price === 'under100') matchesPrice = (c.discount_price || c.price) < 100;
      else if (filters.price === '100to300')
        matchesPrice = (c.discount_price || c.price) >= 100 && (c.discount_price || c.price) <= 300;
      else if (filters.price === 'over300') matchesPrice = (c.discount_price || c.price) > 300;

      let matchesRating = true;
      if (filters.rating === '4plus') matchesRating = (c.rating || 0) >= 4;
      else if (filters.rating === '3plus') matchesRating = (c.rating || 0) >= 3;

      let matchesDuration = true;
      if (filters.duration === 'short') matchesDuration = (c.total_duration || 0) < 60;
      else if (filters.duration === 'medium')
        matchesDuration = (c.total_duration || 0) >= 60 && (c.total_duration || 0) <= 180;
      else if (filters.duration === 'long') matchesDuration = (c.total_duration || 0) > 180;

      return (
        matchesQuery &&
        matchesCategory &&
        matchesPrice &&
        matchesLevel &&
        matchesRating &&
        matchesDuration &&
        matchesLanguage
      );
    });

    list = [...list].sort((a, b) => {
      if (filters.sort === 'newest') return new Date(b.id).getTime() - new Date(a.id).getTime();
      if (filters.sort === 'rating') return (b.rating || 0) - (a.rating || 0);
      if (filters.sort === 'priceLow') return (a.discount_price || a.price) - (b.discount_price || b.price);
      if (filters.sort === 'priceHigh') return (b.discount_price || b.price) - (a.discount_price || a.price);
      return (b.enrolled_count || 0) - (a.enrolled_count || 0);
    });

    return list;
  }, [courses, filters, lang, normalizedQuery]);

  const activeFiltersCount = Object.values(filters).filter((v) => v !== 'all').length;

  return (
    <div className="container">
      <div ref={heroRef} className={`${styles.hero} glass`}>
        <h1>{lang === 'ar' ? 'ابحث عن كورسك' : 'Find your course'}</h1>
        <div className={styles.searchBox}>
          <Search size={20} />
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={lang === 'ar' ? 'ابحث بالعنوان أو الوصف...' : 'Search by title or description...'}
          />
          <button
            className={styles.filterToggle}
            onClick={() => setShowFilters(!showFilters)}
            data-active={activeFiltersCount > 0}
          >
            <SlidersHorizontal size={18} />
            {activeFiltersCount > 0 && <span>{activeFiltersCount}</span>}
          </button>
        </div>
      </div>

      {showFilters && (
        <div className={`${styles.filters} glass`}>
          <div className={styles.filterGrid}>
            <select value={filters.category} onChange={(e) => setFilters({ ...filters, category: e.target.value })}>
              <option value="all">{t.allCategories}</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {lang === 'ar' ? c.name_ar : c.name_en}
                </option>
              ))}
            </select>

            <select value={filters.price} onChange={(e) => setFilters({ ...filters, price: e.target.value })}>
              <option value="all">{lang === 'ar' ? 'أي سعر' : 'Any price'}</option>
              <option value="free">{t.free}</option>
              <option value="paid">{lang === 'ar' ? 'مدفوع' : 'Paid'}</option>
              <option value="under100">{lang === 'ar' ? 'أقل من 100 ج' : 'Under 100 EGP'}</option>
              <option value="100to300">{lang === 'ar' ? '100 - 300 ج' : '100 - 300 EGP'}</option>
              <option value="over300">{lang === 'ar' ? 'أكثر من 300 ج' : 'Over 300 EGP'}</option>
            </select>

            <select value={filters.level} onChange={(e) => setFilters({ ...filters, level: e.target.value })}>
              <option value="all">{lang === 'ar' ? 'أي مستوى' : 'Any level'}</option>
              <option value="beginner">{lang === 'ar' ? 'مبتدئ' : 'Beginner'}</option>
              <option value="intermediate">{lang === 'ar' ? 'متوسط' : 'Intermediate'}</option>
              <option value="advanced">{lang === 'ar' ? 'متقدم' : 'Advanced'}</option>
            </select>

            <select value={filters.rating} onChange={(e) => setFilters({ ...filters, rating: e.target.value })}>
              <option value="all">{lang === 'ar' ? 'أي تقييم' : 'Any rating'}</option>
              <option value="4plus">{lang === 'ar' ? '4 نجوم فأكثر' : '4+ stars'}</option>
              <option value="3plus">{lang === 'ar' ? '3 نجوم فأكثر' : '3+ stars'}</option>
            </select>

            <select value={filters.duration} onChange={(e) => setFilters({ ...filters, duration: e.target.value })}>
              <option value="all">{lang === 'ar' ? 'أي مدة' : 'Any duration'}</option>
              <option value="short">{lang === 'ar' ? 'أقل من ساعة' : 'Under 1 hour'}</option>
              <option value="medium">{lang === 'ar' ? '1 - 3 ساعات' : '1 - 3 hours'}</option>
              <option value="long">{lang === 'ar' ? 'أكثر من 3 ساعات' : 'Over 3 hours'}</option>
            </select>

            <select value={filters.language} onChange={(e) => setFilters({ ...filters, language: e.target.value })}>
              <option value="all">{lang === 'ar' ? 'أي لغة' : 'Any language'}</option>
              <option value="ar">{lang === 'ar' ? 'العربية' : 'Arabic'}</option>
              <option value="en">{lang === 'ar' ? 'الإنجليزية' : 'English'}</option>
            </select>

            <select value={filters.sort} onChange={(e) => setFilters({ ...filters, sort: e.target.value })}>
              <option value="popular">{lang === 'ar' ? 'الأكثر شهرة' : 'Most popular'}</option>
              <option value="newest">{lang === 'ar' ? 'الأحدث' : 'Newest'}</option>
              <option value="rating">{lang === 'ar' ? 'الأعلى تقييماً' : 'Highest rated'}</option>
              <option value="priceLow">{lang === 'ar' ? 'السعر: الأقل' : 'Price: low to high'}</option>
              <option value="priceHigh">{lang === 'ar' ? 'السعر: الأعلى' : 'Price: high to low'}</option>
            </select>
          </div>

          {activeFiltersCount > 0 && (
            <button
              className={styles.clearBtn}
              onClick={() =>
                setFilters({
                  category: 'all',
                  price: 'all',
                  level: 'all',
                  rating: 'all',
                  duration: 'all',
                  language: 'all',
                  sort: 'popular',
                })
              }
            >
              <X size={14} /> {lang === 'ar' ? 'مسح الفلاتر' : 'Clear filters'}
            </button>
          )}
        </div>
      )}

      <div className={styles.resultsHeader}>
        <span>
          {filtered.length} {lang === 'ar' ? 'نتيجة' : 'result'}{filtered.length !== 1 && lang === 'en' ? 's' : ''}
        </span>
      </div>

      {loading ? (
        <div className={styles.loading}>{t.loading}</div>
      ) : filtered.length === 0 ? (
        <div className={styles.emptyState}>
          <Search size={48} />
          <strong>{lang === 'ar' ? 'لا توجد نتائج مطابقة' : 'No matching courses'}</strong>
          <span>{lang === 'ar' ? 'جرّب تغيير البحث أو الفلاتر' : 'Try changing your search or filters'}</span>
        </div>
      ) : (
        <div ref={gridRef} className={styles.grid}>
          {filtered.map((course) => {
            const inCart = cart.includes(course.id);
            const isEnrolled = enrolledCourseIds.includes(course.id);
            const hasDiscount = course.discount_price > 0 && course.discount_price < course.price;

            return (
              <article key={course.id} className={styles.courseCard}>
                <Link href={`/courses/${course.id}`} className={styles.thumbLink}>
                  {course.thumbnail_url ? (
                    <img src={course.thumbnail_url} alt="" className={styles.thumb} />
                  ) : (
                    <div className={styles.thumbPlaceholder} />
                  )}
                </Link>
                <div className={styles.cardBody}>
                  <h3>{lang === 'ar' ? course.title_ar : course.title_en}</h3>
                  <p>{lang === 'ar' ? course.subtitle_ar : course.subtitle_en}</p>
                  <div className={styles.metaRow}>
                    <span><Star size={13} fill="currentColor" /> {Number(course.rating || 0).toFixed(1)}</span>
                    <span><Clock size={13} /> {course.total_duration || 0} {t.durationMinutes}</span>
                    <span><Users size={13} /> {course.enrolled_count || 0}</span>
                  </div>
                  <div className={styles.cardFooter}>
                    <div className={styles.price}>
                      {course.is_free ? (
                        <span className={styles.free}>{t.free}</span>
                      ) : hasDiscount ? (
                        <>
                          <span>{course.discount_price} {t.egp}</span>
                          <del>{course.price} {t.egp}</del>
                        </>
                      ) : (
                        <span>{course.price} {t.egp}</span>
                      )}
                    </div>
                    {isEnrolled ? (
                      <Link href={`/learn/${course.id}`} className={`${styles.actionBtn} ${styles.enrolled}`}>
                        {t.continueLearning}
                      </Link>
                    ) : (
                      <button
                        onClick={() => addToCart(course.id)}
                        disabled={inCart}
                        className={`${styles.actionBtn} ${inCart ? styles.inCart : ''}`}
                      >
                        {inCart ? t.addedToCart : t.addToCart}
                      </button>
                    )}
                  </div>
                </div>
              </article>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default function SearchPage() {
  return (
    <Suspense
      fallback={
        <div className="container fade-in">
          <div className={styles.loading}>{'Loading...'}</div>
        </div>
      }
    >
      <SearchContent />
    </Suspense>
  );
}
