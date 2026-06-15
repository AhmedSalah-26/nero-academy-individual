'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import { MessageCircle, Send, User, X } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import styles from '../student-features.module.css';

interface Instructor {
  id: string;
  name?: string;
  email?: string;
  avatar_url?: string;
}

interface Message {
  id: string;
  message_text?: string;
  created_at: string;
  user_id: string;
  profiles?: { name?: string };
}

export default function ChatPage() {
  const { lang, user } = useApp();
  const [instructors, setInstructors] = useState<Instructor[]>([]);
  const [activeConversation, setActiveConversation] = useState<string | null>(null);
  const [activeOtherUser, setActiveOtherUser] = useState<Instructor | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!user) return;
    const currentUser = user;

    async function loadInstructors() {
      const { data: enrollments } = await supabase
        .from('enrollments')
        .select('course_id')
        .eq('user_id', currentUser.id)
        .in('status', ['active', 'completed']);

      const courseIds = (enrollments || []).map((e: { course_id: string }) => e.course_id);
      if (courseIds.length === 0) {
        setLoading(false);
        return;
      }

      const { data: courses } = await supabase
        .from('courses')
        .select('instructor_id')
        .in('id', courseIds);

      const instructorIds = Array.from(
        new Set((courses || []).map((c: { instructor_id?: string }) => c.instructor_id).filter(Boolean))
      );
      if (instructorIds.length === 0) {
        setLoading(false);
        return;
      }

      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, name, email, avatar_url')
        .in('id', instructorIds);

      setInstructors((profiles || []) as Instructor[]);
      setLoading(false);
    }

    loadInstructors();
  }, [user]);

  const openChat = useCallback(
    async (other: Instructor) => {
      if (!user) return;

      const { data, error } = await supabase.rpc('get_or_create_single_conversation', {
        p_user1_id: user.id,
        p_user2_id: other.id,
      });

      if (error || !data) return;

      const conversationId = data as string;
      setActiveConversation(conversationId);
      setActiveOtherUser(other);

      const { data: msgs } = await supabase
        .from('messages')
        .select('id, message_text, created_at, user_id, profiles(name)')
        .eq('conversation_id', conversationId)
        .eq('is_deleted', false)
        .order('created_at', { ascending: true });

      setMessages((msgs || []) as unknown as Message[]);
    },
    [user]
  );

  useEffect(() => {
    if (!activeConversation) return;

    const channel = supabase
      .channel(`chat-${activeConversation}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${activeConversation}` },
        async () => {
          if (!activeConversation) return;
          const { data: msgs } = await supabase
            .from('messages')
            .select('id, message_text, created_at, user_id, profiles(name)')
            .eq('conversation_id', activeConversation)
            .eq('is_deleted', false)
            .order('created_at', { ascending: true });
          setMessages((msgs || []) as unknown as Message[]);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [activeConversation]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = async () => {
    if (!user || !activeConversation || !text.trim()) return;

    await supabase.from('messages').insert({
      conversation_id: activeConversation,
      user_id: user.id,
      message_text: text.trim(),
      message_type: 'text',
    });

    setText('');
  };

  if (!user) {
    return (
      <main className={styles.page}>
        <div className={styles.empty}>
          {lang === 'ar' ? 'سجل الدخول لاستخدام المحادثات' : 'Sign in to use chat'}
        </div>
      </main>
    );
  }

  return (
    <main className={styles.page}>
      <FeaturePageHero
        icon={MessageCircle}
        eyebrow="MESSAGES"
        title={lang === 'ar' ? 'محادثاتي' : 'My Chats'}
        subtitle={lang === 'ar' ? 'تواصل مباشر مع المدرسين.' : 'Direct messaging with instructors.'}
      />

      <div className={styles.chatLayout}>
        <aside className={`${styles.chatSidebar} glass`}>
          <h3>{lang === 'ar' ? 'المدرسين' : 'Instructors'}</h3>
          {loading ? (
            <div className={styles.empty}>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</div>
          ) : instructors.length === 0 ? (
            <div className={styles.empty}>
              {lang === 'ar' ? 'لا يوجد مدرسين متاحين' : 'No instructors available'}
            </div>
          ) : (
            <div className={styles.chatUsers}>
              {instructors.map((inst) => (
                <button
                  key={inst.id}
                  className={`${styles.chatUser} ${activeOtherUser?.id === inst.id ? styles.activeUser : ''}`}
                  onClick={() => openChat(inst)}
                >
                  {inst.avatar_url ? (
                    <img src={inst.avatar_url} alt="" className={styles.chatAvatar} />
                  ) : (
                    <div className={styles.chatAvatarPlaceholder}>
                      <User size={16} />
                    </div>
                  )}
                  <span>{inst.name || inst.email}</span>
                </button>
              ))}
            </div>
          )}
        </aside>

        <section className={`${styles.chatWindow} glass`}>
          {activeConversation && activeOtherUser ? (
            <>
              <div className={styles.chatHeader}>
                <span>{activeOtherUser.name || activeOtherUser.email}</span>
                <button className={styles.modalClose} onClick={() => setActiveConversation(null)}>
                  <X size={18} />
                </button>
              </div>

              <div className={styles.chatMessages}>
                {messages.map((m) => {
                  const isMe = m.user_id === user.id;
                  return (
                    <div key={m.id} className={`${styles.chatMessage} ${isMe ? styles.myMessage : ''}`}>
                      <div className={styles.chatBubble}>
                        <small>{m.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')}</small>
                        <p>{m.message_text}</p>
                        <span className={styles.chatTime}>
                          {new Date(m.created_at).toLocaleTimeString(lang === 'ar' ? 'ar-EG' : 'en-US', {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </span>
                      </div>
                    </div>
                  );
                })}
                <div ref={bottomRef} />
              </div>

              <div className={styles.chatInputRow}>
                <input
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && sendMessage()}
                  placeholder={lang === 'ar' ? 'اكتب رسالتك...' : 'Type a message...'}
                  className={styles.input}
                />
                <button onClick={sendMessage} disabled={!text.trim()} className={styles.action}>
                  <Send size={16} />
                </button>
              </div>
            </>
          ) : (
            <div className={styles.empty}>
              <MessageCircle size={48} />
              <strong>{lang === 'ar' ? 'اختر مدرساً للبدء' : 'Select an instructor to start'}</strong>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
