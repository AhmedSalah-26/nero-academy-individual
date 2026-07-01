'use client';

import React, { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { Delete, ShoppingCart, Sell, Error as ErrorIcon, ArrowForward, ArrowBack, ExpandMore, ExpandLess, CheckCircle, Close } from '@mui/icons-material';
import { ShimmerEffect, EmptyState, RatingStars, PriceTag } from '../../components/ui';
import { NumberUtils } from '../../lib/formatters';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface CartItem {
  id: string;
  title_ar: string;
  title_en: string;
  thumbnail_url: string;
  price: number;
  discount_price: number;
  is_free: boolean;
  instructor_name_ar?: string;
  instructor_name_en?: string;
  rating?: number;
  rating_count?: number;
}

interface Coupon {
  id: string;
  code: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  max_discount_amount?: number;
  min_order_amount?: number;
  start_date: string;
  end_date?: string;
  usage_limit?: number;
  usage_count: number;
}

export default function CartPage() {
  const pageRef = usePageTransition();
  const { lang, t, user, cart, removeFromCart } = useApp();
  const router = useRouter();

  const [items, setItems] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [removing, setRemoving] = useState<string | null>(null);
  const [shakeId, setShakeId] = useState<string | null>(null);

  const [couponCode, setCouponCode] = useState('');
  const [couponData, setCouponData] = useState<Coupon | null>(null);
  const [couponError, setCouponError] = useState<string | null>(null);
  const [couponSuccess, setCouponSuccess] = useState<string | null>(null);
  const [couponOpen, setCouponOpen] = useState(false);

  useEffect(() => {
    async function fetchCartItems() {
      if (cart.length === 0) {
        setItems([]);
        setLoading(false);
        return;
      }

      try {
        const { data, error } = await supabase
          .from('courses')
          .select('id, title_ar, title_en, thumbnail_url, price, discount_price, is_free, instructor_name_ar, instructor_name_en, rating, rating_count')
          .in('id', cart);

        if (data && !error) {
          setItems(data as CartItem[]);
        }
      } catch (err) {
        console.error('Error fetching cart details:', err);
      } finally {
        setLoading(false);
      }
    }

    fetchCartItems();
  }, [cart]);

  const subtotal = items.reduce((sum, item) => {
    const price = item.is_free ? 0 : (item.discount_price || item.price || 0);
    return sum + price;
  }, 0);

  let discount = 0;
  if (couponData) {
    if (couponData.discount_type === 'percentage') {
      discount = (subtotal * Number(couponData.discount_value)) / 100;
      if (couponData.max_discount_amount) {
        discount = Math.min(discount, Number(couponData.max_discount_amount));
      }
    } else {
      discount = Number(couponData.discount_value);
    }
  }

  const total = Math.max(0, subtotal - discount);

  const handleApplyCoupon = async () => {
    if (!couponCode) return;
    setCouponError(null);
    setCouponSuccess(null);

    try {
      const { data, error } = await supabase
        .from('coupons')
        .select('*')
        .eq('code', couponCode.toUpperCase().trim())
        .eq('is_active', true)
        .single();

      if (error || !data) {
        setCouponError(t.couponInvalid);
        setCouponData(null);
        return;
      }

      const now = new Date();
      const startDate = new Date(data.start_date);
      const endDate = data.end_date ? new Date(data.end_date) : null;

      if (now < startDate || (endDate && now > endDate)) {
        setCouponError(t.couponInvalid);
        setCouponData(null);
        return;
      }

      if (data.usage_limit && data.usage_count >= data.usage_limit) {
        setCouponError(t.couponInvalid);
        setCouponData(null);
        return;
      }

      if (data.min_order_amount && subtotal < data.min_order_amount) {
        setCouponError(
          lang === 'ar'
            ? `الحد الأدنى لتطبيق الكوبون هو ${data.min_order_amount} جنيه`
            : `Minimum order for this coupon is ${data.min_order_amount} EGP`
        );
        setCouponData(null);
        return;
      }

      setCouponData(data);
      setCouponSuccess(t.couponSuccess);

      sessionStorage.setItem('applied_coupon', JSON.stringify({
        id: data.id,
        code: data.code,
        discount: discount,
      }));
    } catch (err) {
      console.error(err);
      setCouponError(t.couponInvalid);
    }
  };

  const handleRemoveCoupon = () => {
    setCouponData(null);
    setCouponSuccess(null);
    setCouponCode('');
    sessionStorage.removeItem('applied_coupon');
  };

  const handleRemoveFromCart = useCallback(async (courseId: string) => {
    setRemoving(courseId);
    try {
      await removeFromCart(courseId);
    } catch {
      setShakeId(courseId);
      setTimeout(() => setShakeId(null), 600);
    } finally {
      setRemoving(null);
    }
  }, [removeFromCart]);

  const handleCheckout = () => {
    if (!user) {
      router.push('/login?redirect=/checkout');
    } else {
      sessionStorage.setItem('checkout_totals', JSON.stringify({
        subtotal,
        discount,
        total,
        couponId: couponData?.id || null,
        couponCode: couponData?.code || null
      }));
      router.push('/checkout');
    }
  };

  if (loading) {
    return (
      <div className={styles.loadingState}>
        <div className={styles.shimmerGrid}>
          <div className={styles.shimmerItems}>
            {[1, 2, 3].map((i) => (
              <div key={i} className={styles.shimmerCard}>
                <ShimmerEffect width="100px" height="60px" borderRadius="md" />
                <div className={styles.shimmerDetails}>
                  <ShimmerEffect width="70%" height="16px" borderRadius="sm" />
                  <ShimmerEffect width="50%" height="14px" borderRadius="sm" />
                  <ShimmerEffect width="40%" height="12px" borderRadius="sm" />
                </div>
              </div>
            ))}
          </div>
          <div className={styles.shimmerSummary}>
            <ShimmerEffect width="100%" height="200px" borderRadius="lg" />
          </div>
        </div>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className={styles.emptyContainer}>
        <EmptyState
          type="cart"
          title={lang === 'ar' ? 'سلتك فارغة' : 'Your cart is empty'}
          message={lang === 'ar' ? 'استكشف الكورسات المتاحة وأضف ما يناسبك للسلة' : 'Explore available courses and add what suits you to the cart'}
          actionLabel={lang === 'ar' ? 'تصفح الكورسات' : 'Browse Courses'}
          onAction={() => router.push('/')}
        />
      </div>
    );
  }

  return (
    <div ref={pageRef} className="container fade-in">
      <h1 className={styles.pageTitle}>{t.cart}</h1>

      <div className={styles.grid}>
        <div className={styles.itemsCol}>
          {items.map((item) => (
            <div
              key={item.id}
              className={`${styles.cartItem} glass ${shakeId === item.id ? styles.shake : ''} ${removing === item.id ? styles.removing : ''}`}
            >
              {item.thumbnail_url ? (
                <img src={item.thumbnail_url} alt={item.title_ar} className={styles.itemImg} />
              ) : (
                <div className={styles.placeholderImg}>
                  <ShoppingCart fontSize="small" className={styles.placeholderIcon} />
                </div>
              )}

              <div className={styles.itemDetails}>
                <h3 className={styles.itemTitle}>
                  {lang === 'ar' ? item.title_ar : item.title_en}
                </h3>

                {(item.instructor_name_ar || item.instructor_name_en) && (
                  <p className={styles.instructorName}>
                    {lang === 'ar' ? item.instructor_name_ar : item.instructor_name_en}
                  </p>
                )}

                {(item.rating != null && item.rating > 0) && (
                  <div className={styles.ratingRow}>
                    <RatingStars value={item.rating} size="xs" showValue count={item.rating_count} />
                  </div>
                )}

                <div className={styles.itemPricing}>
                  {item.is_free ? (
                    <span className={styles.itemFree}>{t.free}</span>
                  ) : (
                    <PriceTag
                      price={item.discount_price || item.price}
                      originalPrice={item.discount_price ? item.price : undefined}
                      size="sm"
                    />
                  )}
                </div>
              </div>

              <button
                onClick={() => handleRemoveFromCart(item.id)}
                className={styles.removeBtn}
                disabled={removing === item.id}
                title={lang === 'ar' ? 'حذف من السلة' : 'Remove from cart'}
              >
                <Delete fontSize="small" />
              </button>
            </div>
          ))}
        </div>

        <div className={styles.summaryCol}>
          <div className={`${styles.summaryCard} glass`}>
            <h2 className={styles.summaryTitle}>{t.cartSummary}</h2>

            <div className={styles.summaryRows}>
              <div className={styles.summaryRow}>
                <span>{lang === 'ar' ? 'المجموع الفرعي' : 'Subtotal'}</span>
                <span>{NumberUtils.formatPrice(subtotal, lang)}</span>
              </div>
              {discount > 0 && (
                <div className={`${styles.summaryRow} ${styles.discountRow}`}>
                  <span>{lang === 'ar' ? 'الخصم' : 'Discount'}</span>
                  <span>-{NumberUtils.formatPrice(discount, lang)}</span>
                </div>
              )}
              <div className={`${styles.summaryRow} ${styles.totalRow}`}>
                <span>{t.total}</span>
                <span>{NumberUtils.formatPrice(total, lang)}</span>
              </div>
            </div>

            <div className={styles.couponToggle}>
              <button
                className={styles.couponToggleBtn}
                onClick={() => setCouponOpen(!couponOpen)}
                type="button"
              >
                <Sell fontSize="small" />
                <span>{t.applyCoupon}</span>
                {couponOpen ? <ExpandLess fontSize="small" /> : <ExpandMore fontSize="small" />}
              </button>
            </div>

            <div className={`${styles.couponBody} ${couponOpen || couponData ? styles.couponOpen : ''}`}>
              {couponData ? (
                <div className={styles.couponApplied}>
                  <div className={styles.couponAppliedInfo}>
                    <CheckCircle fontSize="small" className={styles.couponCheckIcon} />
                    <div>
                      <span className={styles.couponCode}>{couponData.code}</span>
                      <span className={styles.couponDiscount}>
                        {couponData.discount_type === 'percentage'
                          ? `-${couponData.discount_value}%`
                          : `-${NumberUtils.formatPrice(Number(couponData.discount_value), lang)}`
                        }
                      </span>
                    </div>
                  </div>
                  <button className={styles.couponCloseBtn} onClick={handleRemoveCoupon} type="button">
                    <Close fontSize="small" />
                  </button>
                </div>
              ) : (
                <div className={styles.couponForm}>
                  <div className={styles.couponInputWrapper}>
                    <Sell fontSize="small" className={styles.tagIcon} />
                    <input
                      type="text"
                      placeholder={t.couponCode}
                      value={couponCode}
                      onChange={(e) => setCouponCode(e.target.value)}
                      className={styles.couponInput}
                    />
                    <button
                      onClick={handleApplyCoupon}
                      className={`${styles.applyBtn} gradient-bg`}
                      disabled={!couponCode}
                    >
                      {t.apply}
                    </button>
                  </div>

                  {couponError && (
                    <div className={styles.couponMessageError}>
                      <ErrorIcon fontSize="small" />
                      <span>{couponError}</span>
                    </div>
                  )}
                </div>
              )}
            </div>

            <button onClick={handleCheckout} className={`${styles.checkoutBtn} gradient-bg`}>
              <span>{t.checkout}</span>
              {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
