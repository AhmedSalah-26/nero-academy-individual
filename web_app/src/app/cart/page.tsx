'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { Trash2, ShoppingCart, Tag, AlertCircle, ArrowRight, ArrowLeft } from 'lucide-react';
import styles from './page.module.css';

interface CartItem {
  id: string;
  title_ar: string;
  title_en: string;
  thumbnail_url: string;
  price: number;
  discount_price: number;
  is_free: boolean;
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
  const { lang, t, user, cart, removeFromCart } = useApp();
  const router = useRouter();

  const [items, setItems] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState(true);

  // Coupon state
  const [couponCode, setCouponCode] = useState('');
  const [couponData, setCouponData] = useState<Coupon | null>(null);
  const [couponError, setCouponError] = useState<string | null>(null);
  const [couponSuccess, setCouponSuccess] = useState<string | null>(null);

  // Fetch full details of items in the cart
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
          .select('id, title_ar, title_en, thumbnail_url, price, discount_price, is_free')
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

  // Calculate totals
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

  // Apply Coupon Logic
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

      // Check dates
      const now = new Date();
      const startDate = new Date(data.start_date);
      const endDate = data.end_date ? new Date(data.end_date) : null;

      if (now < startDate || (endDate && now > endDate)) {
        setCouponError(t.couponInvalid);
        setCouponData(null);
        return;
      }

      // Check limit
      if (data.usage_limit && data.usage_count >= data.usage_limit) {
        setCouponError(t.couponInvalid);
        setCouponData(null);
        return;
      }

      // Check min order amount
      if (data.min_order_amount && subtotal < data.min_order_amount) {
        setCouponError(
          lang === 'ar' 
            ? `الحد الأدنى لتطبيق الكوبون هو ${data.min_order_amount} جنيه` 
            : `Minimum order for this coupon is ${data.min_order_amount} EGP`
        );
        setCouponData(null);
        return;
      }

      // Success
      setCouponData(data);
      setCouponSuccess(t.couponSuccess);

      // Save coupon variables to sessionStorage for the checkout screen
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

  const handleCheckout = () => {
    if (!user) {
      // Redirect to login, then redirect back to cart or checkout
      router.push('/login?redirect=/checkout');
    } else {
      // Save totals to session storage
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
        <div className={styles.spinner}></div>
        <p>{t.loading}</p>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className={`${styles.emptyContainer} fade-in`}>
        <div className={`${styles.emptyCard} glass`}>
          <ShoppingCart size={64} className={styles.emptyIcon} />
          <h2>{t.emptyCart}</h2>
          <Link href="/" className={`${styles.exploreBtn} gradient-bg`}>
            {lang === 'ar' ? 'تصفح الكورسات المتاحة' : 'Browse Available Courses'}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container fade-in">
      <h1 className={styles.pageTitle}>{t.cart}</h1>

      <div className={styles.grid}>
        {/* Cart Items list */}
        <div className={styles.itemsCol}>
          {items.map((item) => (
            <div key={item.id} className={`${styles.cartItem} glass`}>
              {item.thumbnail_url ? (
                <img src={item.thumbnail_url} alt={item.title_ar} className={styles.itemImg} />
              ) : (
                <div className={styles.placeholderImg}></div>
              )}
              
              <div className={styles.itemDetails}>
                <h3 className={styles.itemTitle}>
                  {lang === 'ar' ? item.title_ar : item.title_en}
                </h3>
                <div className={styles.itemPricing}>
                  {item.is_free ? (
                    <span className={styles.itemFree}>{t.free}</span>
                  ) : (
                    <>
                      {item.discount_price ? (
                        <>
                          <span className={styles.itemPrice}>{item.discount_price} {t.egp}</span>
                          <span className={styles.itemOldPrice}>{item.price} {t.egp}</span>
                        </>
                      ) : (
                        <span className={styles.itemPrice}>{item.price} {t.egp}</span>
                      )}
                    </>
                  )}
                </div>
              </div>

              <button 
                onClick={() => removeFromCart(item.id)} 
                className={styles.removeBtn}
                title={lang === 'ar' ? 'حذف من السلة' : 'Remove from cart'}
              >
                <Trash2 size={18} />
              </button>
            </div>
          ))}
        </div>

        {/* Cart summary and coupon sidebar */}
        <div className={styles.summaryCol}>
          <div className={`${styles.summaryCard} glass`}>
            <h2 className={styles.summaryTitle}>{t.cartSummary}</h2>

            <div className={styles.summaryRows}>
              <div className={styles.summaryRow}>
                <span>{lang === 'ar' ? 'المجموع الفرعي' : 'Subtotal'}</span>
                <span>{subtotal.toFixed(2)} {t.egp}</span>
              </div>
              {discount > 0 && (
                <div className={`${styles.summaryRow} ${styles.discountRow}`}>
                  <span>{lang === 'ar' ? 'الخصم' : 'Discount'}</span>
                  <span>-{discount.toFixed(2)} {t.egp}</span>
                </div>
              )}
              <div className={`${styles.summaryRow} ${styles.totalRow}`}>
                <span>{t.total}</span>
                <span>{total.toFixed(2)} {t.egp}</span>
              </div>
            </div>

            {/* Coupon Code Section */}
            <div className={styles.couponSection}>
              <label className={styles.couponLabel}>{t.applyCoupon}</label>
              <div className={styles.couponInputWrapper}>
                <Tag size={16} className={styles.tagIcon} />
                <input
                  type="text"
                  placeholder={t.couponCode}
                  value={couponCode}
                  onChange={(e) => setCouponCode(e.target.value)}
                  className={styles.couponInput}
                  disabled={!!couponData}
                />
                <button 
                  onClick={handleApplyCoupon} 
                  className={`${styles.applyBtn} gradient-bg`}
                  disabled={!couponCode || !!couponData}
                >
                  {t.apply}
                </button>
              </div>

              {couponError && (
                <div className={styles.couponMessageError}>
                  <AlertCircle size={14} />
                  <span>{couponError}</span>
                </div>
              )}
              {couponSuccess && (
                <div className={styles.couponMessageSuccess}>
                  <span>{couponSuccess}</span>
                </div>
              )}
            </div>

            <button onClick={handleCheckout} className={`${styles.checkoutBtn} gradient-bg`}>
              <span>{t.checkout}</span>
              {lang === 'ar' ? <ArrowLeft size={18} /> : <ArrowRight size={18} />}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
