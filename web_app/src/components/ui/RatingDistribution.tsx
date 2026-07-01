'use client';

import Star from '@mui/icons-material/Star';
import StarBorder from '@mui/icons-material/StarBorder';
import styles from './RatingDistribution.module.css';

interface RatingBucket {
  stars: number;
  count: number;
  percentage: number;
}

interface RatingDistributionProps {
  buckets: RatingBucket[];
  className?: string;
}

export default function RatingDistribution({ buckets, className }: RatingDistributionProps) {
  return (
    <div className={`${styles.container} ${className || ''}`}>
      {buckets.map((bucket) => (
        <div key={bucket.stars} className={styles.row}>
          <span className={styles.starLabel}>{bucket.stars}</span>
          <Star fontSize="small" className={styles.starIcon} />
          <div className={styles.barTrack}>
            <div
              className={styles.barFill}
              style={{ width: `${bucket.percentage}%` }}
            />
          </div>
          <span className={styles.percentage}>{bucket.percentage}%</span>
          <span className={styles.count}>({bucket.count})</span>
        </div>
      ))}
    </div>
  );
}
