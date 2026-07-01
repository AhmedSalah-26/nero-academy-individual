'use client';

import Star from '@mui/icons-material/Star';
import StarHalf from '@mui/icons-material/StarHalf';
import StarBorder from '@mui/icons-material/StarBorder';
import styles from './RatingStars.module.css';

interface RatingStarsProps {
  value: number;
  size?: 'xs' | 'sm' | 'md' | 'lg';
  interactive?: boolean;
  onChange?: (value: number) => void;
  showValue?: boolean;
  count?: number;
  className?: string;
}

export default function RatingStars({
  value,
  size = 'md',
  interactive = false,
  onChange,
  showValue = false,
  count,
  className,
}: RatingStarsProps) {
  const stars = [];
  const clampedValue = Math.min(5, Math.max(0, value));

  for (let i = 1; i <= 5; i++) {
    if (clampedValue >= i) {
      stars.push(
        <span
          key={i}
          className={styles.star}
          onClick={interactive ? () => onChange?.(i) : undefined}
        >
          <Star fontSize="inherit" />
        </span>
      );
    } else if (clampedValue >= i - 0.5) {
      stars.push(
        <span
          key={i}
          className={styles.star}
          onClick={interactive ? () => onChange?.(i - 0.5) : undefined}
        >
          <StarHalf fontSize="inherit" />
        </span>
      );
    } else {
      stars.push(
        <span
          key={i}
          className={`${styles.star} ${styles.empty}`}
          onClick={interactive ? () => onChange?.(i) : undefined}
        >
          <StarBorder fontSize="inherit" />
        </span>
      );
    }
  }

  return (
    <div
      className={`${styles.container} ${styles[size]} ${interactive ? styles.interactive : ''} ${className || ''}`}
      role={interactive ? 'slider' : 'img'}
      aria-label={`Rating: ${clampedValue} out of 5`}
      aria-valuenow={clampedValue}
      aria-valuemin={0}
      aria-valuemax={5}
    >
      {stars}
      {showValue && <span className={styles.value}>{clampedValue}</span>}
      {count !== undefined && <span className={styles.count}>({count})</span>}
    </div>
  );
}
