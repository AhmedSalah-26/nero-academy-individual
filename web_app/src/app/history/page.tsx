'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { History, PlayCircle } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import styles from '../student-features.module.css';
type Enrollment={id:string;course_id:string;progress_percentage:number;last_accessed_at?:string;status:string;courses?:{title_ar:string;title_en?:string;subtitle_ar?:string}};
export default function HistoryPage(){const{lang,user}=useApp();const[items,setItems]=useState<Enrollment[]>([]);useEffect(()=>{if(!user)return;supabase.from('enrollments').select('*,courses(title_ar,title_en,subtitle_ar)').eq('user_id',user.id).order('last_accessed_at',{ascending:false}).then(({data})=>setItems((data||[]) as unknown as Enrollment[]));},[user]);return <main className={styles.page}><FeaturePageHero icon={History} eyebrow="ACTIVITY" title={lang==='ar'?'سجل التعلم':'Learning History'} subtitle={lang==='ar'?'ارجع بسرعة لآخر الكورسات التي درستها وتابع تقدمك.':'Return to your recent learning activity.'}/>{!items.length?<div className={styles.empty}><History size={38}/><strong>لا يوجد نشاط تعليمي بعد</strong></div>:<section className={styles.list}>{items.map(e=><article className={styles.card} key={e.id}><div className={styles.cardTop}><div><h3>{e.courses?.title_ar||'كورس'}</h3><p>{e.courses?.subtitle_ar}</p></div><span className={styles.badge}>{Math.round(e.progress_percentage)}%</span></div><div className={styles.meta}><span>{e.last_accessed_at?new Date(e.last_accessed_at).toLocaleDateString():'—'}</span><Link className={styles.action} href={`/learn/${e.course_id}`}><PlayCircle size={13}/>استكمال</Link></div></article>)}</section>}</main>}
