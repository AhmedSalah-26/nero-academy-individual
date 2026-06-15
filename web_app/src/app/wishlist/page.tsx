'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Heart, ShoppingCart, Trash2 } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import styles from '../student-features.module.css';
type Course={id:string;title_ar:string;title_en?:string;subtitle_ar?:string;subtitle_en?:string;thumbnail_url?:string;price:number};
export default function WishlistPage(){const{lang,wishlist,removeFromWishlist,addToCart}=useApp();const[items,setItems]=useState<Course[]>([]);useEffect(()=>{let active=true;const load=async()=>{if(!wishlist.length){await Promise.resolve();if(active)setItems([]);return;}const{data}=await supabase.from('courses').select('id,title_ar,title_en,subtitle_ar,subtitle_en,thumbnail_url,price').in('id',wishlist);if(active)setItems((data||[]) as Course[]);};load();return()=>{active=false};},[wishlist]);
return <main className={styles.page}><FeaturePageHero icon={Heart} eyebrow={lang==='ar'?'محفوظاتك':'SAVED'} title={lang==='ar'?'المفضلة':'Wishlist'} subtitle={lang==='ar'?'كل الكورسات التي حفظتها للعودة إليها لاحقاً.':'Courses you saved for later.'}/>{!items.length?<div className={styles.empty}><Heart size={38}/><strong>المفضلة فارغة</strong><Link className={styles.action} href="/">استكشف الكورسات</Link></div>:<section className={styles.grid}>{items.map(c=><article className={styles.card} key={c.id}>{c.thumbnail_url&&<img className={styles.image} src={c.thumbnail_url} alt="" onError={e=>e.currentTarget.style.display='none'}/>}<h3>{lang==='ar'?c.title_ar:c.title_en||c.title_ar}</h3><p>{lang==='ar'?c.subtitle_ar:c.subtitle_en||c.subtitle_ar}</p><div className={styles.meta}><strong>{c.price} جنيه</strong><button className={styles.action} onClick={()=>addToCart(c.id)}><ShoppingCart size={13}/>السلة</button><button className={`${styles.action} ${styles.secondary}`} onClick={()=>removeFromWishlist(c.id)}><Trash2 size={13}/></button></div></article>)}</section>}</main>}
