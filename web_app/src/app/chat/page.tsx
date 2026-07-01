'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import { Chat, Send, Person, Close, DoneAll, Done, Reply, Whatshot } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { AppBackButton, EmptyState, ShimmerEffect, UserAvatar } from '../../components/ui';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface Instructor {
  id: string;
  name?: string;
  email?: string;
  avatar_url?: string;
}

interface MessageReaction {
  emoji: string;
  user_id: string;
}

interface Message {
  id: string;
  message_text?: string;
  created_at: string;
  user_id: string;
  is_read?: boolean;
  reactions?: MessageReaction[];
  reply_to_id?: string;
  reply_to_text?: string;
  profiles?: { name?: string };
}

const REACTION_EMOJIS = ['👍', '❤️', '😂', '😮', '🔥', '🙏'];

export default function ChatPage() {
  const pageRef = usePageTransition();
  const { lang, user } = useApp();
  const [instructors, setInstructors] = useState<Instructor[]>([]);
  const [activeConversation, setActiveConversation] = useState<string | null>(null);
  const [activeOtherUser, setActiveOtherUser] = useState<Instructor | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(true);
  const [replyTo, setReplyTo] = useState<Message | null>(null);
  const [reactionMessageId, setReactionMessageId] = useState<string | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!user) return;
    const uid = user.id;
    async function loadInstructors() {
      const { data: enrollments } = await supabase.from('enrollments').select('course_id')
        .eq('user_id', uid).in('status', ['active', 'completed']);
      const courseIds = (enrollments || []).map((e: { course_id: string }) => e.course_id);
      if (!courseIds.length) { setLoading(false); return; }
      const { data: courses } = await supabase.from('courses').select('instructor_id').in('id', courseIds);
      const ids = Array.from(new Set((courses || []).map((c: { instructor_id?: string }) => c.instructor_id).filter(Boolean)));
      if (!ids.length) { setLoading(false); return; }
      const { data: profiles } = await supabase.from('profiles').select('id, name, email, avatar_url').in('id', ids);
      setInstructors((profiles || []) as Instructor[]);
      setLoading(false);
    }
    loadInstructors();
  }, [user]);

  const openChat = useCallback(async (other: Instructor) => {
    if (!user) return;
    const { data, error } = await supabase.rpc('get_or_create_single_conversation', { p_user1_id: user.id, p_user2_id: other.id });
    if (error || !data) return;
    const conversationId = data as string;
    setActiveConversation(conversationId);
    setActiveOtherUser(other);
    const { data: msgs } = await supabase.from('messages').select('id, message_text, created_at, user_id, profiles(name)')
      .eq('conversation_id', conversationId).eq('is_deleted', false).order('created_at', { ascending: true });
    setMessages((msgs || []) as unknown as Message[]);
  }, [user]);

  useEffect(() => {
    if (!activeConversation) return;
    const channel = supabase.channel(`chat-${activeConversation}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${activeConversation}` },
        async () => {
          if (!activeConversation) return;
          const { data: msgs } = await supabase.from('messages').select('id, message_text, created_at, user_id, profiles(name)')
            .eq('conversation_id', activeConversation).eq('is_deleted', false).order('created_at', { ascending: true });
          setMessages((msgs || []) as unknown as Message[]);
        })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [activeConversation]);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  const sendMessage = async () => {
    if (!user || !activeConversation || !text.trim()) return;
    await supabase.from('messages').insert({
      conversation_id: activeConversation, user_id: user.id,
      message_text: text.trim(), message_type: 'text',
      reply_to_id: replyTo?.id || null,
    });
    setText('');
    setReplyTo(null);
  };

  const handleReaction = async (messageId: string, emoji: string) => {
    if (!user) return;
    await supabase.from('direct_message_reactions').upsert({
      message_id: messageId, user_id: user.id, emoji,
    }, { onConflict: 'message_id,user_id' });
    setReactionMessageId(null);
  };

  if (!user) return <main className={styles.page}><EmptyState type="instructors" /></main>;

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.header}>
        <AppBackButton />
        <h1>{lang === 'ar' ? 'محادثاتي' : 'My Chats'}</h1>
      </div>

      <div className={styles.chatLayout}>
        <aside className={styles.chatSidebar}>
          <h3>{lang === 'ar' ? 'المدرسين' : 'Instructors'}</h3>
          {loading ? Array.from({ length: 3 }).map((_, i) => <ShimmerEffect key={i} height={48} />) : instructors.length === 0 ? (
            <EmptyState type="instructors" />
          ) : (
            <div className={styles.chatUsers}>
              {instructors.map((inst) => (
                <button key={inst.id} className={`${styles.chatUser} ${activeOtherUser?.id === inst.id ? styles.activeUser : ''}`} onClick={() => openChat(inst)}>
                  <UserAvatar alt={inst.name || ''} src={inst.avatar_url} size="sm" />
                  <span>{inst.name || inst.email}</span>
                </button>
              ))}
            </div>
          )}
        </aside>

        <section className={styles.chatWindow}>
          {activeConversation && activeOtherUser ? (
            <>
              <div className={styles.chatHeader}>
                <UserAvatar alt={activeOtherUser.name || ''} src={activeOtherUser.avatar_url} size="sm" />
                <span className={styles.chatHeaderName}>{activeOtherUser.name || activeOtherUser.email}</span>
                <button className={styles.modalClose} onClick={() => { setActiveConversation(null); setActiveOtherUser(null); }}>
                  <Close fontSize="small" />
                </button>
              </div>

              <div className={styles.chatMessages}>
                {messages.map((m) => {
                  const isMe = m.user_id === user.id;
                    return (
                    <div key={m.id} className={`${styles.chatMessage} ${isMe ? styles.myMessage : styles.theirMessage}`}
                      onContextMenu={(e) => { e.preventDefault(); setReactionMessageId(m.id); }}>
                      {!isMe && <small className={styles.senderName}>{m.profiles?.name || (lang === 'ar' ? 'مدرس' : 'Instructor')}</small>}
                      {m.reply_to_text && <div className={styles.replyPreview}>{m.reply_to_text.slice(0, 60)}</div>}
                      <div className={styles.chatBubble}>
                        <p>{m.message_text}</p>
                        <div className={styles.bubbleFooter}>
                          <span className={styles.chatTime}>
                            {new Date(m.created_at).toLocaleTimeString(lang === 'ar' ? 'ar-EG' : 'en-US', { hour: '2-digit', minute: '2-digit' })}
                          </span>
                          {isMe && (
                            <span className={styles.readReceipt}>
                              {m.is_read ? <DoneAll fontSize="small" className={styles.readReceiptRead} /> : <Done fontSize="small" />}
                            </span>
                          )}
                        </div>
                      </div>
                      {m.reactions && m.reactions.length > 0 && (
                        <div className={styles.reactionsRow}>
                          {Object.entries(m.reactions.reduce<Record<string, number>>((acc, r) => { acc[r.emoji] = (acc[r.emoji] || 0) + 1; return acc; }, {})).map(([emoji, count]) => (
                            <span key={emoji} className={styles.reactionChip}>{emoji} {count > 1 && count}</span>
                          ))}
                        </div>
                      )}
                      <button className={styles.replyBtn} onClick={() => setReplyTo(m)} aria-label="Reply">
                        <Reply fontSize="small" />
                      </button>
                    </div>
                  );
                })}
                <div ref={bottomRef} />
              </div>

              {reactionMessageId && (
                <div className={styles.reactionPicker}>
                  {REACTION_EMOJIS.map((emoji) => (
                    <button key={emoji} className={styles.reactionBtn} onClick={() => handleReaction(reactionMessageId, emoji)}>{emoji}</button>
                  ))}
                  <button className={styles.reactionClose} onClick={() => setReactionMessageId(null)}>✕</button>
                </div>
              )}

              <div className={styles.chatInputArea}>
                {replyTo && (
                  <div className={styles.replyBar}>
                    <span>{lang === 'ar' ? 'رد على:' : 'Reply to:'} {replyTo.message_text?.slice(0, 30)}</span>
                    <button onClick={() => setReplyTo(null)}><Close fontSize="small" /></button>
                  </div>
                )}
                <div className={styles.chatInputRow}>
                  <input value={text} onChange={(e) => setText(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && sendMessage()}
                    placeholder={lang === 'ar' ? 'اكتب رسالتك...' : 'Type a message...'} className={styles.input} />
                  <button onClick={sendMessage} disabled={!text.trim()} className={styles.sendBtn}>
                    <Send fontSize="small" />
                  </button>
                </div>
              </div>
            </>
          ) : (
            <EmptyState type="instructors" title={lang === 'ar' ? 'اختر مدرساً للبدء' : 'Select an instructor to start'} />
          )}
        </section>
      </div>
    </main>
  );
}
