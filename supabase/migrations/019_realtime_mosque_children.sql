-- تفعيل Realtime لجدول mosque_children
-- عند ربط طفل بمسجد (أو إلغاء الربط) يصل الحدث فوراً للمشرف/الإمام

ALTER PUBLICATION supabase_realtime ADD TABLE mosque_children;
