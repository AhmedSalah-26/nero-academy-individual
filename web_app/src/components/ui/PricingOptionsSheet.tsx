'use client';

import { Close } from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import ResponsiveDialog from './ResponsiveDialog';
import styles from './PricingOptionsSheet.module.css';

interface PricingOption {
  id: string;
  label_ar: string;
  label_en: string;
  price: number;
  originalPrice?: number;
  isFree?: boolean;
  features?: string[];
}

interface PricingOptionsSheetProps {
  open: boolean;
  onClose: () => void;
  options: PricingOption[];
  onSelect?: (optionId: string) => void;
  selectedId?: string;
}

export default function PricingOptionsSheet({
  open,
  onClose,
  options,
  onSelect,
  selectedId,
}: PricingOptionsSheetProps) {
  const { lang, t } = useApp();

  return (
    <ResponsiveDialog
      open={open}
      onClose={onClose}
      title={lang === 'ar' ? 'خيارات الشراء' : 'Pricing Options'}
      maxWidth="sm"
    >
      <div className={styles.list}>
        {options.map((opt) => {
          const isSelected = selectedId === opt.id;
          const label = lang === 'ar' ? opt.label_ar : opt.label_en;

          return (
            <button
              key={opt.id}
              className={`${styles.option} ${isSelected ? styles.selected : ''}`}
              onClick={() => onSelect?.(opt.id)}
              type="button"
            >
              <div className={styles.optionHeader}>
                <span className={styles.optionLabel}>{label}</span>
                <div className={styles.optionPrice}>
                  {opt.isFree ? (
                    <span className={styles.free}>{t.free}</span>
                  ) : (
                    <>
                      <span className={styles.price}>{opt.price} {t.egp}</span>
                      {opt.originalPrice && opt.originalPrice > opt.price && (
                        <span className={styles.originalPrice}>{opt.originalPrice} {t.egp}</span>
                      )}
                    </>
                  )}
                </div>
              </div>

              {opt.features && opt.features.length > 0 && (
                <ul className={styles.features}>
                  {opt.features.map((feat, i) => (
                    <li key={i}>{feat}</li>
                  ))}
                </ul>
              )}

              {isSelected && <div className={styles.checkmark} />}
            </button>
          );
        })}
      </div>
    </ResponsiveDialog>
  );
}
