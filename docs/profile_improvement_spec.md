# تحسين صفحة البروفايل لكل الأدوار

وثيقة توضح ما يلزم كل دور في صفحة البروفايل، والملفات المطلوبة لكل دور، حتى يمكن إعطاء Claude الملفات المناسبة وتحسين كل شيء.

---

## 1. من يستخدم البروفايل اليوم؟

| الدور | الشاشة/التبويب | الموقع |
|-------|----------------|--------|
| **ولي الأمر (parent)** | ProfileScreen | تبويب "الملف الشخصي" في IndexedStack (الرئيسية) |
| **إمام (imam)** | ProfileScreen | تبويب "الملف الشخصي" في IndexedStack (لوحة الإمام) |
| **مشرف (supervisor)** | ProfileScreen | تبويب "الملف الشخصي" في IndexedStack (لوحة المشرف) |
| **سوبر أدمن (super_admin)** | AdminProfileTab | تبويب "ملفي" في لوحة الأدمن (IndexedStack) |
| **ابن (child)** | ChildViewScreen | شاشة "حسابي" منفصلة — ليست بروفايل بالمعنى نفسه |

---

## 2. ما يلزم كل دور في البروفايل

### ولي الأمر (parent)
- **البيانات:** الاسم، الإيميل، الهاتف، الدور (ولي أمر)، صورة شخصية (avatar إن وُجدت).
- **قسم إضافي:** أطفالي (قائمة الأطفال مع الاسم والعمر).
- **الإجراءات:** تعديل الاسم، تعديل الهاتف، تسجيل الخروج.
- **ملاحظة:** الإيميل يُعرض فقط (عادة لا يُعدّل من التطبيق — يتعلق بـ Auth).

### إمام (imam)
- **البيانات:** الاسم، الإيميل، الهاتف، الدور (إمام)، صورة شخصية.
- **قسم إضافي:** مسجدي (قائمة المساجد المعتمدة — اسم كل مسجد، يمكن الربط بصفحة إعدادات المسجد).
- **الإجراءات:** تعديل الاسم، تعديل الهاتف، تسجيل الخروج.

### مشرف (supervisor)
- **البيانات:** الاسم، الإيميل، الهاتف، الدور (مشرف)، صورة شخصية.
- **قسم إضافي:** مسجدي (قائمة المساجد المعتمدة).
- **الإجراءات:** تعديل الاسم، تعديل الهاتف، تسجيل الخروج.

### سوبر أدمن (super_admin)
- **البيانات:** الاسم، الإيميل، الدور (مدير النظام) — حالياً التبويب يعرض "سوبر أدمن" و"مدير النظام" ثابتين بدون بيانات المستخدم الحقيقي.
- **الإجراءات:** تعديل الاسم إن رغبت، تسجيل الخروج.
- **تحسين مطلوب:** عرض بيانات المستخدم من AuthBloc (user.name, user.email) بدل النص الثابت.

### ابن (child)
- **الموقع:** ChildViewScreen — شاشة "حسابي" وليست تبويب بروفايل.
- **المحتوى:** اسم الطفل، QR code، حضور اليوم، طلب تصحيح حضور.
- **الإجراءات:** تسجيل خروج (إن وُجد) — الابن عادة لا يعدّل بياناته من التطبيق.

---

## 3. الملفات المطلوبة لكل دور

### ولي الأمر (parent) — تحسين البروفايل
| الملف | الاستخدام |
|-------|-----------|
| `lib/app/features/profile/presentation/screens/profile_screen.dart` | الشاشة الرئيسية — تعديل قسم ولي الأمر (_ChildrenSection، إضافة تعديل الاسم/الهاتف) |
| `lib/app/features/auth/presentation/bloc/auth_bloc.dart` | إضافة حدث تحديث البروفايل (إن لزم) |
| `lib/app/features/auth/presentation/bloc/auth_event.dart` | حدث AuthProfileUpdated |
| `lib/app/features/auth/data/repositories/auth_repository.dart` | updateUserProfile — موجود |
| `lib/app/models/user_model.dart` | مرجع للبيانات |
| `lib/app/features/parent/data/repositories/child_repository.dart` | getMyChildren للقسم أطفالي |
| `lib/app/features/parent/presentation/screens/home_screen.dart` | حيث يُعرض ProfileScreen في IndexedStack |
| `lib/app/core/constants/app_colors.dart` | الألوان |
| `lib/app/core/constants/app_dimensions.dart` | الأبعاد |

### إمام (imam) — تحسين البروفايل
| الملف | الاستخدام |
|-------|-----------|
| `lib/app/features/profile/presentation/screens/profile_screen.dart` | تعديل قسم الإمام (_MosqueSection، إضافة روابط لإعدادات المسجد إن رغبت) |
| `lib/app/features/auth/presentation/bloc/auth_bloc.dart` | حدث تحديث البروفايل |
| `lib/app/features/auth/data/repositories/auth_repository.dart` | updateUserProfile |
| `lib/app/features/mosque/presentation/bloc/mosque_bloc.dart` | MosqueLoaded للقسم مسجدي |
| `lib/app/features/imam/presentation/screens/imam_dashboard_screen.dart` | حيث يُعرض ProfileScreen |

