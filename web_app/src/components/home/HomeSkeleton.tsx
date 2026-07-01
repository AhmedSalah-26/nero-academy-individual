'use client';

import styles from './HomeSkeleton.module.css';

export function HomeSkeleton() {
  return (
    <div className={styles.page}>
      <div className={styles.bannerShimmer} />
      <div className={styles.chipsRow}>
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className={styles.chipShimmer} />
        ))}
      </div>
      <div className={styles.sectionShimmer} />
      <div className={styles.horizontalRow}>
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className={styles.verticalCardShimmer} />
        ))}
      </div>
      <div className={styles.sectionShimmer} />
      <div className={styles.verticalList}>
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className={styles.horizontalCardShimmer} />
        ))}
      </div>
    </div>
  );
}
