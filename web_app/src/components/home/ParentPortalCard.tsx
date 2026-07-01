'use client';

import Link from 'next/link';
import { useApp } from '../../context/AppContext';
import styles from './ParentPortalCard.module.css';

export function ParentPortalCard() {
  const { lang } = useApp();

  return (
    <div className={styles.card}>
      <div className={styles.icon}>
        👨‍👩‍👧‍👦
      </div>
      <div className={styles.info}>
        <h3 className={styles.title}>
          {lang === 'ar' ? 'بوابة ولي الأمر' : 'Parent Portal'}
        </h3>
        <p className={styles.subtitle}>
          {lang === 'ar' ? 'تابع تقدم أبنائك ونتائجهم' : "Track your children's progress"}
        </p>
      </div>
      <Link href="/parent-portal" className={styles.enterBtn}>
        {lang === 'ar' ? 'دخول' : 'Enter'}
      </Link>
    </div>
  );
}
