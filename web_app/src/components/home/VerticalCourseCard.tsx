'use client';

import Link from 'next/link';
import { useApp } from '../../context/AppContext';
import {
  getBaseCoursePrice,
  getCourseDiscountPercentage,
  getEffectiveCoursePrice,
} from '../../lib/pricing';
import styles from './VerticalCourseCard.module.css';

export interface CourseData {
  id: string;
  title_ar?: string;
  title_en?: string;
  subtitle_ar?: string;
  subtitle_en?: string;
  thumbnail_url?: string;
  price: number;
  discount_price?: number;
  is_free: boolean;
  pricing_options?: unknown;
  is_flash_sale?: boolean;
  flash_sale_price?: number;
  flash_sale_start?: string;
  flash_sale_end?: string;
  rating: number;
  rating_count?: number;
  enrolled_count: number;
  total_lessons: number;
  total_duration: number;
  instructor_name?: string;
  badge?: string;
  currency?: string;
}

interface VerticalCourseCardProps {
  course: CourseData;
  isWishlisted: boolean;
  onWishlistToggle: () => void;
  width?: number;
}

function formatCount(count: number): string {
  if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
  if (count >= 1000) return `${(count / 1000).toFixed(1)}k`;
  return count.toString();
}

export function VerticalCourseCard({ course, isWishlisted, onWishlistToggle, width }: VerticalCourseCardProps) {
  const { lang, addToCart, cart } = useApp();
  const title = lang === 'ar' ? (course.title_ar || course.title_en || '') : (course.title_en || course.title_ar || '');
  const inCart = cart.includes(course.id);
  const discountPct = getCourseDiscountPercentage(course);
  const basePrice = getBaseCoursePrice(course);
  const currentPrice = getEffectiveCoursePrice(course);
  const hasDiscount = discountPct != null;

  return (
    <Link href={`/courses/${course.id}`} className={styles.card} style={width ? { width } : undefined}>
      <div className={styles.thumbnail}>
        {course.thumbnail_url ? (
          <img src={course.thumbnail_url} alt={title} className={styles.img} />
        ) : (
          <div className={styles.thumbnailFallback}>
            <span className={styles.playIcon}>▶</span>
          </div>
        )}
        {course.badge ? (
          <span className={`${styles.badge} ${styles.badgeCustom}`}>{course.badge}</span>
        ) : course.is_free ? (
          <span className={`${styles.badge} ${styles.badgeFree}`}>{lang === 'ar' ? 'مجاني' : 'Free'}</span>
        ) : discountPct ? (
          <span className={`${styles.badge} ${styles.badgeDiscount}`}>{discountPct}%</span>
        ) : null}
        <button
          className={`${styles.wishlist} ${isWishlisted ? styles.wishlistActive : ''}`}
          onClick={(e) => { e.preventDefault(); e.stopPropagation(); onWishlistToggle(); }}
          aria-label="Wishlist"
        >
          {isWishlisted ? '❤️' : '🤍'}
        </button>
      </div>
      <div className={styles.body}>
        <h3 className={styles.title}>{title}</h3>
        {course.instructor_name && <p className={styles.instructor}>{course.instructor_name}</p>}
        <div className={styles.stats}>
          <span className={styles.rating}>
            <span className={styles.star}>★</span> {course.rating.toFixed(1)}
            <span className={styles.ratingCount}>({formatCount(course.rating_count || 0)})</span>
          </span>
          <span className={styles.enrolled}>
            {formatCount(course.enrolled_count)} 👥
          </span>
        </div>
        <div className={styles.priceRow}>
          {course.is_free ? (
            <span className={styles.freePrice}>{lang === 'ar' ? 'مجاني' : 'Free'}</span>
          ) : (
            <span className={styles.price}>
              {course.currency || (lang === 'ar' ? 'ج.م' : 'EGP')} {Math.round(currentPrice)}
              {hasDiscount && <del className={styles.origPrice}>{Math.round(basePrice)}</del>}
            </span>
          )}
          <button
            type="button"
            className={`${styles.cartButton} ${inCart ? styles.cartButtonAdded : ''}`}
            onClick={(e) => { e.preventDefault(); e.stopPropagation(); addToCart(course.id); }}
            disabled={inCart}
          >
            {inCart ? (lang === 'ar' ? 'تمت الإضافة' : 'Added') : (lang === 'ar' ? 'أضف للسلة' : 'Add to cart')}
          </button>
        </div>
      </div>
    </Link>
  );
}
