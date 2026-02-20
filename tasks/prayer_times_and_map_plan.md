# خطة تنفيذ: مواقيت الصلاة (Aladhan API) والخريطة

> **المرجع:** `docs/study_prayer_times_and_mosque_location.md`  
> **الحالة والخطوة التالية:** `tasks/todo.md`

---

## المرحلة 1 — Aladhan API واستبدال adhan ✅

- [x] عميل API: `lib/app/core/network/aladhan_api.dart` (method=3 للأردن).
- [x] Cache في `PrayerTimesService` + `loadTimingsFor(lat, lng)` و `getNextPrayer(lat, lng)`.
- [x] `AttendanceValidationService`: `getAdhanTime()` و `canRecordNow(..., isImam)`.
- [x] حذف حزمة `adhan`.

## المرحلة 2 — ربط الإحداثيات حسب الدور ✅

- [x] إمام/مشرف: مواقيت حسب موقع المسجد.
- [x] ولي أمر: إحداثيات عمان الافتراضية.
- [x] مراجعة الشاشات: home, scanner, supervisor_dashboard, imam_dashboard.

## المرحلة 3 — الخريطة عند إنشاء المسجد ✅

- [x] شاشة كاملة؛ بداية من موقع المستخدم؛ النقر على مكان المسجد بالضبط.

## المرحلة 4 — التحقق والاختبار

- [ ] التحقق: مواقيت اليوم صحيحة للأردن (مقارنة مع مصدر معتمد).
- [ ] التحقق: قبول/رفض التحضير حسب النافذة والإحداثيات.
- [ ] التحقق: كل الأدوار يرون «الصلاة القادمة» بشكل سليم.

---

**ملاحظة:** الإمام يسجّل حضور بدون قيد الساعة؛ المشرف مقيد بنافذة الحضور ويعرض له «متبقي X دقيقة» أو «انتهت مهلة التسجيل».
