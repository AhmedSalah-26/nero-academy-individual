'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import type { User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabaseClient';
import { Language, translations } from '../lib/translations';
import { getEffectiveCoursePrice } from '../lib/pricing';

interface UserProfile {
  id: string;
  email: string;
  name: string;
  phone: string;
  role: 'student' | 'instructor';
  avatar_url?: string;
  interests?: string[];
}

interface AppContextType {
  lang: Language;
  t: typeof translations.ar;
  user: User | null;
  profile: UserProfile | null;
  cart: string[]; // courseIds
  wishlist: string[]; // courseIds
  enrolledCourseIds: string[]; // courseIds
  loading: boolean;
  theme: 'light' | 'dark';
  toggleTheme: () => void;
  toggleLang: () => void;
  addToCart: (courseId: string) => Promise<void>;
  removeFromCart: (courseId: string) => Promise<void>;
  clearCart: () => Promise<void>;
  addToWishlist: (courseId: string) => Promise<void>;
  removeFromWishlist: (courseId: string) => Promise<void>;
  signOut: () => Promise<void>;
  refreshAuth: () => Promise<void>;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Keep the first client render identical to the server render.
  // Persisted preferences are restored after hydration.
  const [lang, setLang] = useState<Language>('ar');
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [cart, setCart] = useState<string[]>([]);
  const [wishlist, setWishlist] = useState<string[]>([]);
  const [enrolledCourseIds, setEnrolledCourseIds] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  const t = translations[lang];

  useEffect(() => {
    const savedLang = localStorage.getItem('nero_lang') as Language | null;
    const savedTheme = localStorage.getItem('nero_theme') as 'light' | 'dark' | null;

    const restorePreferences = window.setTimeout(() => {
      if (savedLang === 'ar' || savedLang === 'en') {
        setLang(savedLang);
      }
      if (savedTheme === 'light' || savedTheme === 'dark') {
        setTheme(savedTheme);
      }
    }, 0);

    return () => window.clearTimeout(restorePreferences);
  }, []);

  // Set document dir on lang change
  useEffect(() => {
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;
  }, [lang]);

  // Set document theme attribute
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const toggleLang = () => {
    const nextLang = lang === 'ar' ? 'en' : 'ar';
    setLang(nextLang);
    localStorage.setItem('nero_lang', nextLang);
  };

  const toggleTheme = () => {
    const nextTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(nextTheme);
    localStorage.setItem('nero_theme', nextTheme);
  };

  // Main Auth Refresh Flow
  const refreshAuth = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        setUser(session.user);
        // Auth is ready once the session is known. Profile/cart queries should
        // not keep protected pages stuck behind a loading screen.
        setLoading(false);
        
        const offlineCart = JSON.parse(localStorage.getItem('nero_cart') || '[]') as string[];
        const offlineWish = JSON.parse(localStorage.getItem('nero_wishlist') || '[]') as string[];

        if (offlineCart.length > 0) {
          await supabase.from('cart_items').upsert(
            offlineCart.map((courseId) => ({
              user_id: session.user.id,
              course_id: courseId,
              price_at_add: 0,
            })),
            { onConflict: 'user_id,course_id' }
          );
          localStorage.removeItem('nero_cart');
        }

        if (offlineWish.length > 0) {
          await supabase.from('wishlist').upsert(
            offlineWish.map((courseId) => ({
              user_id: session.user.id,
              course_id: courseId,
            })),
            { onConflict: 'user_id,course_id' }
          );
          localStorage.removeItem('nero_wishlist');
        }

        // Fetch profile
        const { data: prof, error } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', session.user.id)
          .single();
        
        if (prof && !error) {
          setProfile(prof as UserProfile);
        }

        // Fetch active/completed enrollments
        const { data: dbEnrollments } = await supabase
          .from('enrollments')
          .select('course_id')
          .eq('user_id', session.user.id)
          .in('status', ['active', 'completed']);

        const enrolledIds = dbEnrollments ? dbEnrollments.map((e: { course_id: string }) => e.course_id) : [];
        setEnrolledCourseIds(enrolledIds);

        // Fetch DB Cart & Wishlist
        const { data: dbCart } = await supabase
          .from('cart_items')
          .select('course_id')
          .eq('user_id', session.user.id);
        
