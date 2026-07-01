'use client';

import { useRouter } from 'next/navigation';
import ArrowBack from '@mui/icons-material/ArrowBack';
import styles from './AppBackButton.module.css';

interface AppBackButtonProps {
  onClick?: () => void;
  label?: string;
  className?: string;
}

export default function AppBackButton({ onClick, label, className }: AppBackButtonProps) {
  const router = useRouter();

  const handleClick = () => {
    if (onClick) {
      onClick();
    } else {
      router.back();
    }
  };

  return (
    <button className={`${styles.backButton} ${className || ''}`} onClick={handleClick} type="button">
      <span className={styles.icon}>
        <ArrowBack fontSize="small" />
      </span>
      {label && <span className={styles.label}>{label}</span>}
    </button>
  );
}
