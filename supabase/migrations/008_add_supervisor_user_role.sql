-- إضافة دور "مشرف" في جدول المستخدمين (أقل من الإمام، يدخل بكود الدعوة فقط)
ALTER TYPE user_role ADD VALUE 'supervisor';
