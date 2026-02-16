-- طلبات الانضمام للمسجد: المشرف يدخل الكود → يرسل طلب → الإمام يوافق أو يرفض
CREATE TYPE mosque_join_request_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TABLE mosque_join_requests (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id    UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       mosque_join_request_status NOT NULL DEFAULT 'pending',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at  TIMESTAMPTZ,
  reviewed_by  UUID REFERENCES users(id),
  UNIQUE(mosque_id, user_id)
);

CREATE INDEX idx_join_requests_mosque ON mosque_join_requests(mosque_id);
CREATE INDEX idx_join_requests_user ON mosque_join_requests(user_id);
CREATE INDEX idx_join_requests_status ON mosque_join_requests(status);

ALTER TABLE mosque_join_requests ENABLE ROW LEVEL SECURITY;

-- المستخدم يضيف طلب انضمام لنفسه فقط (لمسجد معتمد)
CREATE POLICY "Join requests: user insert own"
  ON mosque_join_requests FOR INSERT
  WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    AND mosque_id IN (SELECT id FROM mosques WHERE status = 'approved')
  );

-- المستخدم يقرأ طلباته
CREATE POLICY "Join requests: user read own"
  ON mosque_join_requests FOR SELECT
  USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- مالك المسجد يقرأ طلبات مسجده
CREATE POLICY "Join requests: owner read mosque"
  ON mosque_join_requests FOR SELECT
  USING (
    mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- مالك المسجد يعدّل طلبات مسجده (موافقة/رفض)
CREATE POLICY "Join requests: owner update mosque"
  ON mosque_join_requests FOR UPDATE
  USING (
    mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );
