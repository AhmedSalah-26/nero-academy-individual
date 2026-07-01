'use client';

import { useOnlineStatus } from '../lib/hooks/useOnlineStatus';
import { WifiOff, Refresh } from '@mui/icons-material';
import { useState, useEffect } from 'react';
import styles from './OfflineIndicator.module.css';

export default function OfflineIndicator() {
  const isOnline = useOnlineStatus();
  const [visible, setVisible] = useState(false);
  const [exiting, setExiting] = useState(false);

  useEffect(() => {
    if (!isOnline) {
      setVisible(true);
      setExiting(false);
    } else if (visible) {
      setExiting(true);
      const timer = window.setTimeout(() => { setVisible(false); setExiting(false); }, 3000);
      return () => window.clearTimeout(timer);
    }
  }, [isOnline, visible]);

  if (!visible) return null;

  const lang = document.documentElement.lang || 'ar';

  return (
    <div className={`${styles.banner} ${exiting ? styles.bannerExit : styles.bannerEnter}`}>
      <WifiOff fontSize="small" />
      <span>{lang === 'ar' ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection'}</span>
      {isOnline && (
        <button onClick={() => window.location.reload()} className={styles.retryBtn}>
          <Refresh fontSize="small" />
          <span>{lang === 'ar' ? 'إعادة' : 'Retry'}</span>
        </button>
      )}
    </div>
  );
}
