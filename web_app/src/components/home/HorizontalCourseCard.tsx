'use client';

import Link from 'next/link';
import { useApp } from '../../context/AppContext';
import {
  getBaseCoursePrice,
  getCourseDiscountPercentage,
  getEffectiveCoursePrice,
} from '../../lib/pricing';
import type { CourseData } from './VerticalCourseCard';
import styles from './HorizontalCourseCard.module.css';

interface HorizontalCourseCardProps {
  course: CourseData;
  isWishlisted: boolean;
  onWishlistToggle: () => void;
}

function formatCount(count: number): string {
  if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
  if (count >= 1000) return `${(count / 1000).toFixed(1)}k`;
  return count.toString();
}

export function HorizontalCourseCard({ course, isWishlisted, onWishlistToggle }: HorizontalCourseCardProps) {
  const { lang } = useApp();
  const title = lang === 'ar' ? (course.title_ar || course.title_en || '') : (course.title_en || course.title_ar || '');
  const currentPrice = getEffectiveCoursePrice(course);
  const basePrice = getBaseCoursePrice(course);
  const discountPct = getCourseDiscountPercentage(course);
  const hasDiscount = discountPct != null;
  const isNew = course.is_flash_sale && discountPct;

  return (
    <Link href={`/courses/${course.id}`} className={styles.card}>
      <div className={styles.thumbnail}>
        {course.thumbnail_url ? (
          <img src={course.thumbnail_url} alt={title} className={styles.img} />
        ) : (
          <div className={styles.thumbnailFallback}>▶</div>
        )}
        {discountPct && course.is_flash_sale && (
          <span className={styles.discountBadge}>{discountPct}%</span>
        )}
        <button
          className={`${styles.wishlist} ${isWishlisted ? styles.wishlistActive : ''}`}
          onClick={(e) => { e.preventDefault(); e.stopPropagation(); onWishlistToggle(); }}
          aria-label="Wishlist"
        >
          {isWishlisted ? '❤️' : '🤍'}
        </button>
      </div>
      <div className={styles.body}>
        <div className={styles.titleRow}>
          <h3 className={styles.title}>{title}</h3>
          {isNew && <span className={styles.newBadge}>{lang === 'ar' ? 'جديد' : 'New'}</span>}
        </div>
        {course.instructor_name && (
          <p className={styles.instructor}>👤 {course.instructor_name}</p>
        )}
        <div className={styles.bottomRow}>
          <span className={styles.rating}>
            <span className={styles.star}>★</span> {(course.rating || 5.0).toFixed(1)}
          </span>
          {course.is_free ? (
            <span className={styles.freePrice}>{lang === 'ar' ? 'مجاني' : 'Free'}</span>
          ) : (
            <span className={styles.price}>
              {hasDiscount && <del className={styles.del}>{Math.round(basePrice)}</del>}
              {course.currency || (lang === 'ar' ? 'ج.م' : 'EGP')} {Math.round(currentPrice)}
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}
