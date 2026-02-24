// Edge Function: التحقق من رمز تفعيل البريد (بعد التسجيل)
// يُستدعى من التطبيق عند إدخال المستخدم للرمز — يتحقق من الجدول ثم يُرجع النجاح

import { serve } from "std/server";
import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "مطلوب تسجيل دخول (Authorization)" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json().catch(() => ({}));
    const code = (body?.code ?? "").toString().trim();
    if (!code || code.length !== 6) {
      return new Response(
        JSON.stringify({ error: "الرمز يجب أن يكون 6 أرقام" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabaseUser = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user?.email) {
      return new Response(
        JSON.stringify({ error: "جلسة غير صالحة" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const email = user.email;
    const now = new Date().toISOString();

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
    const { data: rows, error: selectError } = await supabaseAdmin
      .from("email_verification_codes")
      .select("id")
      .eq("email", email)
      .eq("code", code)
      .gt("expires_at", now)
      .order("created_at", { ascending: false })
      .limit(1);

    if (selectError || !rows?.length) {
      return new Response(
        JSON.stringify({ error: "رمز غير صحيح أو منتهي الصلاحية" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    await supabaseAdmin
      .from("email_verification_codes")
      .delete()
      .eq("id", rows[0].id);

    return new Response(
      JSON.stringify({ ok: true, message: "تم التحقق بنجاح" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
