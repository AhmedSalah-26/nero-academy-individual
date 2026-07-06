-- Keep notification inboxes scoped to the real recipient and account lifetime.
-- This removes stale rows that may have been copied/created before the profile existed.

DELETE FROM notifications n
USING profiles p
WHERE n.user_id = p.id
  AND n.created_at < p.created_at;

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON notifications(user_id, created_at DESC);
