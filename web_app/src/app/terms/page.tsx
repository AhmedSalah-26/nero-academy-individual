import Link from 'next/link';
import styles from '../settings/legal.module.css';

export default function TermsPage() {
  return <main className={styles.page}><Link href="/settings">العودة للإعدادات</Link><h1>شروط الاستخدام</h1><p>باستخدام المنصة، توافق على استخدام المحتوى للأغراض التعليمية الشخصية والالتزام بقواعد المجتمع.</p><h2>الحساب والمحتوى</h2><p>الحساب مخصص لصاحبه، ولا يجوز مشاركة المحتوى المدفوع أو إعادة نشره دون إذن.</p><h2>المجتمع</h2><p>يجب احترام الطلاب والمدرسين وتجنب الرسائل المسيئة أو المحتوى غير المرتبط بالتعلم.</p></main>;
}
