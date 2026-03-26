// Edge Function: إنشاء حساب إمام (السوبر أدمن فقط)
// 1. التحقق: JWT سوبر أدمن
// 2. الإنشاء: Admin API ينشئ المستخدم مع role='imam'
// 3. الأتمتة: Trigger handle_new_user ينشئ صفاً في users
// 4. النتيجة: إرجاع user_id + email + temp_password

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
    // 1) قراءة الـ JWT والجسم
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return respond(401, "مطلوب تسجيل دخول (Authorization header)");

    const body = await req.json();
    const { name, email, temp_password: tempPassword } = body as {
      name?: string;
      email?: string;
      temp_password?: string;
    };

    if (!name || !email || !tempPassword) {
      return respond(400, "مطلوب: name, email, temp_password");
    }

    // التحقق من صيغة الإيميل
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return respond(400, "صيغة الإيميل غير صحيحة");
    }

    // التحقق من طول كلمة السر
    if (tempPassword.length < 6) {
      return respond(400, "كلمة السر يجب أن تكون 6 أحرف على الأقل");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")!;

    // عميل بجلسة المستدعي (للتحقق من الدور)
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

    // 2) التحقق أن المستدعي super_admin
    const { data: callerProfile, error: profileError } = await supabaseUser
      .from("users")
      .select("id, role")
      .eq("auth_id", callerAuth.id)
      .single();

    if (profileError || !callerProfile) {
      return respond(403, "ملف المستخدم غير موجود");
    }

    if (callerProfile.role !== "super_admin") {
      return respond(403, "ليس لديك صلاحية لإنشاء حساب إمام");
    }

    // 3) إنشاء حساب الإمام عبر Admin API
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const { data: authData, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: { role: "imam", name },
      });

    if (createError) {
      const msg = createError.message.toLowerCase();
      if (msg.includes("already") || msg.includes("duplicate") || msg.includes("exists")) {
        return respond(409, "هذا الإيميل مسجّل بالفعل");
      }
      if (msg.includes("invalid") && msg.includes("email")) {
        return respond(400, "صيغة الإيميل غير صحيحة");
      }
      if (msg.includes("password") && msg.includes("weak")) {
        return respond(400, "كلمة السر ضعيفة — استخدم 6 أحرف على الأقل");
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

    // 4) انتظار Trigger مع retry (الـ trigger قد يتأخر ميلي ثانية)
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

    // 5) تحديث الاسم والدور في public.users (تأكيد بعد الـ trigger)
    await supabaseAdmin
      .from("users")
      .update({ name: name, role: "imam" })
      .eq("id", newUserRow.id);

    // 6) تسجيل العملية في audit_logs (لو الجدول موجود)
    try {
      await supabaseAdmin.from("audit_logs").insert({
        action: "create_imam_account",
        performed_by: callerProfile.id,
        target_user_id: newUserRow.id,
        details: { email, name },
      });
    } catch (_) {
      // audit_logs قد لا يكون موجوداً بعد — نتجاهل الخطأ
    }

    // 7) النتيجة
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
