'use client';

import React, { useState, useEffect, useCallback } from 'react';

import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { Delete, ShoppingCart, Sell, Error as ErrorIcon, ArrowForward, ArrowBack, ExpandMore, ExpandLess, CheckCircle, Close, Sync } from '@mui/icons-material';
import { ShimmerEffect, EmptyState, RatingStars, PriceTag } from '../../components/ui';
import { NumberUtils } from '../../lib/formatters';
import { getBaseCoursePrice, getEffectiveCoursePrice, hasCourseDiscount } from '../../lib/pricing';
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
  pricing_options?: unknown;
  instructor_id?: string;
  instructor_name?: string;
  rating?: number;
  rating_count?: number;
}

interface InstructorProfile {
  id?: string;
  name?: string;
}

interface RawCourse extends CartItem {
  profiles?: InstructorProfile | InstructorProfile[] | null;
}

interface CartRow {
  course_id: string;
  courses?: RawCourse | RawCourse[] | null;
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
  const { lang, t, user, cart, removeFromCart, clearCart } = useApp();
  const router = useRouter();

  const [items, setItems] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [removing, setRemoving] = useState<string | null>(null);
  const [shakeId, setShakeId] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const [couponCode, setCouponCode] = useState('');
  const [couponData, setCouponData] = useState<Coupon | null>(null);
  const [couponError, setCouponError] = useState<string | null>(null);
  const [couponSuccess, setCouponSuccess] = useState<string | null>(null);
  const [couponOpen, setCouponOpen] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function fetchCartItems() {
      setLoading(true);

      try {
        let courseIds = [...cart];
        const prefetchedItems = new Map<string, CartItem>();

        if (user?.id) {
          const { data: dbCart, error: dbCartError } = await supabase
            .from('cart_items')
            .select(`
              course_id,
              courses (
                id,
                title_ar,
                title_en,
                thumbnail_url,
                price,
                discount_price,
                is_free,
                pricing_options,
                rating,
                rating_count,
                profiles!courses_instructor_id_fkey (
                  id,
                  name
                )
              )
            `)
            .eq('user_id', user.id);

          if (!dbCartError && dbCart?.length) {
            const dbItems = (dbCart as CartRow[])
              .map((row) => {
                const course = Array.isArray(row.courses) ? row.courses[0] : row.courses;
                if (!course?.id) return null;
                const profile = Array.isArray(course.profiles) ? course.profiles[0] : course.profiles;
                return { ...course, instructor_id: profile?.id || course.instructor_id, instructor_name: profile?.name } as CartItem;
              })
              .filter((course): course is CartItem => course !== null);

            dbItems.forEach((item) => prefetchedItems.set(item.id, item));

            courseIds = [...courseIds, ...dbCart.map((row: CartRow) => row.course_id)];
          }
        } else if (courseIds.length === 0 && typeof window !== 'undefined') {
          try {
            const offlineCart = JSON.parse(localStorage.getItem('nero_cart') || '[]') as string[];
            courseIds = offlineCart;
          } catch {
            courseIds = [];
          }
        }

        const cleanIds = Array.from(new Set(courseIds.filter(Boolean)));
        const missingIds = cleanIds.filter((id) => !prefetchedItems.has(id));

        if (cleanIds.length === 0) {
          if (!cancelled) setItems([]);
          return;
        }

        if (missingIds.length > 0) {
          const { data, error } = await supabase
            .from('courses')
            .select('id, title_ar, title_en, thumbnail_url, price, discount_price, is_free, pricing_options, rating, rating_count, instructor_id, profiles!courses_instructor_id_fkey(id, name)')
            .in('id', missingIds);

          if (!error && data) {
            (data as unknown as RawCourse[])
              .map((course) => {
                const profile = Array.isArray(course.profiles) ? course.profiles[0] : course.profiles;
                return { ...course, instructor_id: profile?.id || course.instructor_id, instructor_name: profile?.name } as CartItem;
              })
              .forEach((item) => prefetchedItems.set(item.id, item));
          }
        }

        if (!cancelled) {
          setItems(cleanIds.map((id) => prefetchedItems.get(id)).filter((item): item is CartItem => Boolean(item)));
        }
      } catch (err) {
        console.error('Error fetching cart details:', err);
        if (!cancelled) setItems([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    fetchCartItems();
    return () => { cancelled = true; };
  }, [cart, user?.id]);

  const subtotal = items.reduce((sum, item) => {
    return sum + getEffectiveCoursePrice(item);
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

  const handleCheckout = async () => {
    if (!user) {
      router.push('/login?redirect=/cart');
      return;
    }

    setSubmitting(true);
    setSubmitError(null);

    try {
      if (items.length === 0) {
        throw new Error(t.emptyCart || 'Cart is empty');
      }

      // Check if user is already enrolled in any of these courses
      const courseIds = items.map((item) => item.id);
      const { data: enrolledCheck } = await supabase
        .from('enrollments')
        .select('course_id')
        .eq('user_id', user.id)
        .in('status', ['active', 'completed']);

      const alreadyEnrolledIds = new Set(enrolledCheck?.map((e) => e.course_id) || []);
      const filteredItems = items.filter((item) => !alreadyEnrolledIds.has(item.id));

      if (filteredItems.length === 0) {
        throw new Error(lang === 'ar' ? 'جميع الكورسات في سلتك مشترك بها بالفعل.' : 'All courses in your cart are already enrolled.');
      }

      // ✅ Check: Prevent submitting a new request if there's already a pending one for the same courses
      const filteredCourseIds = filteredItems.map((item) => item.id);
      const { data: pendingItems } = await supabase
        .from('manual_purchase_request_items')
        .select('course_id, parent_enrollments!inner(user_id, payment_status)')
        .eq('parent_enrollments.user_id', user.id)
        .eq('parent_enrollments.payment_status', 'pending_manual_payment')
        .in('course_id', filteredCourseIds);

      if (pendingItems && pendingItems.length > 0) {
        const pendingCourseIds = pendingItems.map((p: { course_id: string }) => p.course_id);
        const pendingTitles = filteredItems
          .filter((item) => pendingCourseIds.includes(item.id))
          .map((item) => lang === 'ar' ? item.title_ar : item.title_en)
          .join('، ');
        throw new Error(
          lang === 'ar'
            ? `لديك طلب شراء معلق بالفعل للكورسات التالية: ${pendingTitles}. انتظر موافقة المدرس أولاً.`
            : `You already have a pending purchase request for: ${pendingTitles}. Please wait for approval first.`
        );
      }

      const couponDiscountTotal = discount;
      const isFreeOrder = total === 0;

      // 1. Create parent enrollment record first
      const { data: parentEnrollment, error: parentError } = await supabase
        .from('parent_enrollments')
        .insert({
          user_id: user.id,
          total: total,
          subtotal: subtotal,
          discount: couponDiscountTotal,
          coupon_id: couponData?.id || null,
          coupon_code: couponData?.code || null,
          coupon_discount: couponDiscountTotal,
          payment_method: isFreeOrder ? 'free' : 'manual',
          payment_status: isFreeOrder ? 'paid' : 'pending_manual_payment',
          paid_at: isFreeOrder ? new Date().toISOString() : null,
        })
        .select('id')
        .single();

      if (parentError || !parentEnrollment) {
        throw parentError || new Error('Failed to create order record.');
      }

      const parentEnrollmentId = parentEnrollment.id;

      // 2. Loop through each item and insert request items or enrollments
      for (const item of filteredItems) {
        const itemPrice = getEffectiveCoursePrice(item);
        
        let itemCouponDiscount = 0;
        if (itemPrice > 0 && subtotal > 0 && couponDiscountTotal > 0) {
          itemCouponDiscount = Math.round((itemPrice / subtotal) * couponDiscountTotal);
        }

        if (!isFreeOrder) {
          const { error: itemError } = await supabase
            .from('manual_purchase_request_items')
            .insert({
              parent_enrollment_id: parentEnrollmentId,
              user_id: user.id,
              course_id: item.id,
              instructor_id: item.instructor_id || null,
              price: itemPrice,
              original_price: item.price || 0,
              discount: itemCouponDiscount,
              pricing_option: null,
            });

          if (itemError) throw itemError;
        } else {
          const { error: enrollError } = await supabase
            .from('enrollments')
            .insert({
              user_id: user.id,
              course_id: item.id,
              instructor_id: item.instructor_id || null,
              parent_enrollment_id: parentEnrollmentId,
              status: 'active',
              progress_percentage: 0,
              completed_lessons: 0,
              price: itemPrice,
              pricing_option: null,
              discount: itemCouponDiscount,
              total_watch_time: 0,
              enrolled_at: new Date().toISOString(),
            });

          if (enrollError) throw enrollError;
        }
      }

      if (couponData?.id) {
        await supabase
          .from('coupon_usages')
          .insert({
            coupon_id: couponData.id,
            user_id: user.id,
            enrollment_id: parentEnrollmentId,
            discount_amount: couponDiscountTotal,
          });

        await supabase
          .from('coupons')
          .update({ usage_count: (couponData.usage_count || 0) + 1 })
          .eq('id', couponData.id);
      }

      await clearCart();

      sessionStorage.setItem('pending_parent_enrollment_id', parentEnrollmentId);
      sessionStorage.removeItem('checkout_totals');
      sessionStorage.removeItem('applied_coupon');

      router.push(`/checkout/success?id=${parentEnrollmentId}`);
    } catch (err: unknown) {
      console.error('Checkout error:', err);
      setSubmitError(err instanceof Error ? err.message : t.paymentFailed);
      setSubmitting(false);
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
    <main ref={pageRef} className={styles.page}>
      {/* Hero Banner */}
      <div className={styles.hero}>
        <div className={styles.heroText}>
          <p className={styles.heroEyebrow}>{lang === 'ar' ? 'مشترياتك' : 'YOUR CART'}</p>
          <h1>{lang === 'ar' ? 'سلة المشتريات' : 'Shopping Cart'}</h1>
          <p>
            {lang === 'ar'
              ? `لديك ${items.length} ${items.length === 1 ? 'كورس' : 'كورسات'} في السلة`
              : `You have ${items.length} ${items.length === 1 ? 'course' : 'courses'} in your cart`}
          </p>
        </div>
        <div className={styles.heroIcon}>🛒</div>
      </div>

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

                {item.instructor_name && (
                  <p className={styles.instructorName}>
                    {item.instructor_name}
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
                      price={getEffectiveCoursePrice(item)}
                      originalPrice={hasCourseDiscount(item) ? getBaseCoursePrice(item) : undefined}
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

            {submitError && (
              <div className={styles.couponMessageError}>
                <ErrorIcon fontSize="small" />
                <span>{submitError}</span>
              </div>
            )}

            <button onClick={handleCheckout} disabled={submitting} className={`${styles.checkoutBtn} gradient-bg`}>
              {submitting ? (
                <>
                  <Sync fontSize="small" className={styles.spin} />
                  <span>{t.processing}</span>
                </>
              ) : (
                <>
                  <span>{lang === 'ar' ? `تقديم الطلب - ${NumberUtils.formatPrice(total, lang)}` : `Submit request - ${NumberUtils.formatPrice(total, lang)}`}</span>
                  {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </main>
  );
}
