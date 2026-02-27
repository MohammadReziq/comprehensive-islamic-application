// Edge Function: إنشاء حساب الابن (الخطوات الست الإجبارية)
// 1. الطلب: Flutter يرسل child_id, email, password
// 2. التحقق: JWT ولي أمر + الطفل يخصه
// 3. الإنشاء: مفتاح الماستر ينشئ المستخدم في Auth
// 4. الأتمتة: Trigger handle_new_user ينشئ صفاً في users
// 5. الربط: تحديث children.login_user_id
// 6. النتيجة: إرجاع email و password

import { serve } from "std/server";
import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1) الطلب: قراءة الجسم والـ JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "مطلوب تسجيل دخول (Authorization header)" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { child_id: childId, email, password } = body as {
      child_id?: string;
      email?: string;
      password?: string;
    };

    if (!childId || !email || !password) {
      return new Response(
        JSON.stringify({ error: "مطلوب: child_id, email, password" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")!;

    // عميل بجلسة ولي الأمر (للتحقق)
    const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // 2) التحقق: هل هذا الشخص ولي أمر؟ وهل الطفل يخصه؟
    console.log("Auth Header present:", !!authHeader);
    const token = authHeader.replace("Bearer ", "");
    
    console.log("Fetching user from Supabase Auth...");
    const {
      data: { user: parentUser },
      error: userError,
    } = await supabaseUser.auth.getUser(token);

    if (userError || !parentUser) {
      console.error("Auth Error Details:", userError);
      return new Response(
        JSON.stringify({ 
          error: "جلسة غير صالحة أو JWT غير معروف", 
          details: userError?.message,
          suggestion: "جرب تسجيل الخروج والدخول مرة أخرى"
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: parentProfile } = await supabaseUser
      .from("users")
      .select("id")
      .eq("auth_id", parentUser.id)
      .single();

    if (!parentProfile?.id) {
      return new Response(
        JSON.stringify({ error: "ملف ولي الأمر غير موجود" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: childRow, error: childError } = await supabaseUser
      .from("children")
      .select("id, parent_id, name")
      .eq("id", childId)
      .single();

    if (childError || !childRow || childRow.parent_id !== parentProfile.id) {
      return new Response(
        JSON.stringify({ error: "الطفل غير موجود أو لا يخصك" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3) الإنشاء: عميل service_role لإنشاء المستخدم في Auth
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const { data: authData, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { role: "child", name: childRow.name ?? "الابن" },
      });

    if (createError) {
      return new Response(
        JSON.stringify({ error: createError.message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const newAuthId = authData.user?.id;
    if (!newAuthId) {
      return new Response(
        JSON.stringify({ error: "لم يُنشأ المستخدم" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4) الأتمتة: Trigger handle_new_user أنشأ صفاً في public.users
    // 5) الربط: جلب users.id للمستخدم الجديد ثم تحديث children
    const { data: newUserRow, error: userRowError } = await supabaseAdmin
      .from("users")
      .select("id")
      .eq("auth_id", newAuthId)
      .single();

    if (userRowError || !newUserRow) {
      return new Response(
        JSON.stringify({
          error: "تم إنشاء الحساب لكن الربط فشل. راجع الجدول users.",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { error: updateError } = await supabaseAdmin
      .from("children")
      .update({ login_user_id: newUserRow.id })
      .eq("id", childId);

    if (updateError) {
      return new Response(
        JSON.stringify({ error: "فشل ربط الحساب بالطفل: " + updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6) النتيجة — password لا يُرجَع أبداً للعميل (يبقى في Supabase Auth فقط)
    return new Response(
      JSON.stringify({ email }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
