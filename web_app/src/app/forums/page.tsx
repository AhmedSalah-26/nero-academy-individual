'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { MessagesSquare, Users } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import styles from '../student-features.module.css';
type Forum={id:string;title?:string;type:string;updated_at:string;courses?:{title_ar:string;title_en?:string}};
export default function ForumsPage(){const{lang,user}=useApp();const[items,setItems]=useState<Forum[]>([]);useEffect(()=>{if(!user)return;supabase.from('conversations').select('id,title,type,updated_at,courses(title_ar,title_en)').order('updated_at',{ascending:false}).then(({data})=>setItems((data||[]) as unknown as Forum[]));},[user]);return <main className={styles.page}><FeaturePageHero icon={MessagesSquare} eyebrow="COMMUNITY" title={lang==='ar'?'المنتديات والمناقشات':'Forums'} subtitle={lang==='ar'?'ناقش الدروس واسأل زملاءك وتواصل مع المدرس.':'Discuss lessons with your community.'}/>{!user?<div className={styles.empty}>سجل الدخول للانضمام للمناقشات</div>:!items.length?<div className={styles.empty}><MessagesSquare size={38}/><strong>لا توجد مناقشات متاحة حالياً</strong></div>:<section className={styles.grid}>{items.map(f=><Link href={`/forums/${f.id}`} className={styles.card} key={f.id}><div className={styles.cardIcon}><Users/></div><h3>{f.title||f.courses?.title_ar||'مجموعة نقاش'}</h3><p>{f.type==='multi'?'مناقشة جماعية':'محادثة مباشرة'}</p><div className={styles.meta}><span>{new Date(f.updated_at).toLocaleDateString()}</span><span className={styles.badge}>دخول</span></div></Link>)}</section>}</main>}
