-- 032: جدول قراءة الإعلانات (للوالد: مقروء / غير مقروء)
CREATE TABLE IF NOT EXISTS announcement_reads (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id  UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(announcement_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_announcement_reads_user ON announcement_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_announcement ON announcement_reads(announcement_id);

ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;

-- الوالد يدرج/يحدّث سجله فقط (عند فتح إعلان)
CREATE POLICY "users_insert_own_reads"
  ON announcement_reads FOR INSERT
  WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "users_update_own_reads"
  ON announcement_reads FOR UPDATE
  USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- القراءة: المستخدم يرى سجلاته فقط
CREATE POLICY "users_select_own_reads"
  ON announcement_reads FOR SELECT
  USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

COMMENT ON TABLE announcement_reads IS 'تتبع قراءة الوالد للإعلانات — mark as read عند الفتح';
