// Edge Function: إرسال رمز تفعيل البريد بعد التسجيل
// يُستدعى من التطبيق بعد signUp — يولد رمز 6 خانات، يحفظه في الجدول، ويرسل إيميل عبر send-emails

import { serve } from "std/server";
import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function random6Digit(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

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
    const userName = (body?.userName ?? "").trim();

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabaseUser = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user?.email) {
      return new Response(
        JSON.stringify({ error: "جلسة غير صالحة أو البريد غير متوفر" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const email = user.email;
    const displayName = userName || (user.user_metadata?.name as string) || "المستخدم";
    const code = random6Digit();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString(); // 15 دقيقة

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
    const { error: insertError } = await supabaseAdmin
      .from("email_verification_codes")
      .insert({ email, code, expires_at: expiresAt });

    if (insertError) {
      return new Response(
        JSON.stringify({ error: "فشل حفظ الرمز: " + insertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const functionsUrl = `${supabaseUrl}/functions/v1/send-emails`;
    const res = await fetch(functionsUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        email,
        userName: displayName,
        verificationCode: code,
      }),
    });

    const resData = await res.json().catch(() => ({}));
    if (!res.ok) {
      return new Response(
        JSON.stringify(resData?.error ? { error: resData.error } : { error: "فشل إرسال الإيميل" }),
        { status: res.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ ok: true, message: "تم إرسال الرمز إلى بريدك" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
