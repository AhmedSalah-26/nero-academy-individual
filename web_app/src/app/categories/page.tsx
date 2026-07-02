'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Code,
  DesignServices,
  BusinessCenter,
  Campaign,
  CameraAlt,
  GraphicEq,
  School,
  Language,
  HealthAndSafety,
  Smartphone,
  Science,
  Calculate,
  FolderOpen,
  Category,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface CategoryData {
  id: string;
  name_ar: string;
  name_en: string;
  icon_name?: string;
}

function getCategoryConfig(iconName?: string) {
  switch (iconName?.toLowerCase()) {
    case 'code':
      return { icon: <Code fontSize="medium" />, color: '#6F7A3A' };
    case 'design':
      return { icon: <DesignServices fontSize="medium" />, color: '#8B5CF6' };
    case 'business':
      return { icon: <BusinessCenter fontSize="medium" />, color: '#059669' };
    case 'marketing':
      return { icon: <Campaign fontSize="medium" />, color: '#D97706' };
    case 'photography':
      return { icon: <CameraAlt fontSize="medium" />, color: '#DC2626' };
    case 'music':
      return { icon: <GraphicEq fontSize="medium" />, color: '#7C3AED' };
    case 'academics':
    case 'school':
      return { icon: <School fontSize="medium" />, color: '#0891B2' };
    case 'language':
    case 'languages':
      return { icon: <Language fontSize="medium" />, color: '#4F46E5' };
    case 'health':
      return { icon: <HealthAndSafety fontSize="medium" />, color: '#16A34A' };
    case 'mobile':
    case 'smartphone':
      return { icon: <Smartphone fontSize="medium" />, color: '#E11D48' };
    case 'science':
      return { icon: <Science fontSize="medium" />, color: '#F59E0B' };
    case 'math':
      return { icon: <Calculate fontSize="medium" />, color: '#0EA5E9' };
    default:
      return { icon: <FolderOpen fontSize="medium" />, color: '#64748B' };
  }
}

export default function CategoriesPage() {
  const pageRef = usePageTransition();
  const { lang, t } = useApp();
  const router = useRouter();
  const [categories, setCategories] = useState<CategoryData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadCategories() {
      try {
        const { data, error } = await supabase
          .from('categories')
          .select('id, name_ar, name_en, icon_name')
          .eq('is_active', true)
          .order('sort_order', { ascending: true });

        if (data && !error) {
          setCategories(data as CategoryData[]);
        }
      } catch (err) {
        console.error('Error loading categories:', err);
      } finally {
        setLoading(false);
      }
    }
    loadCategories();
  }, []);

  const handleCategoryClick = (categoryId: string) => {
    router.push(`/search?category=${categoryId}`);
  };

  if (loading) {
    return (
      <div className={styles.loadingState}>
        <div className={styles.spinner}></div>
        <p>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</p>
      </div>
    );
  }

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.hero}>
        <div className={styles.heroText}>
          <h1>{t.categories}</h1>
          <p>
            {lang === 'ar' ? 'استكشف الكورسات حسب التصنيف' : 'Explore courses by category'}
          </p>
        </div>
        <div className={styles.heroIcon}>
          <Category />
        </div>
      </div>

      <div className={styles.grid}>
        {categories.map((cat) => {
          const cfg = getCategoryConfig(cat.icon_name);
          const alphaColor = cfg.color + '26'; // 15% opacity overlay color

          return (
            <button
              key={cat.id}
              className={styles.categoryCard}
              onClick={() => handleCategoryClick(cat.id)}
              type="button"
            >
              <div
                className={styles.iconContainer}
                style={{ backgroundColor: alphaColor, color: cfg.color }}
              >
                {cfg.icon}
              </div>
              <span className={styles.categoryName}>
                {lang === 'ar' ? cat.name_ar : cat.name_en}
              </span>
            </button>
          );
        })}
      </div>
    </main>
  );
}


