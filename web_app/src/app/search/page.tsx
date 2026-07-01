'use client';

import { useEffect, useMemo, useState, Suspense, useCallback } from 'react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import { Search, Tune, Star, Schedule, Groups, Close, History } from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { useFadeIn, useStagger } from '../../lib/animations';
import { CourseFilterSheet, type CourseFilterState } from '../../components/ui';
import { getBaseCoursePrice, getEffectiveCoursePrice, hasCourseDiscount } from '../../lib/pricing';
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

const RECENT_SEARCHES_KEY = 'nero_recent_searches';
const MAX_RECENT = 8;

function getRecentSearches(): string[] {
  try {
    return JSON.parse(localStorage.getItem(RECENT_SEARCHES_KEY) || '[]');
  } catch {
    return [];
  }
}

function saveRecentSearch(query: string) {
  const recent = getRecentSearches().filter((s) => s !== query);
  recent.unshift(query);
  localStorage.setItem(RECENT_SEARCHES_KEY, JSON.stringify(recent.slice(0, MAX_RECENT)));
}

function clearRecentSearches() {
  localStorage.removeItem(RECENT_SEARCHES_KEY);
}

function SearchContent() {
  const { lang, t, cart, addToCart, enrolledCourseIds } = useApp();
  const searchParams = useSearchParams();
  const router = useRouter();
  const initialQuery = searchParams.get('q') || '';
  const initialCategory = searchParams.get('category') || '';

  const [courses, setCourses] = useState<Course[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState(initialQuery);
  const [recentSearches, setRecentSearches] = useState<string[]>([]);
  const [showFilters, setShowFilters] = useState(false);

  const [filters, setFilters] = useState<CourseFilterState>({
    categories: initialCategory ? [initialCategory] : [],
    priceMin: 0,
    priceMax: 500,
    levels: [],
    rating: 'all',
    sort: 'popular',
  });

  const [legacyFilters, setLegacyFilters] = useState({
    duration: 'all',
    language: 'all',
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

  useEffect(() => {
    setRecentSearches(getRecentSearches());
  }, []);

  useEffect(() => {
    if (initialCategory && !filters.categories.includes(initialCategory)) {
      setFilters((prev) => ({ ...prev, categories: [initialCategory] }));
    }
  }, [initialCategory]);

  const handleSearchSubmit = useCallback((e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = query.trim();
    if (trimmed) {
      saveRecentSearch(trimmed);
      setRecentSearches(getRecentSearches());
    }
  }, [query]);

  const handleRecentClick = useCallback((term: string) => {
    setQuery(term);
  }, []);

  const handleClearRecent = useCallback(() => {
    clearRecentSearches();
    setRecentSearches([]);
  }, []);

  const handleFilterApply = useCallback((newFilters: CourseFilterState) => {
    setFilters(newFilters);
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

      const matchesCategory = filters.categories.length === 0 || filters.categories.includes(c.category_id);
      const matchesLevel = filters.levels.length === 0 || filters.levels.includes(c.level);
      const matchesLanguage = legacyFilters.language === 'all' || c.language === legacyFilters.language;

      let matchesPrice = true;
      const effectivePrice = getEffectiveCoursePrice(c);
      if (filters.priceMin > 0 || filters.priceMax < 500) {
        if (c.is_free) {
          matchesPrice = filters.priceMin === 0;
        } else {
          matchesPrice = effectivePrice >= filters.priceMin && effectivePrice <= filters.priceMax;
        }
      }

      let matchesRating = true;
      if (filters.rating === '4plus') matchesRating = (c.rating || 0) >= 4;
      else if (filters.rating === '3plus') matchesRating = (c.rating || 0) >= 3;
      else if (filters.rating === '2plus') matchesRating = (c.rating || 0) >= 2;

      let matchesDuration = true;
      if (legacyFilters.duration === 'short') matchesDuration = (c.total_duration || 0) < 60;
      else if (legacyFilters.duration === 'medium')
        matchesDuration = (c.total_duration || 0) >= 60 && (c.total_duration || 0) <= 180;
      else if (legacyFilters.duration === 'long') matchesDuration = (c.total_duration || 0) > 180;

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
      if (filters.sort === 'newest') return 0;
      if (filters.sort === 'rating') return (b.rating || 0) - (a.rating || 0);
      if (filters.sort === 'priceLow') return getEffectiveCoursePrice(a) - getEffectiveCoursePrice(b);
      if (filters.sort === 'priceHigh') return getEffectiveCoursePrice(b) - getEffectiveCoursePrice(a);
      return (b.enrolled_count || 0) - (a.enrolled_count || 0);
    });

    return list;
  }, [courses, filters, legacyFilters, lang, normalizedQuery]);

  const activeFiltersCount = [
    ...filters.categories,
    ...filters.levels,
    filters.rating !== 'all' ? filters.rating : null,
    (filters.priceMin > 0 || filters.priceMax < 500) ? 'price' : null,
  ].filter(Boolean).length;

  const hasQuery = normalizedQuery.length > 0;

  return (
    <div className="container">
      <div ref={heroRef} className={styles.hero}>
        <div className={styles.heroContent}>
          <h1>{lang === 'ar' ? 'ابحث عن كورسك 🎓' : 'Find your course 🎓'}</h1>
          <form className={styles.searchBox} onSubmit={handleSearchSubmit}>
            <Search fontSize="small" />
            <input
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={lang === 'ar' ? 'ابحث بالعنوان أو الوصف...' : 'Search by title or description...'}
            />
            <button
              className={styles.filterToggle}
              onClick={() => setShowFilters(true)}
              type="button"
              data-active={activeFiltersCount > 0}
            >
              <Tune fontSize="small" />
              {activeFiltersCount > 0 && <span>{activeFiltersCount}</span>}
            </button>
          </form>
        </div>
        <span className={styles.heroEmoji} aria-hidden>📚</span>
      </div>

      {!hasQuery && recentSearches.length > 0 && (
        <div className={styles.recentSection}>
          <div className={styles.recentHeader}>
            <div className={styles.recentTitle}>
              <History fontSize="small" />
              <span>{t.recentSearches}</span>
            </div>
            <button className={styles.clearRecentBtn} onClick={handleClearRecent} type="button">
              {t.clearAll}
            </button>
          </div>
          <div className={styles.recentChips}>
            {recentSearches.map((term) => (
              <button
                key={term}
                className={styles.recentChip}
                onClick={() => handleRecentClick(term)}
                type="button"
              >
                {term}
              </button>
            ))}
          </div>
        </div>
      )}

      {!hasQuery && categories.length > 0 && (
        <div className={styles.categoriesSection}>
          <div className={styles.categoriesHeader}>
            <span className={styles.categoriesTitle}>{t.categories}</span>
            <Link href="/categories" className={styles.viewAllLink}>
              {lang === 'ar' ? 'عرض الكل' : 'View All'}
            </Link>
          </div>
          <div className={styles.categoryChips}>
            {categories.slice(0, 8).map((cat) => (
              <button
                key={cat.id}
                className={`${styles.categoryChip} ${filters.categories.includes(cat.id) ? styles.categoryChipActive : ''}`}
                onClick={() =>
                  setFilters((prev) => ({
                    ...prev,
                    categories: prev.categories.includes(cat.id)
                      ? prev.categories.filter((c) => c !== cat.id)
                      : [...prev.categories, cat.id],
                  }))
                }
                type="button"
              >
                {lang === 'ar' ? cat.name_ar : cat.name_en}
              </button>
            ))}
          </div>
        </div>
      )}

      <div className={styles.resultsHeader}>
        <span>
          <span className={styles.resultsCount}>{filtered.length}</span>
          {' '}{lang === 'ar' ? 'نتيجة' : `result${filtered.length !== 1 ? 's' : ''}`}
        </span>
        {activeFiltersCount > 0 && (
          <button
            className={styles.clearBtn}
            onClick={() => {
              setFilters({
                categories: [],
                priceMin: 0,
                priceMax: 500,
                levels: [],
                rating: 'all',
                sort: 'popular',
              });
              setLegacyFilters({ duration: 'all', language: 'all' });
            }}
            type="button"
          >
            <Close fontSize="small" /> {lang === 'ar' ? 'مسح الفلاتر' : 'Clear filters'}
          </button>
        )}
      </div>

      {loading ? (
        <div className={styles.loading}>{t.loading}</div>
      ) : filtered.length === 0 ? (
        <div className={styles.emptyState}>
          <Search fontSize="large" />
          <strong>{lang === 'ar' ? 'لا توجد نتائج مطابقة' : 'No matching courses'}</strong>
          <span>{lang === 'ar' ? 'جرّب تغيير البحث أو الفلاتر' : 'Try changing your search or filters'}</span>
        </div>
      ) : (
        <div ref={gridRef} className={styles.grid}>
          {filtered.map((course) => {
            const inCart = cart.includes(course.id);
            const isEnrolled = enrolledCourseIds.includes(course.id);
            const basePrice = getBaseCoursePrice(course);
            const effectivePrice = getEffectiveCoursePrice(course);
            const hasDiscount = hasCourseDiscount(course);

            return (
              <article key={course.id} className={styles.courseCard}>
                <Link href={`/courses/${course.id}`} className={styles.thumbLink}>
                  {course.thumbnail_url ? (
                    <img src={course.thumbnail_url} alt="" className={styles.thumb} />
                  ) : (
                    <div className={styles.thumbPlaceholder} />
                  )}
                  {course.level && (
                    <span className={styles.levelBadge}>
                      {lang === 'ar'
                        ? course.level === 'beginner' ? 'مبتدئ' : course.level === 'intermediate' ? 'متوسط' : 'متقدم'
                        : course.level}
                    </span>
                  )}
                </Link>
                <div className={styles.cardBody}>
                  <h3>{lang === 'ar' ? course.title_ar : course.title_en}</h3>
                  <p>{lang === 'ar' ? course.subtitle_ar : course.subtitle_en}</p>
                  <div className={styles.metaRow}>
                    <span className={styles.ratingVal}><Star fontSize="small" /> {Number(course.rating || 0).toFixed(1)}</span>
                    <span><Schedule fontSize="small" /> {course.total_duration || 0} {t.durationMinutes}</span>
                    <span><Groups fontSize="small" /> {course.enrolled_count || 0}</span>
                  </div>
                  <div className={styles.cardFooter}>
                    <div className={styles.price}>
                      {course.is_free ? (
                        <span className={styles.free}>{t.free}</span>
                      ) : hasDiscount ? (
                        <>
                          <span>{effectivePrice} {t.egp}</span>
                          <del>{basePrice} {t.egp}</del>
                          <span className={styles.discountBadge}>
                            -{Math.round((1 - effectivePrice / basePrice) * 100)}%
                          </span>
                        </>
                      ) : (
                        <span>{effectivePrice} {t.egp}</span>
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

      <CourseFilterSheet
        open={showFilters}
        onClose={() => setShowFilters(false)}
        onApply={handleFilterApply}
        categories={categories}
        initialFilters={filters}
      />
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
