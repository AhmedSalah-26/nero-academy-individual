'use client';

import Search from '@mui/icons-material/Search';
import Close from '@mui/icons-material/Close';
import Tune from '@mui/icons-material/Tune';
import styles from './GlassSearchBar.module.css';

interface GlassSearchBarProps {
  value?: string;
  onChange?: (value: string) => void;
  onSubmit?: (value: string) => void;
  placeholder?: string;
  onFilterClick?: () => void;
  className?: string;
}

export default function GlassSearchBar({
  value = '',
  onChange,
  onSubmit,
  placeholder = 'Search...',
  onFilterClick,
  className,
}: GlassSearchBarProps) {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit?.(value);
  };

  return (
    <form className={`${styles.searchBar} ${className || ''}`} onSubmit={handleSubmit}>
      <span className={styles.searchIcon}>
        <Search fontSize="small" />
      </span>
      <input
        className={styles.input}
        type="text"
        value={value}
        onChange={(e) => onChange?.(e.target.value)}
        placeholder={placeholder}
      />
      {value && (
        <button
          className={styles.clearButton}
          type="button"
          onClick={() => onChange?.('')}
          aria-label="Clear search"
        >
          <Close fontSize="small" />
        </button>
      )}
      {onFilterClick && (
        <button
          className={styles.filterButton}
          type="button"
          onClick={onFilterClick}
          aria-label="Filters"
        >
          <Tune fontSize="small" />
        </button>
      )}
    </form>
  );
}