        if (dbCart) {
          const rawCartIds = dbCart.map((item: { course_id: string }) => item.course_id);
          const cleanCartIds = rawCartIds.filter((id: string) => !enrolledIds.includes(id));
          const duplicates = rawCartIds.filter((id: string) => enrolledIds.includes(id));

          if (duplicates.length > 0) {
            // Remove duplicates from database cart
            await supabase
              .from('cart_items')
              .delete()
              .eq('user_id', session.user.id)
              .in('course_id', duplicates);
          }

          setCart(cleanCartIds);
        }

        const { data: dbWish } = await supabase
          .from('wishlist')
          .select('course_id')
          .eq('user_id', session.user.id);
        
        if (dbWish) {
          setWishlist(dbWish.map((item: { course_id: string }) => item.course_id));
        }
      } else {
        setUser(null);
        setProfile(null);
        setEnrolledCourseIds([]);
        // Load offline cart/wishlist
        const offlineCart = JSON.parse(localStorage.getItem('nero_cart') || '[]');
        const offlineWish = JSON.parse(localStorage.getItem('nero_wishlist') || '[]');
        setCart(offlineCart);
        setWishlist(offlineWish);
      }
    } catch (err) {
      console.error('Error refreshing auth:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const initialRefresh = window.setTimeout(() => void refreshAuth(), 0);

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
        // Update the visible auth state immediately. Running database queries
        // inside the auth callback can block Supabase's internal auth lock.
        setUser(session?.user ?? null);
        window.setTimeout(() => void refreshAuth(), 0);
      } else if (event === 'SIGNED_OUT') {
        setUser(null);
        setProfile(null);
        setCart([]);
        setWishlist([]);
        setEnrolledCourseIds([]);
        localStorage.removeItem('nero_cart');
        localStorage.removeItem('nero_wishlist');
      }
    });

    return () => {
      window.clearTimeout(initialRefresh);
      subscription.unsubscribe();
    };
  }, []);

  // Cart operations
  const addToCart = async (courseId: string) => {
    if (cart.includes(courseId)) return;
    
    const nextCart = [...cart, courseId];
    setCart(nextCart);

    if (user) {
      const { data: course } = await supabase
        .from('courses')
        .select('price, discount_price, is_free, pricing_options, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end')
        .eq('id', courseId)
        .maybeSingle();

      // Sync to DB
      await supabase.from('cart_items').upsert({
        user_id: user.id,
        course_id: courseId,
        price_at_add: course ? getEffectiveCoursePrice(course) : 0
      });
    } else {
      localStorage.setItem('nero_cart', JSON.stringify(nextCart));
    }
  };

  const removeFromCart = async (courseId: string) => {
    const nextCart = cart.filter((id) => id !== courseId);
    setCart(nextCart);

    if (user) {
      await supabase
        .from('cart_items')
        .delete()
        .eq('user_id', user.id)
        .eq('course_id', courseId);
    } else {
      localStorage.setItem('nero_cart', JSON.stringify(nextCart));
    }
  };

  const clearCart = async () => {
    setCart([]);
    if (user) {
      await supabase.from('cart_items').delete().eq('user_id', user.id);
    } else {
      localStorage.removeItem('nero_cart');
    }
  };

  // Wishlist operations
  const addToWishlist = async (courseId: string) => {
    if (wishlist.includes(courseId)) return;
    
    const nextWish = [...wishlist, courseId];
    setWishlist(nextWish);

    if (user) {
      await supabase.from('wishlist').upsert({
        user_id: user.id,
        course_id: courseId
      });
    } else {
      localStorage.setItem('nero_wishlist', JSON.stringify(nextWish));
    }
  };

  const removeFromWishlist = async (courseId: string) => {
    const nextWish = wishlist.filter((id) => id !== courseId);
    setWishlist(nextWish);

    if (user) {
      await supabase
        .from('wishlist')
        .delete()
        .eq('user_id', user.id)
        .eq('course_id', courseId);
    } else {
      localStorage.setItem('nero_wishlist', JSON.stringify(nextWish));
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setProfile(null);
    setCart([]);
    setWishlist([]);
    setEnrolledCourseIds([]);
    localStorage.removeItem('nero_cart');
    localStorage.removeItem('nero_wishlist');
  };

  return (
    <AppContext.Provider
      value={{
        lang,
        t,
        user,
        profile,
        cart,
        wishlist,
        enrolledCourseIds,
        loading,
        theme,
        toggleTheme,
        toggleLang,
        addToCart,
        removeFromCart,
        clearCart,
        addToWishlist,
        removeFromWishlist,
        signOut,
        refreshAuth
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
