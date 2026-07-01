'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Code,
  DesignServices,
  BusinessCenter,
  Psychology,
  CameraAlt,
  GraphicEq,
  School,
  Language,
  HealthAndSafety,
  Smartphone,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { AppColors } from '../../lib/designTokens';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface CategoryData {
  id: string;
  name_ar: string;
  name_en: string;
  courseCount?: number;
}

interface HardcodedCategory {
  id: string;
  name_ar: string;
  name_en: string;
  icon: React.ReactNode;
  color: string;
}

const HARDCODED_CATEGORIES: HardcodedCategory[] = [
  {
    id: 'programming',
    name_ar: 'البرمجة',
    name_en: 'Programming',
    icon: <Code fontSize="medium" />,
    color: '#2563EB',
  },
  {
    id: 'design',
    name_ar: 'التصميم',
    name_en: 'Design',
    icon: <DesignServices fontSize="medium" />,
    color: '#8B5CF6',
  },
  {
    id: 'business',
    name_ar: 'الأعمال',
    name_en: 'Business',
    icon: <BusinessCenter fontSize="medium" />,
    color: '#059669',
  },
  {
    id: 'marketing',
    name_ar: 'التسويق',
    name_en: 'Marketing',
    icon: <Psychology fontSize="medium" />,
    color: '#D97706',
  },
  {
    id: 'photography',
    name_ar: 'التصوير',
    name_en: 'Photography',
    icon: <CameraAlt fontSize="medium" />,
    color: '#DC2626',
  },
  {
    id: 'music',
    name_ar: 'الموسيقى',
    name_en: 'Music',
    icon: <GraphicEq fontSize="medium" />,
    color: '#7C3AED',
  },
  {
    id: 'academics',
    name_ar: 'الأكاديمي',
    name_en: 'Academics',
    icon: <School fontSize="medium" />,
    color: '#0891B2',
  },
  {
    id: 'languages',
    name_ar: 'اللغات',
    name_en: 'Languages',
    icon: <Language fontSize="medium" />,
    color: '#4F46E5',
  },
  {
    id: 'health',
    name_ar: 'الصحة',
    name_en: 'Health',
    icon: <HealthAndSafety fontSize="medium" />,
    color: '#16A34A',
  },
  {
    id: 'mobile',
    name_ar: 'تطوير التطبيقات',
    name_en: 'App Development',
    icon: <Smartphone fontSize="medium" />,
    color: '#E11D48',
  },
];

export default function CategoriesPage() {
  const pageRef = usePageTransition();
  const { lang, t } = useApp();
  const router = useRouter();
  const [dbCategories, setDbCategories] = useState<CategoryData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadCategories() {
      try {
        const { data, error } = await supabase
          .from('categories')
          .select('id, name_ar, name_en')
          .eq('is_active', true);

        if (data && !error) {
          setDbCategories(data as CategoryData[]);
        }
      } catch (err) {
        console.error('Error loading categories:', err);
      } finally {
        setLoading(false);
      }
    }
    loadCategories();
  }, []);

  const mergedCategories = HARDCODED_CATEGORIES.map((hc) => {
    const dbMatch = dbCategories.find((db) => db.id === hc.id);
    return {
      ...hc,
      dbId: dbMatch?.id,
    };
  });

  const handleCategoryClick = (categoryId: string) => {
    const dbId = dbCategories.find((db) => db.id === categoryId)?.id;
    const navId = dbId || categoryId;
    router.push(`/search?category=${navId}`);
  };

  return (
    <div ref={pageRef} className="container fade-in">
      <div className={styles.header}>
        <h1 className={styles.title}>{t.categories}</h1>
        <p className={styles.subtitle}>
          {lang === 'ar' ? 'استكشف الكورسات حسب التصنيف' : 'Explore courses by category'}
        </p>
      </div>

      <div className={styles.grid}>
        {mergedCategories.map((cat) => {
          const alphaColor = cat.color + '26';
          return (
            <button
              key={cat.id}
              className={styles.categoryCard}
              onClick={() => handleCategoryClick(cat.id)}
              type="button"
            >
              <div
                className={styles.iconContainer}
                style={{ backgroundColor: alphaColor, color: cat.color }}
              >
                {cat.icon}
              </div>
              <span className={styles.categoryName}>
                {lang === 'ar' ? cat.name_ar : cat.name_en}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
