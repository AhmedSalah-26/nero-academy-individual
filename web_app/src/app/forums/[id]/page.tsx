'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useParams } from 'next/navigation';
import { Chat, Send, Person } from '@mui/icons-material';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { usePageTransition } from '../../../lib/animations';
import styles from '../../student-features.module.css';

type ForumMessage = {
  id: string;
  user_id: string;
  message_text: string;
  created_at: string;
  profiles?: {
    name?: string | null;
  } | null;
};

export default function ForumPage() {
  const params = useParams<{ id: string }>();
  const courseId = params.id;
  const pageRef = usePageTransition();
  const { user } = useApp();
  const [items, setItems] = useState<ForumMessage[]>([]);
  const [message, setMessage] = useState('');
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  const loadMessages = useCallback(async () => {
    if (!courseId) return;

    const { data } = await supabase
      .from('messages')
      .select('id, user_id, message_text, created_at, profiles(name)')
      .eq('conversation_id', courseId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: true });

    setItems((data as ForumMessage[] | null) ?? []);
  }, [courseId]);

  useEffect(() => {
    const timer = window.setTimeout(() => void loadMessages(), 0);

    const channel = supabase
      .channel(`forum-${courseId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${courseId}`,
        },
        () => void loadMessages(),
      )
      .subscribe();

    return () => {
      window.clearTimeout(timer);
      void supabase.removeChannel(channel);
    };
  }, [courseId, loadMessages]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [items]);

  const sendMessage = async () => {
    const text = message.trim();
    if (!text || !user?.id || sending) return;

    setSending(true);
    setMessage('');

    const { error } = await supabase.from('messages').insert({
      conversation_id: courseId,
      user_id: user.id,
      message_text: text,
      message_type: 'text',
    });

    if (error) setMessage(text);
    else await loadMessages();

    setSending(false);
  };

  return (
    <main ref={pageRef} className={`${styles.page} ${styles.forumPage}`}>
      <header className={styles.forumHeader}>
        <span>LIVE DISCUSSION</span>
        <div>
          <Chat fontSize="medium" />
          <h1>مناقشة الكورس</h1>
        </div>
        <p>تواصل مع المدرس وزملائك في مساحة آمنة ومرتبة خاصة بالكورس.</p>
      </header>

      <section className={styles.forumWindow}>
        <div className={styles.forumMessages}>
          {items.length === 0 && (
            <div className={styles.forumEmpty}>
              <Chat fontSize="medium" />
              <strong>ابدأ أول نقاش</strong>
              <span>اكتب سؤالك أو شارك زملاءك فكرة مفيدة.</span>
            </div>
          )}

          {items.map((item) => {
            const mine = item.user_id === user?.id;
            return (
              <div
                className={`${styles.forumMessage} ${mine ? styles.forumMessageMine : ''}`}
                key={item.id}
              >
                <article className={styles.forumBubble}>
                  <div className={styles.forumAuthor}>
                    <span className={styles.forumAvatar}>
                      <Person fontSize="small" />
                    </span>
                    <strong>{mine ? 'أنت' : item.profiles?.name || 'طالب'}</strong>
                  </div>
                  <p>{item.message_text}</p>
                  <time>
                    {new Intl.DateTimeFormat('ar-EG', {
                      hour: 'numeric',
                      minute: '2-digit',
                    }).format(new Date(item.created_at))}
                  </time>
                </article>
              </div>
            );
          })}
          <div ref={bottomRef} />
        </div>

        <div className={styles.forumComposer}>
          <input
            value={message}
            onChange={(event) => setMessage(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' && !event.shiftKey) {
                event.preventDefault();
                void sendMessage();
              }
            }}
            placeholder={user ? 'اكتب رسالتك...' : 'سجّل الدخول للمشاركة في النقاش'}
            disabled={!user || sending}
          />
          <button
            type="button"
            onClick={() => void sendMessage()}
            disabled={!user || sending || !message.trim()}
          >
            <Send fontSize="small" />
            إرسال
          </button>
        </div>
      </section>
    </main>
  );
}
