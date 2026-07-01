'use client';

import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import CheckCircle from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import Warning from '@mui/icons-material/Warning';
import Info from '@mui/icons-material/Info';
import styles from './Toast.module.css';

type ToastType = 'success' | 'error' | 'warning' | 'info';

interface ToastItem {
  id: string;
  type: ToastType;
  message: string;
  exiting?: boolean;
}

interface ToastContextValue {
  showToast: (type: ToastType, message: string, duration?: number) => void;
}

const ToastContext = createContext<ToastContextValue>({ showToast: () => {} });

export function useToast() {
  return useContext(ToastContext);
}

const iconMap: Record<ToastType, React.ReactNode> = {
  success: <CheckCircle fontSize="small" />,
  error: <ErrorIcon fontSize="small" />,
  warning: <Warning fontSize="small" />,
  info: <Info fontSize="small" />,
};

let toastCounter = 0;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const dismissToast = useCallback((id: string) => {
    setToasts((prev) =>
      prev.map((t) => (t.id === id ? { ...t, exiting: true } : t))
    );
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 250);
  }, []);

  const showToast = useCallback(
    (type: ToastType, message: string, duration = 3000) => {
      const id = `toast-${++toastCounter}`;
      const newToast: ToastItem = { id, type, message };
      setToasts((prev) => {
        const updated = [...prev, newToast];
        if (updated.length > 3) {
          const oldest = updated[0];
          setTimeout(() => dismissToast(oldest.id), 0);
          return updated.slice(-3);
        }
        return updated;
      });
      setTimeout(() => dismissToast(id), duration);
    },
    [dismissToast]
  );

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      {typeof window !== 'undefined' &&
        createPortal(
          <div className={styles.toastContainer}>
            {toasts.map((toast) => (
              <div
                key={toast.id}
                className={`${styles.toast} ${styles[toast.type]} ${toast.exiting ? styles.toastExit : ''}`}
                role="alert"
              >
                <span className={styles.icon}>{iconMap[toast.type]}</span>
                <span className={styles.message}>{toast.message}</span>
              </div>
            ))}
          </div>,
          document.body
        )}
    </ToastContext.Provider>
  );
}

export function showToast(type: ToastType, message: string, duration = 3000) {
  const event = new CustomEvent('show-toast', {
    detail: { type, message, duration },
  });
  window.dispatchEvent(event);
}
