'use client';

import WifiOff from '@mui/icons-material/WifiOff';
import CloudOff from '@mui/icons-material/CloudOff';
import SearchOff from '@mui/icons-material/SearchOff';
import Lock from '@mui/icons-material/Lock';
import ErrorOutline from '@mui/icons-material/Error';
import AppButton from './AppButton';
import styles from './ErrorState.module.css';

type ErrorType = 'network' | 'server' | 'notFound' | 'unauthorized' | 'generic';

const iconMap: Record<ErrorType, React.ReactNode> = {
  network: <WifiOff />,
  server: <CloudOff />,
  notFound: <SearchOff />,
  unauthorized: <Lock />,
  generic: <ErrorOutline />,
};

interface ErrorStateProps {
  type?: ErrorType;
  density?: 'fullPage' | 'section' | 'compact';
  title?: string;
  message?: string;
  onRetry?: () => void;
  onGoBack?: () => void;
  className?: string;
}

export default function ErrorState({
  type = 'generic',
  density = 'fullPage',
  title,
  message,
  onRetry,
  onGoBack,
  className,
}: ErrorStateProps) {
  return (
    <div className={`${styles.container} ${styles[density]} ${className || ''}`}>
      <div className={styles.iconWrapper}>{iconMap[type]}</div>
      {title && <h3 className={styles.title}>{title}</h3>}
      {message && <p className={styles.message}>{message}</p>}
      {(onRetry || onGoBack) && (
        <div className={styles.actions}>
          {onRetry && (
            <AppButton variant="primary" size={density === 'compact' ? 'small' : 'medium'} onClick={onRetry}>
              Retry
            </AppButton>
          )}
          {onGoBack && (
            <AppButton variant="outline" size={density === 'compact' ? 'small' : 'medium'} onClick={onGoBack}>
              Go Back
            </AppButton>
          )}
        </div>
      )}
    </div>
  );
}
