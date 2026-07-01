'use client';

import Link from 'next/link';
import { useApp } from '../../context/AppContext';
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
  is_flash_sale?: boolean;
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

function isFlashSaleActive(course: CourseData): boolean {
  if (!course.is_flash_sale) return false;
  const now = Date.now();
  if (course.flash_sale_start && now < new Date(course.flash_sale_start).getTime()) return false;
  if (course.flash_sale_end && now > new Date(course.flash_sale_end).getTime()) return false;
  return true;
}

function getDiscountPercentage(course: CourseData): number | null {
  if (course.is_free || course.price <= 0) return null;
  if (course.discount_price == null || course.discount_price >= course.price) return null;
  if (course.is_flash_sale && !isFlashSaleActive(course)) return null;
  return Math.round(((course.price - course.discount_price) / course.price) * 100);
}

function getCurrentPrice(course: CourseData): number {
  if (course.is_free) return 0;
  if (course.is_flash_sale && isFlashSaleActive(course)) return course.discount_price ?? course.price;
  return course.discount_price ?? course.price;
}

export function VerticalCourseCard({ course, isWishlisted, onWishlistToggle, width }: VerticalCourseCardProps) {
  const { lang, addToCart, cart } = useApp();
  const title = lang === 'ar' ? (course.title_ar || course.title_en || '') : (course.title_en || course.title_ar || '');
  const inCart = cart.includes(course.id);
  const discountPct = getDiscountPercentage(course);
  const currentPrice = getCurrentPrice(course);
  const hasDiscount = currentPrice < course.price && !course.is_free;

  return (
    <article className={styles.card} style={width ? { width } : undefined}>
      <Link href={`/courses/${course.id}`} className={styles.thumbnailLink}>
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
      </Link>
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
              {hasDiscount && <del className={styles.origPrice}>{Math.round(course.price)}</del>}
            </span>
          )}
        </div>
      </div>
    </article>
  );
}
