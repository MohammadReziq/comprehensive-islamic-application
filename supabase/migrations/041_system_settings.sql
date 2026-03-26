-- [041] جدول إعدادات النظام
-- السوبر أدمن يتحكم بالإعدادات العامة للتطبيق

CREATE TABLE IF NOT EXISTS system_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  label      TEXT,           -- وصف بالعربية للعرض في الـ UI
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- القيم الافتراضية
INSERT INTO system_settings (key, value, label) VALUES
  ('default_attendance_window_hours', '24', 'نافذة تسجيل الحضور (ساعات)')
ON CONFLICT (key) DO NOTHING;

-- RLS
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- الكل يقرأ (التطبيق يحتاج يقرأ الإعدادات)
CREATE POLICY "anyone_can_read_settings"
ON system_settings FOR SELECT
USING (true);

-- السوبر أدمن فقط يُعدّل
CREATE POLICY "superadmin_updates_settings"
ON system_settings FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_id = auth.uid() AND role = 'super_admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_id = auth.uid() AND role = 'super_admin'
  )
);

-- السوبر أدمن يُضيف إعدادات جديدة
CREATE POLICY "superadmin_inserts_settings"
ON system_settings FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_id = auth.uid() AND role = 'super_admin'
  )
);
