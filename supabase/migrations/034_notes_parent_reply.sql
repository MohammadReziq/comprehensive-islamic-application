-- ============================================================
-- Migration 034: رد ولي الأمر على الملاحظة (مرة واحدة)
-- ============================================================
-- يُضيف عمودي parent_reply و parent_replied_at إلى جدول notes.
-- شرط parent_reply IS NULL في UPDATE يمنع الرد المكرر على مستوى DB.

ALTER TABLE notes
  ADD COLUMN IF NOT EXISTS parent_reply TEXT,
  ADD COLUMN IF NOT EXISTS parent_replied_at TIMESTAMPTZ;

COMMENT ON COLUMN notes.parent_reply IS
  'رد ولي الأمر على الملاحظة — NULL = لم يرد بعد';
COMMENT ON COLUMN notes.parent_replied_at IS
  'تاريخ ووقت رد ولي الأمر';
