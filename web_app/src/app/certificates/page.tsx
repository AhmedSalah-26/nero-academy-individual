'use client';
import { useEffect, useState } from 'react';
import { EmojiEvents, Verified, Download } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import { usePageTransition } from '../../lib/animations';
import styles from '../student-features.module.css';
type Certificate={id:string;course_title:string;certificate_number:string;completion_date:string;certificate_url?:string;verification_code?:string};
export default function CertificatesPage(){const pageRef=usePageTransition();const{lang,user}=useApp();const[items,setItems]=useState<Certificate[]>([]);useEffect(()=>{if(!user)return;supabase.from('certificates').select('*').eq('user_id',user.id).order('issued_at',{ascending:false}).then(({data})=>setItems((data||[]) as Certificate[]));},[user]);return <main ref={pageRef} className={styles.page}><FeaturePageHero icon={EmojiEvents} eyebrow="ACHIEVEMENTS" title={lang==='ar'?'الشهادات':'Certificates'} subtitle={lang==='ar'?'شهادات إتمام الكورسات والإنجازات الموثقة.':'Your verified learning achievements.'}/>{!items.length?<div className={styles.empty}><EmojiEvents fontSize="large"/><strong>لم تحصل على شهادات بعد</strong><span>أكمل كورساتك لتظهر الشهادات هنا.</span></div>:<section className={styles.grid}>{items.map(c=><article className={styles.card} key={c.id}><div className={styles.cardTop}><div className={styles.cardIcon}><Verified/></div><span className={styles.badge}>موثقة</span></div><h3>{c.course_title}</h3><p>رقم الشهادة: {c.certificate_number}</p><div className={styles.meta}><span>{c.completion_date}</span>{c.certificate_url&&<a className={styles.action} href={c.certificate_url} target="_blank"><Download fontSize="small"/>تحميل</a>}</div></article>)}</section>}</main>}
