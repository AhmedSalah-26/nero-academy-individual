'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { CreditCard, Smartphone, ShieldCheck } from 'lucide-react';
import styles from './page.module.css';

interface CheckoutTotals {
  subtotal: number;
  discount: number;
  total: number;
  couponId?: string;
  couponCode?: string;
}

export default function CheckoutPage() {
  const { lang, t, user, profile, clearCart, loading: authLoading } = useApp();
  const router = useRouter();

  const [totals] = useState<CheckoutTotals | null>(() => {
    if (typeof window === 'undefined') return null;
    const saved = sessionStorage.getItem('checkout_totals');
    if (!saved) return null;
    try {
      return JSON.parse(saved) as CheckoutTotals;
    } catch {
      return null;
    }
  });
  const [paymentMethod, setPaymentMethod] = useState<'card' | 'wallet'>('card');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Prefilled billing info (initialized from profile to avoid setState in effect)
  const [name, setName] = useState(() => profile?.name || '');
  const [phone, setPhone] = useState(() => profile?.phone || '');
  const [walletNumber, setWalletNumber] = useState(() => profile?.phone || '');

  useEffect(() => {
    if (authLoading) return;
    // Redirect to login if user session is lost
    if (!user) {
      router.push('/login?redirect=/checkout');
      return;
    }

    // Redirect to cart if no checkout totals are available
    if (!totals) {
      router.push('/cart');
    }
  }, [authLoading, user, totals, router]);

  const handlePay = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !totals) return;
    setLoading(true);
    setError(null);

    try {
      // 1. Create Enrollment in DB (calls RPC function)
      const { data: parentEnrollmentId, error: dbError } = await supabase.rpc(
        'create_enrollment',
        {
          p_user_id: user.id,
          p_payment_method: paymentMethod,
          p_coupon_id: totals.couponId,
          p_coupon_code: totals.couponCode,
          p_coupon_discount: totals.discount,
        }
      );

      if (dbError || !parentEnrollmentId) {
        throw new Error(dbError?.message || 'Failed to create enrollment in database.');
      }

      // 2. If the total order amount is 0 EGP, auto-confirm enrollment payment and redirect!
      if (totals.total === 0) {
        const { error: confirmError } = await supabase.rpc('confirm_enrollment_payment', {
          p_parent_enrollment_id: parentEnrollmentId,
          p_transaction_id: 'FREE_ACCESS_COUPON',
        });

        if (confirmError) throw confirmError;

        await clearCart();
        sessionStorage.removeItem('checkout_totals');
        sessionStorage.removeItem('applied_coupon');
        router.push('/checkout/success');
        return;
      }

      // 3. Request Paymob Payment key from server API
      const paymobResponse = await fetch('/api/paymob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          parentEnrollmentId,
          amount: totals.total,
          paymentMethod,
          customerInfo: {
            name,
            email: user.email,
            phone,
            walletNumber,
          },
        }),
      });

      const paymobData = await paymobResponse.json();

      if (!paymobResponse.ok || paymobData.error) {
        throw new Error(paymobData.error || 'Failed to initiate checkout with payment provider.');
      }

      // 4. Persist parent enrollment id for the success page to verify payment status
      sessionStorage.setItem('pending_parent_enrollment_id', parentEnrollmentId);

      // Clear local cart now that database enrollment is pending
      await clearCart();

      // 5. Redirect user to payment URL (Card iFrame or Wallet Redirection URL)
      if (paymobData.redirectUrl) {
        window.location.href = paymobData.redirectUrl;
      } else {
        throw new Error('Redirection URL missing from payment service.');
      }
    } catch (err: unknown) {
      console.error('Checkout error:', err);
      setError(err instanceof Error ? err.message : t.paymentFailed);
      setLoading(false);
    }
  };

  if (!totals) return null;

  return (
    <div className="container fade-in">
      <div className={styles.grid}>
        
        {/* Billing details form */}
        <div className={styles.formCol}>
          <form onSubmit={handlePay} className={`${styles.formCard} glass`}>
            <h2 className={styles.sectionTitle}>
              {lang === 'ar' ? 'معلومات الفاتورة والاتصال' : 'Billing & Contact Information'}
            </h2>

            {error && <div className={styles.alert}>{error}</div>}

            <div className={styles.formFields}>
              <div className={styles.field}>
                <label className={styles.label}>{t.name}</label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className={styles.input}
                />
              </div>

              <div className={styles.field}>
                <label className={styles.label}>{t.phone}</label>
                <input
                  type="tel"
                  required
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className={styles.input}
                />
              </div>

              {/* Payment Method Selector */}
              <div className={styles.field}>
                <label className={styles.label}>{t.paymentMethod}</label>
                <div className={styles.paymentSelector}>
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('card')}
                    className={`${styles.selectorBtn} ${paymentMethod === 'card' ? styles.selectorActive : ''}`}
                  >
                    <CreditCard size={18} />
                    <span>{t.creditCard}</span>
                  </button>
                  
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('wallet')}
                    className={`${styles.selectorBtn} ${paymentMethod === 'wallet' ? styles.selectorActive : ''}`}
                  >
                    <Smartphone size={18} />
                    <span>{t.mobileWallet}</span>
                  </button>
                </div>
              </div>

              {/* Wallet specific field */}
              {paymentMethod === 'wallet' && (
                <div className={styles.field}>
                  <label className={styles.label}>
                    {lang === 'ar' ? 'رقم المحفظة الإلكترونية' : 'Mobile Wallet Number'}
                  </label>
                  <input
                    type="tel"
                    required
                    placeholder="01xxxxxxxxx"
                    value={walletNumber}
                    onChange={(e) => setWalletNumber(e.target.value)}
                    className={styles.input}
                  />
                </div>
              )}
            </div>

            <button type="submit" disabled={loading} className={`${styles.payBtn} gradient-bg`}>
              {loading ? (
                <span className={styles.spinner}></span>
              ) : (
                <>
                  <ShieldCheck size={20} />
                  <span>{t.payNow}</span>
                </>
              )}
            </button>
          </form>
        </div>

        {/* Checkout summary sidebar */}
        <div className={styles.summaryCol}>
          <div className={`${styles.summaryCard} glass`}>
            <h2 className={styles.summaryTitle}>{t.cartSummary}</h2>

            <div className={styles.summaryRows}>
              <div className={styles.summaryRow}>
                <span>{lang === 'ar' ? 'المجموع الفرعي' : 'Subtotal'}</span>
                <span>{totals.subtotal.toFixed(2)} {t.egp}</span>
              </div>
              {totals.discount > 0 && (
                <div className={`${styles.summaryRow} ${styles.discountRow}`}>
                  <span>{lang === 'ar' ? 'الخصم' : 'Discount'}</span>
                  <span>-{totals.discount.toFixed(2)} {t.egp}</span>
                </div>
              )}
              <div className={`${styles.summaryRow} ${styles.totalRow}`}>
                <span>{t.total}</span>
                <span>{totals.total.toFixed(2)} {t.egp}</span>
              </div>
            </div>
            
            <div className={styles.securitySeal}>
              <ShieldCheck size={16} className={styles.sealIcon} />
              <span>{lang === 'ar' ? 'معاملة آمنة ومحمية 100%' : '100% Secure Transaction'}</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