### مشرف (supervisor) — تحسين البروفايل
| الملف | الاستخدام |
|-------|-----------|
| `lib/app/features/profile/presentation/screens/profile_screen.dart` | نفس تعديلات الإمام تقريباً (قسم مسجدي) |
| `lib/app/features/auth/presentation/bloc/auth_bloc.dart` | حدث تحديث البروفايل |
| `lib/app/features/auth/data/repositories/auth_repository.dart` | updateUserProfile |
| `lib/app/features/mosque/presentation/bloc/mosque_bloc.dart` | MosqueLoaded |
| `lib/app/features/supervisor/presentation/screens/supervisor_dashboard_screen.dart` | حيث يُعرض ProfileScreen |

### سوبر أدمن (super_admin)
| الملف | الاستخدام |
|-------|-----------|
| `lib/app/features/super_admin/presentation/screens/admin_screen_tabs.dart` | AdminProfileTab — استبدال النص الثابت ببيانات المستخدم من AuthBloc |
| `lib/app/features/auth/presentation/bloc/auth_bloc.dart` | قراءة userProfile |
| `lib/app/features/super_admin/presentation/screens/admin_screen.dart` | السياق العام |

### ابن (child)
| الملف | الاستخدام |
|-------|-----------|
| `lib/app/features/parent/presentation/screens/child_view_screen.dart` | شاشة "حسابي" — يمكن تحسينها كبروفايل للابن (اسم، QR، حضور، تسجيل خروج) |
| `lib/app/features/auth/data/repositories/auth_repository.dart` | getCurrentUserProfile |
| `lib/app/features/parent/data/repositories/child_repository.dart` | getChildByLoginUserId، getAttendanceForChildOnDate |

---

## 4. الملف المشترك — ProfileScreen

**الملف:** `lib/app/features/profile/presentation/screens/profile_screen.dart`

**المحتوى الحالي:**
- Avatar (الحرف الأول من الاسم)
- الاسم، الدور، الإيميل، الهاتف
- _MosqueSection (للإمام والمشرف)
- _ChildrenSection (لولي الأمر)
- زر تسجيل الخروج

**تحسينات مقترحة (مشتركة لجميع الأدوار):**
1. عرض avatar من `user.avatarUrl` إن وُجد، وإلا الحرف الأول.
2. إضافة زر "تعديل" للاسم والهاتف — فتح حوار أو شاشة تعديل، استدعاء `AuthRepository.updateUserProfile`، ثم تحديث AuthBloc (حدث جديد `AuthProfileUpdated` أو إعادة جلب الـ profile).
3. تحسين التصميم: بطاقات، تباعد، ألوان متناسقة مع باقي التطبيق.
4. إضافة روابط سريعة حسب الدور: ولي الأمر → أطفالي، إمام/مشرف → مسجدي أو إعدادات المسجد.

---

## 5. ملخص: الملفات التي تحتاج تعديلاً لكل دور

### لتعديل البروفايل المشترك (parent + imam + supervisor)
```
lib/app/features/profile/presentation/screens/profile_screen.dart
lib/app/features/auth/presentation/bloc/auth_bloc.dart
lib/app/features/auth/presentation/bloc/auth_event.dart
lib/app/features/auth/data/repositories/auth_repository.dart
lib/app/models/user_model.dart
lib/app/features/parent/data/repositories/child_repository.dart
lib/app/features/mosque/presentation/bloc/mosque_bloc.dart
lib/app/features/mosque/presentation/bloc/mosque_state.dart
lib/app/features/parent/presentation/screens/home_screen.dart
lib/app/features/imam/presentation/screens/imam_dashboard_screen.dart
lib/app/features/supervisor/presentation/screens/supervisor_dashboard_screen.dart
lib/app/core/constants/app_colors.dart
lib/app/core/constants/app_dimensions.dart
```

### لتعديل بروفايل السوبر أدمن فقط
```
lib/app/features/super_admin/presentation/screens/admin_screen_tabs.dart
lib/app/features/auth/presentation/bloc/auth_bloc.dart
lib/app/features/auth/presentation/bloc/auth_state.dart
lib/app/features/super_admin/presentation/screens/admin_screen.dart
```

### لتعديل شاشة الابن (حسابي)
```
lib/app/features/parent/presentation/screens/child_view_screen.dart
lib/app/features/auth/data/repositories/auth_repository.dart
lib/app/features/parent/data/repositories/child_repository.dart
```

---

## 6. توصية لعمل Claude

1. **البروفايل المشترك (parent, imam, supervisor):** أعطِ Claude الملفات في القسم 5 (البروفايل المشترك) + `docs/profile_improvement_spec.md` + `docs/parent_capabilities_spec.md` و`docs/imam_capabilities_spec.md` و`docs/supervisor_capabilities_spec.md` للسياق.
2. **بروفايل السوبر أدمن:** أعطِ الملفات في "بروفايل السوبر أدمن فقط" + هذه الوثيقة.
3. **شاشة الابن:** أعطِ الملفات في "شاشة الابن" + هذه الوثيقة.

بعد ذلك يمكن لـ Claude تحسين البروفايل لكل دور بناءً على هذه الملفات والمواصفات.
