# المهمة 5 — تنفيذ 026 والتحقق من Realtime

## 1) تنفيذ 026 في Supabase

- افتح **Supabase Dashboard → SQL Editor**.
- انسخ محتوى الملف **`supabase/migrations/026_announcements.sql`** كاملاً والصقه في استعلام جديد.
- شغّل الاستعلام. النتيجة المتوقعة: **Success. No rows returned**.

## 2) التحقق من Realtime

شغّل الاستعلام التالي في SQL Editor:

```sql
SELECT tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('correction_requests', 'notes', 'announcements')
ORDER BY tablename;
```

**النتيجة المتوقعة:** 3 صفوف — `announcements`, `correction_requests`, `notes`.

إن ظهر جدول ناقص (مثلاً لا `announcements`)، شغّل يدوياً:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
```

ثم أعد الاستعلام أعلاه للتأكد.
