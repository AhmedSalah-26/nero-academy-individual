'use client';

import { useEffect, useState, useMemo, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Favorite, FavoriteBorder, ShoppingCart, Delete, PlayCircle, CheckCircle, ArrowForward } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import { ShimmerEffect, EmptyState, FilterChips, PriceTag, RatingStars, AppButton } from '../../components/ui';
import { NumberUtils, AppDateUtils } from '../../lib/formatters';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

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
  rating?: number;
  rating_count?: number;
  instructor_name_ar?: string;
  instructor_name_en?: string;
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
          .select('id, title_ar, title_en, subtitle_ar, subtitle_en, thumbnail_url, price, discount_price, is_free, rating, rating_count, instructor_name_ar, instructor_name_en, created_at')
          .in('id', wishlist);
        if (active) setItems((data || []) as WishlistCourse[]);
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
    if (currentFilter === 'price-drops') return items.filter((c) => c.discount_price && c.discount_price < c.price);
    if (currentFilter === 'enrolled') return items.filter((c) => enrolledCourseIds.includes(c.id));
    return items;
  }, [items, filter, enrolledCourseIds]);

  const totalValue = useMemo(() => {
    return filteredItems.reduce((sum, c) => {
      const price = c.is_free ? 0 : (c.discount_price || c.price || 0);
      return sum + price;
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
        <Link href={`/learn/${course.id}`} className={styles.actionPurchased}>
          <PlayCircle fontSize="small" />
          <span>{lang === 'ar' ? 'اذهب للتعلم' : 'Go to Learning'}</span>
        </Link>
      );
    }
    if (cart.includes(course.id)) {
      return (
        <span className={styles.actionInCart}>
          <CheckCircle fontSize="small" />
          <span>{lang === 'ar' ? 'في السلة' : 'In Cart'}</span>
        </span>
      );
    }
    return (
      <button className={styles.actionCart} onClick={() => addToCart(course.id)} type="button">
        <ShoppingCart fontSize="small" />
        <span>{t.addToCart}</span>
      </button>
    );
  };

  const filterChips = [
    { id: 'all', label: t.all, count: items.length },
    { id: 'price-drops', label: t.priceDrops, count: items.filter((c) => c.discount_price && c.discount_price < c.price).length },
    { id: 'enrolled', label: t.enrolled, count: items.filter((c) => enrolledCourseIds.includes(c.id)).length },
  ];

  if (loading) {
    return (
      <main className={styles.page}>
        <FeaturePageHero
          icon={Favorite}
          eyebrow={lang === 'ar' ? 'محفوظاتك' : 'SAVED'}
          title={lang === 'ar' ? 'المفضلة' : 'Wishlist'}
          subtitle={lang === 'ar' ? 'كل الكورسات التي حفظتها للعودة إليها لاحقاً.' : 'Courses you saved for later.'}
        />
        <div className={styles.shimmerGrid}>
          {[1, 2, 3].map((i) => (
            <div key={i} className={styles.shimmerCard}>
              <ShimmerEffect width="100%" height="160px" borderRadius="lg" />
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
      <FeaturePageHero
        icon={Favorite}
        eyebrow={lang === 'ar' ? 'محفوظاتك' : 'SAVED'}
        title={lang === 'ar' ? 'المفضلة' : 'Wishlist'}
        subtitle={lang === 'ar' ? 'كل الكورسات التي حفظتها للعودة إليها لاحقاً.' : 'Courses you saved for later.'}
      />

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
          <div className={styles.filterRow}>
            <FilterChips items={filterChips} selected={filter} onChange={setFilter} />
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
                <article className={styles.card} key={c.id}>
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
                      onClick={() => removeFromWishlist(c.id)}
                      type="button"
                      aria-label={lang === 'ar' ? 'إزالة من المفضلة' : 'Remove from wishlist'}
                    >
                      <Favorite fontSize="small" />
                    </button>
                    {c.discount_price && c.discount_price < c.price && (
                      <span className={styles.priceDropBadge}>
                        -{Math.round(((c.price - c.discount_price) / c.price) * 100)}%
                      </span>
                    )}
                  </div>

                  <div className={styles.cardBody}>
                    {(c.instructor_name_ar || c.instructor_name_en) && (
                      <p className={styles.instructorName}>
                        {lang === 'ar' ? c.instructor_name_ar : c.instructor_name_en}
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

                    <div className={styles.cardPricing}>
                      {c.is_free ? (
                        <span className={styles.freeLabel}>{t.free}</span>
                      ) : (
                        <PriceTag
                          price={c.discount_price || c.price}
                          originalPrice={c.discount_price ? c.price : undefined}
                          size="sm"
                        />
                      )}
                    </div>

                    <div className={styles.cardActions}>
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
