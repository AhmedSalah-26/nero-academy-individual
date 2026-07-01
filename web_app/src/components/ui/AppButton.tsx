'use client';

import { type ReactNode, type ButtonHTMLAttributes } from 'react';
import { CircularProgress } from '@mui/material';
import styles from './AppButton.module.css';

interface AppButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'type'> {
  variant?: 'primary' | 'secondary' | 'outline' | 'text' | 'success' | 'error';
  size?: 'small' | 'medium' | 'large';
  loading?: boolean;
  disabled?: boolean;
  fullWidth?: boolean;
  startIcon?: ReactNode;
  endIcon?: ReactNode;
  onClick?: () => void;
  children?: ReactNode;
  type?: 'button' | 'submit' | 'reset';
  className?: string;
}

export default function AppButton({
  variant = 'primary',
  size = 'medium',
  loading = false,
  disabled = false,
  fullWidth = false,
  startIcon,
  endIcon,
  onClick,
  children,
  type = 'button',
  className,
  ...rest
}: AppButtonProps) {
  const classNames = [
    styles.button,
    styles[variant],
    styles[size],
    fullWidth ? styles.fullWidth : '',
    className,
  ].filter(Boolean).join(' ');

  return (
    <button
      className={classNames}
      onClick={onClick}
      disabled={disabled || loading}
      type={type}
      {...rest}
    >
      {loading && (
        <span className={styles.loadingSpinner}>
          <CircularProgress size={size === 'small' ? 14 : size === 'large' ? 20 : 16} color="inherit" />
        </span>
      )}
      {!loading && startIcon && <span className={`${styles.icon} ${styles.startIcon}`}>{startIcon}</span>}
      {!loading && children}
      {!loading && endIcon && <span className={`${styles.icon} ${styles.endIcon}`}>{endIcon}</span>}
    </button>
  );
}
