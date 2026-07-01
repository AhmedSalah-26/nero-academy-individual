'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { useApp } from '../../context/AppContext';
import styles from './FlashSaleSection.module.css';

interface FlashSaleProps {
  children: React.ReactNode;
  endTime?: string;
}

export function FlashSaleSection({ children, endTime }: FlashSaleProps) {
  const { lang } = useApp();
  const [remaining, setRemaining] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (!endTime) return;
    const end = new Date(endTime).getTime();
    const update = () => {
      const diff = Math.max(0, Math.floor((end - Date.now()) / 1000));
      setRemaining(diff);
    };
    update();
    timerRef.current = setInterval(update, 1000);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [endTime]);

  const formatTime = useCallback(() => {
    const d = Math.floor(remaining / 86400);
    const h = Math.floor((remaining % 86400) / 3600);
    const m = Math.floor((remaining % 3600) / 60);
    const s = remaining % 60;
    if (d > 0) return `${d}d ${h}h`;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m ${s}s`;
  }, [remaining]);

  return (
    <div>
      <div className={styles.header}>
        <div className={styles.headerLeft}>
          <span className={styles.flashIcon}>⚡</span>
          <span className={styles.headerTitle}>
            {lang === 'ar' ? 'تخفيضات فلاش' : 'Flash Sale'}
          </span>
        </div>
        {endTime && remaining > 0 && (
          <div className={styles.countdown}>
            <span className={styles.timerIcon}>⏱</span>
            <span className={styles.countdownText}>{formatTime()}</span>
          </div>
        )}
      </div>
      <div className={styles.list}>{children}</div>
    </div>
  );
}
