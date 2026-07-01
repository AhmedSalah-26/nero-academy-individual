'use client';

import Link from 'next/link';
import { useApp } from '../../context/AppContext';
import styles from './ContinueLearningCard.module.css';

interface ContinueLearningCardProps {
  id: string;
  title: string;
  thumbnailUrl?: string;
  progress: number;
  completedLessons: number;
  totalLessons: number;
}

export function ContinueLearningCard({
  id, title, thumbnailUrl, progress, completedLessons, totalLessons,
}: ContinueLearningCardProps) {
  const { lang } = useApp();

  return (
    <Link href={`/learn/${id}`} className={styles.card}>
      <div className={styles.thumbnail}>
        {thumbnailUrl ? (
          <img src={thumbnailUrl} alt={title} className={styles.img} />
        ) : (
          <div className={styles.fallback}>▶</div>
        )}
        <div className={styles.progressTrack}>
          <div className={styles.progressFill} style={{ width: `${progress}%` }} />
        </div>
      </div>
      <div className={styles.body}>
        <span className={styles.label}>
          {lang === 'ar' ? 'متابعة التعلم' : 'CONTINUE LEARNING'}
        </span>
        <h3 className={styles.title}>{title}</h3>
        <div className={styles.meta}>
          <span>{lang === 'ar' ? 'مكتمل' : 'Completed'} {Math.round(progress)}%</span>
          <span>{completedLessons}/{totalLessons} {lang === 'ar' ? 'درس' : 'lessons'}</span>
        </div>
        <button className={styles.resumeBtn}>
          ▶ {lang === 'ar' ? 'متابعة' : 'Resume'}
        </button>
      </div>
    </Link>
  );
}
