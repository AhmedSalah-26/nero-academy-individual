'use client';

import Link from 'next/link';
import { useApp } from '../../context/AppContext';
import styles from './CategoryChips.module.css';

interface Category {
  id: string;
  name_ar?: string;
  name_en?: string;
  icon_name?: string;
}

interface CategoryChipsProps {
  categories: Category[];
  selectedId: string | null;
  onSelect: (id: string | null) => void;
}

const iconMap: Record<string, string> = {
  code: '💻',
  design: '🎨',
  business: '💼',
  marketing: '📣',
  photography: '📷',
  music: '🎵',
  health: '❤️',
  language: '🌐',
  science: '🔬',
  math: '🧮',
};

export function CategoryChips({ categories, selectedId, onSelect }: CategoryChipsProps) {
  const { lang } = useApp();

  return (
    <div className={styles.scroll}>
      <button
        className={`${styles.chip} ${selectedId === null ? styles.active : ''}`}
        onClick={() => onSelect(null)}
      >
        <span className={styles.chipIcon}>📱</span>
        <span className={styles.chipLabel}>{lang === 'ar' ? 'الكل' : 'All'}</span>
      </button>
      {categories.map((cat) => (
        <button
          key={cat.id}
          className={`${styles.chip} ${selectedId === cat.id ? styles.active : ''}`}
          onClick={() => onSelect(cat.id)}
        >
          <span className={styles.chipIcon}>{iconMap[cat.icon_name || ''] || '📂'}</span>
          <span className={styles.chipLabel}>
            {lang === 'ar' ? (cat.name_ar || cat.name_en || '') : (cat.name_en || cat.name_ar || '')}
          </span>
        </button>
      ))}
    </div>
  );
}
