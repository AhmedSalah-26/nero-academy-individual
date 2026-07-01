'use client';

import { CircularProgress } from '@mui/material';
import styles from './LoadingState.module.css';

interface LoadingStateProps {
  density?: 'fullPage' | 'section' | 'compact';
  message?: string;
  className?: string;
}

export default function LoadingState({
  density = 'fullPage',
  message,
  className,
}: LoadingStateProps) {
  return (
    <div className={`${styles.container} ${styles[density]} ${className || ''}`}>
      <span className={styles.spinnerWrapper}>
        <CircularProgress
          size={density === 'compact' ? 20 : density === 'section' ? 28 : 36}
          color="primary"
        />
      </span>
      {message && <span className={styles.message}>{message}</span>}
    </div>
  );
}
