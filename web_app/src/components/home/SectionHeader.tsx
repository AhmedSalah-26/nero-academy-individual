'use client';

import Link from 'next/link';
import { useApp } from '../../context/AppContext';
import styles from './SectionHeader.module.css';

interface SectionHeaderProps {
  title: string;
  subtitle?: string;
  seeAllHref?: string;
  icon?: React.ReactNode;
}

export function SectionHeader({ title, subtitle, seeAllHref, icon }: SectionHeaderProps) {
  const { lang } = useApp();

  return (
    <div className={styles.header}>
      <div className={styles.titles}>
        {icon && <span className={styles.icon}>{icon}</span>}
        <div>
          <h2 className={styles.title}>{title}</h2>
          {subtitle && <p className={styles.subtitle}>{subtitle}</p>}
        </div>
      </div>
      {seeAllHref && (
        <Link href={seeAllHref} className={styles.seeAll}>
          {lang === 'ar' ? 'عرض الكل' : 'See All'}
          <span className={styles.seeAllArrow}>&larr;</span>
        </Link>
      )}
    </div>
  );
}
