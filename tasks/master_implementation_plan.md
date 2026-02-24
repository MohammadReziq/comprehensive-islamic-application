# الخطة الشاملة — ميزات صلاتي حياتي

> **آخر تحديث:** فبراير 2026  
> وثيقة واحدة تجمع كل الميزات المتفق عليها ونطاق تنفيذها.

---

## ملخص سريع

| # | الميزة | النطاق | ملاحظات |
|---|--------|--------|---------|
| 1 | الإعلانات (Announcements) | كامل: إرسال، استقبال، قراءة/غير مقروء، أدوار | جداول جديدة + واجهات لكل دور |
| 2 | تعديل الملف الشخصي | الاسم، الهاتف، تغيير كلمة المرور فقط | **بدون تغيير الصورة حالياً** |
| 3 | أوقات الصلاة بالـ GPS | ربط geolocator بموقع المستخدم الفعلي | ولي الأمر: موقع المستخدم؛ إمام/مشرف: موقع المسجد |
| 4 | زر النسخ في الشاشة الرئيسية | نسخ الإيميل/كلمة المرور في حوار بيانات دخول الابن | Clipboard |
| 5 | تقارير الوالدين (رسوم بيانية) | رسم أسبوعي/شهري لتقدم الطفل (مسجد vs بيت) | fl_chart موجود — إضافة شاشة/قسم |
| 6 | Dark/Light Mode | مفتاح في الإعدادات + حفظ بـ shared_preferences | قيم Android/iOS موجودة |

---

# 1. ميزة الإعلانات (Announcements)

## 1.1 الهرم والصلاحيات

```
Super Admin  → يرسل لكل الأئمة (منصة كاملة)
     ↓
Imam         → يرسل لكل الأولياء في مسجده (أو إعلان تمهيد مسابقة)
     ↓
Supervisor   → يرسل لأولياء مجموعة طلابه فقط
     ↓
Parent       → يستقبل فقط (من إمام المسجد أو مشرف مجموعة ابنه)
```

- **ولي غير مرتبط بمسجد:** شاشة إعلانات فارغة + رسالة "انضم لمسجد لتستلم الإعلانات".
- **أنواع الإعلان (type):** `general` | `competition_preview` | `event` | `reminder`.

## 1.2 قاعدة البيانات (Supabase)

### جدول `announcements` (توسيع الموجود)

- **موجود حاليًا:** `id`, `mosque_id`, `sender_id`, `title`, `body`, `created_at`, `is_pinned`, `updated_at`.
- **إضافة (migration جديدة):**
  - `sender_role` TEXT (`super_admin` | `imam` | `supervisor`).
  - `target_role` TEXT (`imam` | `parent` | `supervisor` | `all`).
  - `supervisor_group_id` UUID nullable — إن وُجد: إعلان للمشرف لمجموعة معيّنة فقط.
  - `type` TEXT (`general` | `competition_preview` | `event` | `reminder`).
- **ملاحظة:** `mosque_id` يكون NULL عندما الإعلان من السوبر أدمن (منصة كاملة).

### جدول `announcement_reads` (جديد)

| عمود | نوع | وصف |
|------|-----|-----|
| id | UUID PK | |
| announcement_id | UUID FK → announcements | |
| user_id | UUID FK → users | |
| read_at | TIMESTAMPTZ | وقت القراءة |

- فهرس مركب: `(announcement_id, user_id)` UNIQUE.
- عند فتح الوالي للإعلان → إدراج أو تحديث `read_at`.

### RLS (ملخص)

- **SELECT:** الوالي يرى إعلانات مساجد أبنائه؛ المشرف يرى إعلانات مسجده؛ الإمام يرى إعلانات مسجده؛ السوبر أدمن يرى الكل.
- **INSERT:** الإمام (owner) لمسجده؛ المشرف لمجموعته؛ السوبر أدمن بدون mosque_id.
- **تعديل/حذف:** المرسل فقط (sender_id = auth user).

## 1.3 التكامل مع النظام

| حدث | إجراء تلقائي (اختياري لاحقًا) |
|-----|-------------------------------|
| الإمام ينشئ مسابقة | إعلان تلقائي للأولياء |
| السوبر أدمن يوافق على مسجد | إعلان للإمام "تمت الموافقة" |
| المشرف يسجّل حضور | إشعار للولي (إن وُجد نظام إشعارات) |

## 1.4 واجهات المستخدم

