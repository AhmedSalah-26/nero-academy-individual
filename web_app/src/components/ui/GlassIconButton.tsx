import { type ReactNode } from 'react';
import styles from './GlassIconButton.module.css';

interface GlassIconButtonProps {
  icon: ReactNode;
  onClick?: () => void;
  badge?: number;
  dot?: boolean;
  size?: 'small' | 'medium' | 'large';
  className?: string;
  ariaLabel?: string;
}

export default function GlassIconButton({
  icon,
  onClick,
  badge,
  dot = false,
  size = 'medium',
  className,
  ariaLabel,
}: GlassIconButtonProps) {
  const classNames = [
    styles.iconButton,
    styles[size],
    className,
  ].filter(Boolean).join(' ');

  return (
    <button className={classNames} onClick={onClick} type="button" aria-label={ariaLabel}>
      {icon}
      {badge !== undefined && badge > 0 && <span className={styles.badge}>{badge}</span>}
      {dot && <span className={styles.dot} />}
    </button>
  );
}
