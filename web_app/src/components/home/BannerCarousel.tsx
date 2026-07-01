'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import styles from './BannerCarousel.module.css';

interface Banner {
  id: string;
  image_url: string;
  title_ar?: string;
  title_en?: string;
  subtitle_ar?: string;
  subtitle_en?: string;
}

export function BannerCarousel() {
  const { lang } = useApp();
  const [banners, setBanners] = useState<Banner[]>([]);
  const [current, setCurrent] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    supabase
      .from('banners')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
      .then(({ data }) => {
        if (data && data.length) setBanners(data as Banner[]);
      });
  }, []);

  const startAutoScroll = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current);
    timerRef.current = setInterval(() => {
      setCurrent((prev) => (prev + 1) % banners.length);
    }, 5000);
  }, [banners.length]);

  useEffect(() => {
    if (banners.length > 1) startAutoScroll();
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [banners.length, startAutoScroll]);

  if (banners.length === 0) return null;

  const banner = banners[current];
  const title = lang === 'ar' ? (banner.title_ar || banner.title_en || '') : (banner.title_en || banner.title_ar || '');
  const subtitle = lang === 'ar' ? (banner.subtitle_ar || banner.subtitle_en || '') : (banner.subtitle_en || banner.subtitle_ar || '');

  return (
    <div className={styles.carousel}>
      <div className={styles.track}>
        {banners.map((b, i) => (
          <div
            key={b.id}
            className={`${styles.slide} ${i === current ? styles.active : ''}`}
            style={{ transform: `translateX(${(i - current) * 100}%)` }}
          >
            <div className={styles.imageWrap}>
              {b.image_url ? (
                <img src={b.image_url} alt="" className={styles.image} />
              ) : (
                <div className={styles.placeholder} />
              )}
              <div className={styles.overlay} />
              <div className={styles.content}>
                <span className={styles.badge}>
                  {lang === 'ar' ? 'عرض خاص' : 'Special Offer'}
                </span>
                {(lang === 'ar' ? b.title_ar : b.title_en) && (
                  <h3 className={styles.slideTitle}>
                    {lang === 'ar' ? (b.title_ar || b.title_en) : (b.title_en || b.title_ar)}
                  </h3>
                )}
                {(lang === 'ar' ? b.subtitle_ar : b.subtitle_en) && (
                  <p className={styles.slideSubtitle}>
                    {lang === 'ar' ? (b.subtitle_ar || b.subtitle_en) : (b.subtitle_en || b.subtitle_ar)}
                  </p>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
      {banners.length > 1 && (
        <div className={styles.dots}>
          {banners.map((_, i) => (
            <button
              key={i}
              className={`${styles.dot} ${i === current ? styles.dotActive : ''}`}
              onClick={() => { setCurrent(i); startAutoScroll(); }}
              aria-label={`Banner ${i + 1}`}
            />
          ))}
        </div>
      )}
    </div>
  );
}
