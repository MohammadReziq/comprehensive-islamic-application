// Edge Function: إنشاء حساب مشرف (الإمام فقط)
// 1. التحقق: JWT إمام + المسجد يخصه
// 2. Rate limit: لا أكثر من 10 حسابات/ساعة
// 3. الإنشاء: Admin API ينشئ المستخدم مع role='supervisor'
// 4. الإضافة: mosque_members + supervisor_credentials
// 5. النتيجة: إرجاع بيانات المشرف + temp_password

import { serve } from "std/server";
import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const respond = (status: number, data: object | string) =>
  new Response(
    JSON.stringify(typeof data === "string" ? { error: data } : data),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return respond(401, "مطلوب تسجيل دخول");

    const body = await req.json();
    const { name, email, temp_password: tempPassword, mosque_id: mosqueId } = body as {
      name?: string;
      email?: string;
      temp_password?: string;
      mosque_id?: string;
    };

    if (!name || !email || !tempPassword || !mosqueId) {
      return respond(400, "مطلوب: name, email, temp_password, mosque_id");
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return respond(400, "صيغة الإيميل غير صحيحة");
    }

    if (tempPassword.length < 6) {
      return respond(400, "كلمة السر يجب أن تكون 6 أحرف على الأقل");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")!;

    const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user: callerAuth },
      error: authError,
    } = await supabaseUser.auth.getUser(token);

    if (authError || !callerAuth) {
      return respond(401, "جلسة غير صالحة");
    }

    // التحقق أن المستدعي إمام
    const { data: callerProfile } = await supabaseUser
      .from("users")
      .select("id, role")
      .eq("auth_id", callerAuth.id)
      .single();

    if (!callerProfile) {
      return respond(403, "ملف المستخدم غير موجود");
    }

    if (callerProfile.role !== "imam") {
      return respond(403, "ليس لديك صلاحية لإنشاء حساب مشرف");
    }

    // تحقق أن المسجد يخص هذا الإمام
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const { data: mosque } = await supabaseAdmin
      .from("mosques")
      .select("id, owner_id")
      .eq("id", mosqueId)
      .single();

    if (!mosque || mosque.owner_id !== callerProfile.id) {
      return respond(403, "ليس لديك صلاحية على هذا المسجد");
    }

    // Rate limit: لا أكثر من 10 حسابات/ساعة
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const { data: recentCreds } = await supabaseAdmin
      .from("supervisor_credentials")
      .select("id")
      .eq("mosque_id", mosqueId)
      .gte("created_at", oneHourAgo);

    if (recentCreds && recentCreds.length >= 10) {
      return respond(429, "تم تجاوز الحد الأقصى (10 حسابات في الساعة)");
    }

    // تحقق أن الإيميل غير مستخدم
    const { data: existingUser } = await supabaseAdmin
      .from("users")
      .select("id, role")
      .eq("email", email)
      .maybeSingle();

    if (existingUser) {
      if (existingUser.role === "parent") {
        return respond(409, "هذا الإيميل مرتبط بحساب ولي أمر. استخدم إيميلاً مختلفاً");
      }
      return respond(409, "حساب بهذا الإيميل موجود بالفعل");
    }

    // إنشاء الحساب
    const { data: authData, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: { role: "supervisor", name },
      });

    if (createError) {
      const msg = createError.message.toLowerCase();
      if (msg.includes("already") || msg.includes("duplicate") || msg.includes("exists")) {
        return respond(409, "هذا الإيميل مسجّل بالفعل");
      }
      if (msg.includes("rate") || msg.includes("limit")) {
        return respond(429, "تم تجاوز الحد المسموح. حاول بعد دقائق");
      }
      return respond(400, createError.message);
    }

    const newAuthId = authData.user?.id;
    if (!newAuthId) {
      return respond(500, "لم يُنشأ المستخدم");
    }

    // انتظار الـ trigger مع retry
    let newUserRow = null;
    let retries = 0;
    while (!newUserRow && retries < 5) {
      await new Promise(resolve => setTimeout(resolve, 500));
      const { data } = await supabaseAdmin
        .from("users")
        .select("id")
        .eq("auth_id", newAuthId)
        .maybeSingle();
      newUserRow = data;
      retries++;
    }

    if (!newUserRow) {
      return respond(202, {
        message: "تم إنشاء الحساب لكن التزامن تأخر. يمكن تسجيل الدخول مباشرة",
        auth_id: newAuthId,
        email,
        temp_password: tempPassword,
      });
    }

    // تحديث الاسم والدور في public.users
    await supabaseAdmin
      .from("users")
      .update({ name: name, role: "supervisor" })
      .eq("id", newUserRow.id);

    // إضافة المشرف لأعضاء المسجد
    await supabaseAdmin.from("mosque_members").upsert({
      mosque_id: mosqueId,
      user_id: newUserRow.id,
      role: "supervisor",
    }, { onConflict: "mosque_id,user_id" });

    // حفظ بيانات الدخول (base64)
    // ⚠ ملاحظة: user_id هنا = auth.users.id (متسق مع migration 037)
    const encodedPass = btoa(tempPassword);
    await supabaseAdmin.from("supervisor_credentials").insert({
      user_id: newAuthId,
      mosque_id: mosqueId,
      encrypted_password: encodedPass,
    });

    // تسجيل العملية في audit_logs (لو الجدول موجود)
    try {
      await supabaseAdmin.from("audit_logs").insert({
        action: "create_supervisor_account",
        performed_by: callerProfile.id,
        target_user_id: newUserRow.id,
        details: { email, name, mosque_id: mosqueId },
      });
    } catch (_) {
      // audit_logs قد لا يكون موجوداً بعد — نتجاهل الخطأ
    }

    return respond(200, {
      user_id: newUserRow.id,
      auth_id: newAuthId,
      email,
      name,
      temp_password: tempPassword,
    });

  } catch (e) {
    return respond(500, { error: String(e) });
  }
});
