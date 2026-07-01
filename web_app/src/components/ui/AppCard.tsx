import { type ReactNode, type CSSProperties } from 'react';
import styles from './AppCard.module.css';

interface AppCardProps {
  variant?: 'elevated' | 'outlined' | 'filled';
  pressable?: boolean;
  onClick?: () => void;
  children?: ReactNode;
  className?: string;
  style?: CSSProperties;
}

export default function AppCard({
  variant = 'elevated',
  pressable = false,
  onClick,
  children,
  className,
  style,
}: AppCardProps) {
  const classNames = [
    styles.card,
    styles[variant],
    pressable ? styles.pressable : '',
    className,
  ].filter(Boolean).join(' ');

  return (
    <div
      className={classNames}
      onClick={onClick}
      role={pressable ? 'button' : undefined}
      tabIndex={pressable ? 0 : undefined}
      style={style}
    >
      {children}
    </div>
  );
}
