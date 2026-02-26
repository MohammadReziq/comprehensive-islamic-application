-- ============================================================
-- Migration 033: attendance source (mosque / correction)
-- ============================================================
-- تمييز مصدر الحضور: تسجيل مباشر من المسجد أو تصحيح مقبول.
-- DEFAULT 'mosque' يضمن عدم كسر السجلات الموجودة.

ALTER TABLE attendance
  ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'mosque'
  CHECK (source IN ('mosque', 'correction'));

COMMENT ON COLUMN attendance.source IS
  'mosque = حضور QR/رقم مباشر | correction = تصحيح مقبول';
