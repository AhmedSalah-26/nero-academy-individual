'use client';

import { useEffect, useState, useMemo, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Favorite, FavoriteBorder, ShoppingCart, Delete, PlayCircle, CheckCircle, ArrowForward, BookmarkBorder } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { ShimmerEffect, EmptyState, FilterChips, PriceTag, RatingStars, AppButton } from '../../components/ui';
import { NumberUtils, AppDateUtils } from '../../lib/formatters';
import { getBaseCoursePrice, getEffectiveCoursePrice, hasCourseDiscount } from '../../lib/pricing';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface InstructorProfile {
  id?: string;
  name?: string;
}

interface WishlistCourse {
  id: string;
  title_ar: string;
  title_en?: string;
  subtitle_ar?: string;
  subtitle_en?: string;
  thumbnail_url?: string;
  price: number;
  discount_price?: number;
  is_free?: boolean;
  pricing_options?: unknown;
  rating?: number;
  rating_count?: number;
  instructor_name?: string;
  profiles?: InstructorProfile | InstructorProfile[] | null;
  created_at?: string;
  price_history?: number;
}

type FilterTab = 'all' | 'price-drops' | 'enrolled';

export default function WishlistPage() {
  const pageRef = usePageTransition();
  const { lang, t, wishlist, removeFromWishlist, addToCart, cart, enrolledCourseIds, user } = useApp();
  const router = useRouter();

  const [items, setItems] = useState<WishlistCourse[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string[]>(['all']);

  useEffect(() => {
    let active = true;
    const load = async () => {
      if (!wishlist.length) {
        if (active) setItems([]);
        setLoading(false);
        return;
      }
      try {
        const { data } = await supabase
          .from('courses')
          .select('id, title_ar, title_en, subtitle_ar, subtitle_en, thumbnail_url, price, discount_price, is_free, pricing_options, rating, rating_count, created_at, profiles!courses_instructor_id_fkey(id, name)')
          .in('id', wishlist);
        if (active) {
          const itemsWithInstructor = (data || []).map((course: unknown) => {
            const c = course as WishlistCourse;
            const profile = Array.isArray(c.profiles) ? c.profiles[0] : c.profiles;
            return { ...c, instructor_name: profile?.name } as WishlistCourse;
          });
          setItems(itemsWithInstructor);
        }
      } catch {
        if (active) setItems([]);
      } finally {
        if (active) setLoading(false);
      }
    };
    load();
    return () => { active = false; };
  }, [wishlist]);

  const filteredItems = useMemo(() => {
    const currentFilter = filter[0] || 'all';
    if (currentFilter === 'all') return items;
    if (currentFilter === 'price-drops') return items.filter((c) => hasCourseDiscount(c));
    if (currentFilter === 'enrolled') return items.filter((c) => enrolledCourseIds.includes(c.id));
    return items;
  }, [items, filter, enrolledCourseIds]);

  const totalValue = useMemo(() => {
    return filteredItems.reduce((sum, c) => {
      return sum + getEffectiveCoursePrice(c);
    }, 0);
  }, [filteredItems]);

  const handleAddAllToCart = useCallback(async () => {
    const itemsNotInCart = filteredItems.filter((c) => !cart.includes(c.id) && !enrolledCourseIds.includes(c.id));
    for (const c of itemsNotInCart) {
      await addToCart(c.id);
    }
  }, [filteredItems, cart, enrolledCourseIds, addToCart]);

  const getActionButton = (course: WishlistCourse) => {
    if (enrolledCourseIds.includes(course.id)) {
      return (
        <Link href={`/learn/${course.id}`} className={`${styles.actionBtn} ${styles.enrolled}`} onClick={(e) => e.stopPropagation()}>
          <span>{lang === 'ar' ? 'اذهب للتعلم' : 'Go to Learning'}</span>
        </Link>
      );
    }
    if (cart.includes(course.id)) {
      return (
        <span className={`${styles.actionBtn} ${styles.inCart}`} onClick={(e) => e.stopPropagation()}>
          <span>{lang === 'ar' ? 'في السلة' : 'In Cart'}</span>
        </span>
      );
    }
    return (
      <button className={styles.actionBtn} onClick={(e) => { e.stopPropagation(); addToCart(course.id); }} type="button">
        <span>{t.addToCart}</span>
      </button>
    );
  };

  const filterChips = [
    { id: 'all', label: t.all, count: items.length },
    { id: 'price-drops', label: t.priceDrops, count: items.filter((c) => hasCourseDiscount(c)).length },
    { id: 'enrolled', label: t.enrolled, count: items.filter((c) => enrolledCourseIds.includes(c.id)).length },
  ];

  if (loading) {
    return (
      <main className={styles.page}>
        <div className={styles.hero}>
          <div className={styles.heroText}>
            <p className={styles.heroEyebrow}>{lang === 'ar' ? 'محفوظاتك' : 'SAVED'}</p>
            <h1>{lang === 'ar' ? 'المفضلة' : 'Wishlist'}</h1>
            <p>{lang === 'ar' ? 'كل الكورسات التي حفظتها للعودة إليها لاحقاً.' : 'Courses you saved for later.'}</p>
          </div>
          <div className={styles.heroIcon}>❤️</div>
        </div>
        <div className={styles.shimmerGrid}>
          {[1, 2, 3].map((i) => (
            <div key={i} className={styles.shimmerCard}>
              <ShimmerEffect width="100%" height="180px" borderRadius="lg" />
              <div className={styles.shimmerBody}>
                <ShimmerEffect width="80%" height="16px" borderRadius="sm" />
                <ShimmerEffect width="60%" height="12px" borderRadius="sm" />
                <ShimmerEffect width="40%" height="12px" borderRadius="sm" />
              </div>
            </div>
          ))}
        </div>
      </main>
    );
  }

  return (
    <main ref={pageRef} className={styles.page}>
      {/* Hero */}
      <div className={styles.hero}>
        <div className={styles.heroText}>
          <p className={styles.heroEyebrow}>{lang === 'ar' ? 'محفوظاتك' : 'SAVED'}</p>
          <h1>{lang === 'ar' ? 'المفضلة' : 'Wishlist'}</h1>
          <p>{lang === 'ar' ? 'كل الكورسات التي حفظتها للعودة إليها لاحقاً.' : 'Courses you saved for later.'}</p>
        </div>
        <div className={styles.heroIcon}>❤️</div>
      </div>

      {items.length === 0 ? (
        <div className={styles.emptyWrap}>
          <EmptyState
            type="wishlist"
            title={lang === 'ar' ? 'المفضلة فارغة' : 'Wishlist is empty'}
            message={lang === 'ar' ? 'احفظ الكورسات التي تعجبك للعودة إليها لاحقاً' : 'Save courses you like for later'}
            actionLabel={lang === 'ar' ? 'استكشف الكورسات' : 'Explore Courses'}
            onAction={() => router.push('/')}
          />
        </div>
      ) : (
        <>
          {/* Toolbar: filter + stats */}
          <div className={styles.toolbar}>
            <FilterChips items={filterChips} selected={filter} onChange={setFilter} />
            <div className={styles.statsRow}>
              <span className={styles.statBadge}>
                <Favorite sx={{ fontSize: 14, color: '#E11D48' }} />
                <strong>{items.length}</strong>
                {lang === 'ar' ? ' كورس' : ' courses'}
              </span>
            </div>
          </div>

          {filteredItems.length === 0 ? (
            <div className={styles.noResults}>
              <EmptyState
                type="search"
                title={t.noResults}
                compact
              />
            </div>
          ) : (
            <section className={styles.grid}>
              {filteredItems.map((c) => (
                <article className={styles.card} key={c.id} onClick={() => router.push(`/courses/${c.id}`)} style={{ cursor: 'pointer' }}>
                  <div className={styles.cardMedia}>
                    {c.thumbnail_url ? (
                      <img
                        className={styles.cardImg}
                        src={c.thumbnail_url}
                        alt=""
                        onError={(e) => { e.currentTarget.style.display = 'none'; }}
                      />
                    ) : (
                      <div className={styles.cardPlaceholder}>
                        <FavoriteBorder fontSize="large" className={styles.placeholderIcon} />
                      </div>
                    )}
                    <button
                      className={styles.favBtn}
                      onClick={(e) => { e.stopPropagation(); removeFromWishlist(c.id); }}
                      type="button"
                      aria-label={lang === 'ar' ? 'إزالة من المفضلة' : 'Remove from wishlist'}
                    >
                      <Favorite fontSize="small" />
                    </button>
                    {hasCourseDiscount(c) && (
                      <span className={styles.priceDropBadge}>
                        -{Math.round(((getBaseCoursePrice(c) - getEffectiveCoursePrice(c)) / getBaseCoursePrice(c)) * 100)}%
                      </span>
                    )}
                  </div>

                  <div className={styles.cardBody}>
                    {c.instructor_name && (
                      <p className={styles.instructorName}>
                        {c.instructor_name}
                      </p>
                    )}

                    <h3 className={styles.cardTitle}>
                      {lang === 'ar' ? c.title_ar : c.title_en || c.title_ar}
                    </h3>

                    {(c.subtitle_ar || c.subtitle_en) && (
                      <p className={styles.cardSubtitle}>
                        {lang === 'ar' ? c.subtitle_ar : c.subtitle_en || c.subtitle_ar}
                      </p>
                    )}

                    {c.rating != null && c.rating > 0 && (
                      <div className={styles.ratingRow}>
                        <RatingStars value={c.rating} size="xs" showValue />
                      </div>
                    )}

                    <div className={styles.cardFooter}>
                      <div className={styles.price}>
                        {c.is_free ? (
                          <span className={styles.free}>{t.free}</span>
                        ) : hasCourseDiscount(c) ? (
                          <>
                            <span>{getEffectiveCoursePrice(c)} {t.egp}</span>
                            <del>{getBaseCoursePrice(c)} {t.egp}</del>
                            <span className={styles.discountBadge}>
                              -{Math.round((1 - getEffectiveCoursePrice(c) / getBaseCoursePrice(c)) * 100)}%
                            </span>
                          </>
                        ) : (
                          <span>{getEffectiveCoursePrice(c)} {t.egp}</span>
                        )}
                      </div>
                      {getActionButton(c)}
                    </div>

                    {c.created_at && (
                      <p className={styles.timeAgo}>
                        {AppDateUtils.getRelativeTime(c.created_at, lang)}
                      </p>
                    )}
                  </div>
                </article>
              ))}
            </section>
          )}

          <div className={styles.valueBar}>
            <div className={styles.valueInfo}>
              <span className={styles.valueLabel}>{t.totalValue}</span>
              <span className={styles.valueAmount}>{NumberUtils.formatPrice(totalValue, lang)}</span>
              <span className={styles.valueCount}>
                ({filteredItems.length} {lang === 'ar' ? 'كورس' : 'courses'})
              </span>
            </div>
            <AppButton
              variant="primary"
              size="medium"
              onClick={handleAddAllToCart}
              startIcon={<ShoppingCart fontSize="small" />}
              endIcon={lang === 'ar' ? <ArrowForward fontSize="small" /> : undefined}
            >
              {t.addAllToCart}
            </AppButton>
          </div>
        </>
      )}
    </main>
  );
}
