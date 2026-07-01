'use client';

import { useState, useEffect } from 'react';
import { Close, Star } from '@mui/icons-material';
import ResponsiveDialog from './ResponsiveDialog';
import FilterChips from './FilterChips';
import AppButton from './AppButton';
import { useApp } from '../../context/AppContext';
import styles from './CourseFilterSheet.module.css';

interface Category {
  id: string;
  name_ar: string;
  name_en: string;
}

export interface CourseFilterState {
  categories: string[];
  priceMin: number;
  priceMax: number;
  levels: string[];
  rating: string;
  sort: string;
}

interface CourseFilterSheetProps {
  open: boolean;
  onClose: () => void;
  onApply: (filters: CourseFilterState) => void;
  categories: Category[];
  initialFilters?: CourseFilterState;
}

const STORAGE_KEY = 'nero_price_range';

export default function CourseFilterSheet({
  open,
  onClose,
  onApply,
  categories,
  initialFilters,
}: CourseFilterSheetProps) {
  const { lang, t } = useApp();

  const [selectedCategories, setSelectedCategories] = useState<string[]>(
    initialFilters?.categories || []
  );
  const [priceMin, setPriceMin] = useState(initialFilters?.priceMin ?? 0);
  const [priceMax, setPriceMax] = useState(initialFilters?.priceMax ?? 500);
  const [selectedLevels, setSelectedLevels] = useState<string[]>(
    initialFilters?.levels || []
  );
  const [selectedRating, setSelectedRating] = useState<string>(
    initialFilters?.rating || 'all'
  );
  const [selectedSort, setSelectedSort] = useState<string>(
    initialFilters?.sort || 'popular'
  );

  useEffect(() => {
    if (open && initialFilters) {
      setSelectedCategories(initialFilters.categories || []);
      setPriceMin(initialFilters.priceMin ?? 0);
      setPriceMax(initialFilters.priceMax ?? 500);
      setSelectedLevels(initialFilters.levels || []);
      setSelectedRating(initialFilters.rating || 'all');
      setSelectedSort(initialFilters.sort || 'popular');
    }
  }, [open, initialFilters]);

  const categoryItems = categories.map((c) => ({
    id: c.id,
    label: lang === 'ar' ? c.name_ar : c.name_en,
  }));

  const levelItems = [
    { id: 'beginner', label: t.beginner },
    { id: 'intermediate', label: t.intermediate },
    { id: 'advanced', label: t.advanced },
  ];

  const ratingItems = [
    { id: 'all', label: lang === 'ar' ? 'الكل' : 'All' },
    { id: '4plus', label: '4+ ★' },
    { id: '3plus', label: '3+ ★' },
    { id: '2plus', label: '2+ ★' },
  ];

  const sortItems = [
    { id: 'popular', label: lang === 'ar' ? 'الأكثر شهرة' : 'Most popular' },
    { id: 'newest', label: t.newest },
    { id: 'rating', label: t.highestRated },
    { id: 'priceLow', label: t.priceLowHigh },
    { id: 'priceHigh', label: t.priceHighLow },
  ];

  const handleClear = () => {
    setSelectedCategories([]);
    setPriceMin(0);
    setPriceMax(500);
    setSelectedLevels([]);
    setSelectedRating('all');
    setSelectedSort('popular');
  };

  const hasActiveFilters =
    selectedCategories.length > 0 ||
    priceMin > 0 ||
    priceMax < 500 ||
    selectedLevels.length > 0 ||
    selectedRating !== 'all';

  const handleApply = () => {
    onApply({
      categories: selectedCategories,
      priceMin,
      priceMax,
      levels: selectedLevels,
      rating: selectedRating,
      sort: selectedSort,
    });
    onClose();
  };

  return (
    <ResponsiveDialog
      open={open}
      onClose={onClose}
      title={lang === 'ar' ? 'تصفية الكورسات' : 'Filter Courses'}
      maxWidth="md"
      actions={
        <div className={styles.actions}>
          {hasActiveFilters && (
            <AppButton
              variant="text"
              size="small"
              onClick={handleClear}
              startIcon={<Close fontSize="small" />}
            >
              {t.clearAll}
            </AppButton>
          )}
          <AppButton variant="primary" onClick={handleApply} fullWidth>
            {lang === 'ar' ? 'تطبيق' : 'Apply'}
          </AppButton>
        </div>
      }
    >
      <div className={styles.content}>
        <div className={styles.section}>
          <h3 className={styles.sectionTitle}>{t.sortBy}</h3>
          <FilterChips
            items={sortItems}
            selected={[selectedSort]}
            onChange={(v) => setSelectedSort(v[0] || 'popular')}
            multiple={false}
          />
        </div>

        {categoryItems.length > 0 && (
          <div className={styles.section}>
            <h3 className={styles.sectionTitle}>{t.categories}</h3>
            <FilterChips
              items={categoryItems}
              selected={selectedCategories}
              onChange={setSelectedCategories}
              multiple
            />
          </div>
        )}

        <div className={styles.section}>
          <h3 className={styles.sectionTitle}>{t.level}</h3>
          <FilterChips
            items={levelItems}
            selected={selectedLevels}
            onChange={setSelectedLevels}
            multiple
          />
        </div>

        <div className={styles.section}>
          <h3 className={styles.sectionTitle}>{t.priceRange}</h3>
          <div className={styles.rangeRow}>
            <span className={styles.rangeLabel}>{priceMin} {t.egp}</span>
            <div className={styles.rangeInputs}>
              <input
                type="range"
                min={0}
                max={500}
                step={10}
                value={priceMin}
                onChange={(e) => {
                  const val = Number(e.target.value);
                  if (val <= priceMax) setPriceMin(val);
                }}
                className={styles.rangeSlider}
              />
              <input
                type="range"
                min={0}
                max={500}
                step={10}
                value={priceMax}
                onChange={(e) => {
                  const val = Number(e.target.value);
                  if (val >= priceMin) setPriceMax(val);
                }}
                className={styles.rangeSlider}
              />
            </div>
            <span className={styles.rangeLabel}>{priceMax} {t.egp}</span>
          </div>
          <div className={styles.rangeTrack}>
            <div
              className={styles.rangeFill}
              style={{
                left: `${(priceMin / 500) * 100}%`,
                right: `${100 - (priceMax / 500) * 100}%`,
              }}
            />
          </div>
        </div>

        <div className={styles.section}>
          <h3 className={styles.sectionTitle}>{t.rating}</h3>
          <FilterChips
            items={ratingItems}
            selected={[selectedRating]}
            onChange={(v) => setSelectedRating(v[0] || 'all')}
            multiple={false}
          />
        </div>
      </div>
    </ResponsiveDialog>
  );
}
