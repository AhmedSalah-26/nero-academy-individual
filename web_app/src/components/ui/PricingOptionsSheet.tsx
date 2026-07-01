'use client';

import { Close } from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import ResponsiveDialog from './ResponsiveDialog';
import styles from './PricingOptionsSheet.module.css';

interface PricingOption {
  label: string;
  price: number;
  duration_days?: number;
  originalPrice?: number;
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
          const isSelected = selectedId === opt.label;

          return (
            <button
              key={opt.label}
              className={`${styles.option} ${isSelected ? styles.selected : ''}`}
              onClick={() => onSelect?.(opt.label)}
              type="button"
            >
              <div className={styles.optionHeader}>
                <span className={styles.optionLabel}>{opt.label}</span>
                <div className={styles.optionPrice}>
                  {opt.price === 0 ? (
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

              {opt.duration_days && (
                <p className={styles.duration}>
                  {`مدة الوصول: ${opt.duration_days} يوم`}
                </p>
              )}

              {isSelected && <div className={styles.checkmark} />}
            </button>
          );
        })}
      </div>
    </ResponsiveDialog>
  );
}
