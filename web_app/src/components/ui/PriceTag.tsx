import styles from './PriceTag.module.css';
import { NumberUtils } from '../../lib/formatters';

interface PriceTagProps {
  price: number;
  originalPrice?: number;
  free?: boolean;
  discount?: number;
  size?: 'sm' | 'md' | 'lg';
  currency?: string;
  className?: string;
}

export default function PriceTag({
  price,
  originalPrice,
  free = false,
  discount,
  size = 'md',
  currency,
  className,
}: PriceTagProps) {
  const computedDiscount =
    discount ?? (originalPrice && originalPrice > price
      ? Math.round(((originalPrice - price) / originalPrice) * 100)
      : undefined);

  return (
    <div className={`${styles.container} ${styles[size]} ${className || ''}`}>
      {free ? (
        <span className={styles.free}>Free</span>
      ) : (
        <>
          <span className={styles.price}>
            {currency ? `${price} ${currency}` : NumberUtils.formatPrice(price)}
          </span>
          {originalPrice && originalPrice > price && (
            <span className={styles.originalPrice}>
              {currency ? `${originalPrice} ${currency}` : NumberUtils.formatPrice(originalPrice)}
            </span>
          )}
          {computedDiscount && computedDiscount > 0 && (
            <span className={styles.discountBadge}>-{computedDiscount}%</span>
          )}
        </>
      )}
    </div>
  );
}