- **والد:** قائمة إعلانات (مع تمييز مقروء/غير مقروء)، عند الفتح → mark as read. إن لم يكن مرتبطًا بمسجد → رسالة "انضم لمسجد".
- **إمام:** إنشاء/تعديل/حذف إعلانات، اختيار النوع (عام، تمهيد مسابقة، حدث، تذكير).
- **مشرف:** إنشاء إعلان لمجموعته فقط (نفس النمط).
- **سوبر أدمن:** إرسال إعلان لكل الأئمة؛ عرض كل الإعلانات (مراقبة).

## 1.5 توحيد أسماء الحقول مع قاعدة البيانات

- في قاعدة البيانات الجدول `announcements` يستخدم العمود **`sender_id`** (انظر 001 و 026). التطبيق حاليًا يكتب `created_by` في الـ insert — يجب توحيد الاستخدام مع العمود `sender_id` في الـ repository والـ model (في fromJson/toJson استخدام `sender_id` أو الاحتفاظ بـ `createdBy` في الدارت مع مفتاح `sender_id` في JSON).

## 1.6 الملفات المتأثرة

- `lib/app/models/announcement_model.dart` — إضافة حقول type, sender_role, target_role, supervisor_group_id؛ والتأكد من مفتاح sender_id مع createdBy.
- `lib/app/features/announcements/data/repositories/announcement_repository.dart` — دوال حسب الدور، markAsRead، getForParent (بحسب مساجد الأبناء).
- Bloc/Events: أحداث جديدة مثل LoadAnnouncementsForParent، MarkAnnouncementRead، CreateAnnouncement (مع type و target).
- شاشات جديدة أو توسيع موجودة: Parent (قائمة إعلانات)، Imam (إدارة إعلانات)، Supervisor (إعلانات للمجموعة)، Super Admin (إرسال + عرض).
- Migration: `supabase/migrations/XXX_announcements_reads_and_fields.sql`.

---

# 2. تعديل الملف الشخصي (Profile)

## 2.1 النطاق

- **يشمل:** تعديل الاسم، تعديل الهاتف، **تغيير كلمة المرور** (من داخل الملف الشخصي، المستخدم مسجّل الدخول).
- **بدون تغيير الصورة حالياً:** لا نضيف زر أو ميزة تغيير صورة الملف الشخصي (avatar). يبقى العرض الحالي (أول حرف من الاسم في دائرة).

## 2.2 تغيير كلمة المرور

- **المطلوب:** حقل "كلمة المرور الحالية" + "كلمة المرور الجديدة" + "تأكيد" في شاشة الملف الشخصي (أو في Bottom Sheet / صفحة فرعية).
- **Backend:** Supabase Auth `updateUser(UserAttributes(password: newPassword))` — موجود في `AuthRepository.updatePassword`.
- **Bloc:** حدث جديد مثل `AuthChangePasswordRequested(currentPassword, newPassword)` — التحقق من current عبر re-sign-in أو عبر دالة تحقق إن وُجدت، ثم استدعاء `updatePassword(newPassword)` **بدون** تسجيل خروج.
- **ملاحظة:** `AuthSetNewPasswordRequested` الحالي يُستخدم لتدفق "نسيت كلمة المرور" ويُسجّل خروج بعد التعديل؛ لا نستخدمه للبروفايل.

## 2.3 الملفات

- `lib/app/features/profile/presentation/screens/profile_screen.dart` — إضافة قسم/زر "تغيير كلمة المرور" يفتح حوارًا أو صفحة.
- `lib/app/features/auth/presentation/bloc/auth_event.dart` — حدث تغيير كلمة المرور (من البروفايل).
- `lib/app/features/auth/presentation/bloc/auth_bloc.dart` — معالج يستدعي `updatePassword` دون تسجيل خروج.

---

# 3. أوقات الصلاة بالـ GPS الفعلي

## 3.1 الوضع الحالي

- `PrayerTimesService` يأخذ `lat, lng`؛ الشاشة الرئيسية لولي الأمر تستخدم `PrayerTimesService.defaultLat/defaultLng` (ثابتة).
- الإمام والمشرف يستخدمان `mosque?.lat` و `mosque?.lng` (صحيح).

## 3.2 المطلوب

- **ولي الأمر (HomeScreen):** الحصول على الموقع الحالي عبر `geolocator` (بعد طلب الصلاحيات)، ثم استدعاء `loadTimingsFor(lat, lng)` و `getNextPrayer(lat, lng)` بالإحداثيات الفعلية. عند الفشل أو عدم منح الصلاحية → fallback إلى الإحداثيات الافتراضية (عمان).
- **الإمام/المشرف:** يبقى استخدام موقع المسجد (لا تغيير).

## 3.3 الملفات

