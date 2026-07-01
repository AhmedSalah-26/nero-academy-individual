'use client';

import { type ReactNode } from 'react';
import styles from './FilterChips.module.css';

interface FilterChipItem {
  id: string;
  label: string;
  count?: number;
  icon?: ReactNode;
}

interface FilterChipsProps {
  items: FilterChipItem[];
  selected: string[];
  onChange: (selected: string[]) => void;
  multiple?: boolean;
  className?: string;
}

export default function FilterChips({
  items,
  selected,
  onChange,
  multiple = false,
  className,
}: FilterChipsProps) {
  const handleClick = (id: string) => {
    if (multiple) {
      if (selected.includes(id)) {
        onChange(selected.filter((s) => s !== id));
      } else {
        onChange([...selected, id]);
      }
    } else {
      onChange(selected.includes(id) ? [] : [id]);
    }
  };

  return (
    <div className={`${styles.container} ${className || ''}`}>
      {items.map((item) => (
        <button
          key={item.id}
          className={`${styles.chip} ${selected.includes(item.id) ? styles.selected : ''}`}
          onClick={() => handleClick(item.id)}
          type="button"
        >
          {item.icon && <span className={styles.icon}>{item.icon}</span>}
          {item.label}
          {item.count !== undefined && <span className={styles.count}>{item.count}</span>}
        </button>
      ))}
    </div>
  );
}
