import styles from './SectionHeader.module.css';

interface SectionHeaderProps {
  title: string;
  subtitle?: string;
  actionLabel?: string;
  onAction?: () => void;
  className?: string;
}

export default function SectionHeader({
  title,
  subtitle,
  actionLabel,
  onAction,
  className,
}: SectionHeaderProps) {
  return (
    <div className={`${styles.container} ${className || ''}`}>
      <div className={styles.content}>
        <h2 className={styles.title}>{title}</h2>
        {subtitle && <p className={styles.subtitle}>{subtitle}</p>}
      </div>
      {actionLabel && onAction && (
        <div className={styles.action}>
          <button className={styles.actionButton} onClick={onAction} type="button">
            {actionLabel}
          </button>
        </div>
      )}
    </div>
  );
}
