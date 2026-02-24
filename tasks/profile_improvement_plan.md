# خطة تحسين البروفايل — ملفات لكل دور لـ Claude

استخدم هذه القوائم لإعطاء Claude الملفات المناسبة لكل دور.

---

## نطاق التنفيذ الحالي (ملاحظة مهمة)

- **يشمل:** تعديل الاسم، تعديل الهاتف، **تغيير كلمة المرور** (من داخل الملف الشخصي).
- **بدون تغيير الصورة حالياً:** لا نضيف زر أو ميزة تغيير صورة الملف الشخصي (avatar) — يُؤجل لاحقاً.

---

## دور 1: ولي الأمر + إمام + مشرف (البروفايل المشترك ProfileScreen)

**المهمة:** تحسين `ProfileScreen` لجميع الأدوار الثلاثة: تعديل الاسم، تعديل الهاتف، تغيير كلمة المرور. **بدون إضافة تغيير الصورة (avatar) حالياً — يبقى العرض الحالي (أول حرف من الاسم في دائرة).**

**الملفات المطلوبة:**
```
lib/app/features/profile/presentation/screens/profile_screen.dart
lib/app/features/auth/presentation/bloc/auth_bloc.dart
lib/app/features/auth/presentation/bloc/auth_event.dart
lib/app/features/auth/data/repositories/auth_repository.dart
lib/app/models/user_model.dart
lib/app/features/parent/data/repositories/child_repository.dart
lib/app/features/mosque/presentation/bloc/mosque_bloc.dart
lib/app/features/mosque/presentation/bloc/mosque_state.dart
lib/app/models/mosque_model.dart
lib/app/features/parent/presentation/screens/home_screen.dart
lib/app/features/imam/presentation/screens/imam_dashboard_screen.dart
lib/app/features/supervisor/presentation/screens/supervisor_dashboard_screen.dart
lib/app/core/constants/app_colors.dart
lib/app/core/constants/app_dimensions.dart
lib/app/core/constants/app_enums.dart
docs/profile_improvement_spec.md
```

---

## دور 2: سوبر أدمن (AdminProfileTab)

**المهمة:** تحسين تبويب "ملفي" في لوحة الأدمن — عرض بيانات المستخدم الحقيقية (الاسم، الإيميل) بدل النص الثابت.

**الملفات المطلوبة:**
```
lib/app/features/super_admin/presentation/screens/admin_screen_tabs.dart
lib/app/features/super_admin/presentation/screens/admin_screen.dart
lib/app/features/auth/presentation/bloc/auth_bloc.dart
lib/app/features/auth/presentation/bloc/auth_state.dart
lib/app/models/user_model.dart
lib/app/core/constants/app_colors.dart
lib/app/core/constants/app_dimensions.dart
lib/app/core/constants/app_strings.dart
docs/profile_improvement_spec.md
```

---

## دور 3: ابن (ChildViewScreen — شاشة "حسابي")

**المهمة:** تحسين شاشة حساب الابن (اسم، QR، حضور اليوم، طلب تصحيح، تسجيل خروج إن وُجد).

**الملفات المطلوبة:**
```
lib/app/features/parent/presentation/screens/child_view_screen.dart
lib/app/features/auth/data/repositories/auth_repository.dart
lib/app/features/parent/data/repositories/child_repository.dart
lib/app/models/child_model.dart
lib/app/models/attendance_model.dart
lib/app/core/constants/app_colors.dart
lib/app/core/constants/app_dimensions.dart
lib/app/core/constants/app_enums.dart
docs/profile_improvement_spec.md
```

---

## مراجع سريعة (اختياري — للسياق)

- `docs/parent_capabilities_spec.md` — مواصفات ولي الأمر
- `docs/imam_capabilities_spec.md` — مواصفات الإمام
- `docs/supervisor_capabilities_spec.md` — مواصفات المشرف