- `lib/app/core/services/prayer_times_service.dart` — لا يحتاج تغيير (يستقبل lat/lng).
- `lib/app/features/parent/presentation/screens/home_screen.dart` — في `initState` (أو عند بناء الصفحة): استدعاء `Geolocator.getCurrentPosition()` ثم تحميل المواقيت بالإحداثيات المُرجعة، مع التعامل مع الأخطاء والصلاحيات.

---

# 4. إصلاح زر النسخ في الشاشة الرئيسية

## 4.1 المشكلة

- في حوار "بيانات دخول الابن" (`_showCredentialsDialog`)، كل صف (_credRow) يعرض "الإيميل" أو "كلمة المرور" ويحتوي زر نسخ بـ `onPressed: () {}` (فارغ).

## 4.2 الحل

- استدعاء `Clipboard.setData(ClipboardData(text: value))` عند الضغط على زر النسخ.
- استخدام `import 'package:flutter/services.dart';` (أو من flutter) ثم في `onPressed` نسخ `value` وإظهار SnackBar مثل "تم النسخ".

## 4.3 الملف

- `lib/app/features/parent/presentation/screens/home_screen.dart` — في `_credRow`: تمرير `value` واستخدامه في `onPressed` مع `Clipboard.setData` وSnackBar.

---

# 5. تحسين تقارير الوالدين (رسوم بيانية)

## 5.1 النطاق

- **الهدف:** رسم بياني أسبوعي/شهري لتقدم الطفل في الصلاة مع مقارنة **المسجد** و **البيت**.
- **البيانات:** موجودة في النماذج/الجداول (attendance، نقاط، إلخ). تحتاج استعلامات تجميعية (أسبوع/شهر) وتصنيف حسب المصدر (مسجد vs بيت إن وُجد في البيانات).
- **الرسم:** استخدام `fl_chart` (موجود في المشروع).

## 5.2 ما يُنفّذ

- تحديد مصدر البيانات (جدول الحضور/النقاط وكيفية تمييز مسجد vs بيت).
- شاشة أو قسم في واجهة ولي الأمر: اختيار الطفل + فترة (أسبوع/شهر) + رسم بياني (مثلاً BarChart) يوضح التقدم ومقارنة المسجد والبيت.
- إن لم تكن "البيت" و"المسجد" مفصولين في البيانات حاليًا، توثيق ذلك وتصميم إما توسيع الموديلات أو استخدام نفس البيانات مع تسمية مناسبة حتى يتم الفصل لاحقًا.

## 5.3 الملفات

- نموذج/مستودع لجلب بيانات التقدم (أسبوع/شهر) — قد يكون في `ChildRepository` أو خدمة تقارير.
- ويدجت أو شاشة جديدة تستخدم `fl_chart` (BarChart أو LineChart).
- ربط من شاشة ولي الأمر (مثلاً من بطاقة الطفل أو تبويب "تقارير").

---

# 6. Dark / Light Mode

## 6.1 النطاق

- ملفات Android (`values-night/`) و iOS موجودة. المطلوب: **مفتاح (Switch) في الإعدادات** يحفظ اختيار المستخدم (dark/light/system) في **shared_preferences** ويطبّق الثيم على التطبيق (MaterialApp theme).

## 6.2 ما يُنفّذ

- إضافة `shared_preferences` إن لم تكن مضافة.
- مفتاح تخزين مثل `theme_mode` (قيم: light | dark | system).
- في شاشة الإعدادات (أو الملف الشخصي حسب التصميم): Switch أو قائمة لاختيار الثيم.
- عند بدء التطبيق: قراءة القيمة وتحديد `themeMode` لـ `MaterialApp`.

---

# ترتيب تنفيذ مقترح

| المرحلة | المهمة | السبب |
|--------|--------|-------|
| 1 | زر النسخ (الشاشة الرئيسية) | إصلاح سريع، لا يعتمد على ميزات أخرى |
| 2 | أوقات الصلاة بالـ GPS (ولي الأمر) | تحسين تجربة يومية بدون تغيير في البنية |
| 3 | تغيير كلمة المرور في البروفايل | مكمل لشاشة الملف الشخصي (بدون صورة) |
| 4 | الإعلانات (جداول + منطق + واجهات) | ميزة كبيرة؛ يفضّل بعد استقرار الأساسيات |
| 5 | تقارير الوالدين (رسوم بيانية) | يعتمد على بيانات الحضور والنقاط |
| 6 | Dark/Light Mode | تحسين تجربة، مستقل |

---

# مراجع

- **البروفايل (تفصيل ملفات كل دور):** `tasks/profile_improvement_plan.md`
- **الخرائط/الموقع:** `tasks/maps_implementation_plan.md`, `tasks/todo.md`
- **Supabase:** `supabase/migrations/026_announcements.sql`, `001_initial_schema.sql` (جدول announcements)
