'use client';

import { useEffect, useCallback, type ReactNode } from 'react';
import Close from '@mui/icons-material/Close';
import styles from './ResponsiveDialog.module.css';

interface ResponsiveDialogProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children?: ReactNode;
  actions?: ReactNode;
  maxWidth?: 'sm' | 'md' | 'lg';
  destructive?: boolean;
  className?: string;
}

export default function ResponsiveDialog({
  open,
  onClose,
  title,
  children,
  actions,
  maxWidth = 'md',
  destructive = false,
  className,
}: ResponsiveDialogProps) {
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    },
    [onClose]
  );

  useEffect(() => {
    if (open) {
      document.addEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'hidden';
    }
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = '';
    };
  }, [open, handleKeyDown]);

  if (!open) return null;

  return (
    <div className={styles.overlay} onClick={onClose} role="presentation">
      <div
        className={`${styles.dialog} ${styles[maxWidth]} ${destructive ? styles.destructive : ''} ${className || ''}`}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label={title}
      >
        <div className={styles.header}>
          <h2 className={styles.title}>{title}</h2>
          <button className={styles.closeButton} onClick={onClose} aria-label="Close" type="button">
            <Close fontSize="small" />
          </button>
        </div>
        <div className={styles.body}>{children}</div>
        {actions && <div className={styles.footer}>{actions}</div>}
      </div>
    </div>
  );
}
