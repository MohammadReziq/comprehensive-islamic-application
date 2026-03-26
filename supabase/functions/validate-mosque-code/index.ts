// Edge Function: التحقق من كود المسجد وربط الطفل
// 1. حماية Brute Force: 5 محاولات/10 دقائق
// 2. التحقق من صحة الكود (invite_code)
// 3. ربط الطفل بالمسجد مع local_number تلقائي

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

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")!;

    // عميل المستخدم للتحقق من الجلسة
    const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser(token);
    if (authError || !user) return respond(401, "جلسة غير صالحة");

    const body = await req.json();
    const { code, child_id } = body as { code?: string; child_id?: string };

    if (!code || !child_id) {
      return respond(400, "مطلوب: code, child_id");
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    // 1. تحقق Brute Force — آخر 10 دقائق
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const { data: recentAttempts } = await supabaseAdmin
      .from("mosque_code_attempts")
      .select("id")
      .eq("user_id", user.id)
      .gte("attempted_at", tenMinutesAgo);

    if (recentAttempts && recentAttempts.length >= 5) {
      return respond(429, "محاولات كثيرة. انتظر 10 دقائق ثم حاول مجدداً");
    }

    // 2. سجّل المحاولة
    await supabaseAdmin.from("mosque_code_attempts").insert({
      ip_hash: user.id, // نستخدم user_id كبديل عن IP (أكثر موثوقية)
      user_id: user.id,
      was_correct: false,
    });

    // 3. ابحث عن المسجد
    const { data: mosque } = await supabaseAdmin
      .from("mosques")
      .select("id, name, status")
      .eq("invite_code", code.toUpperCase().trim())
      .maybeSingle();

    if (!mosque) {
      return respond(404, "كود المسجد غير صحيح. تأكد من الكود وحاول مجدداً");
    }

    if (mosque.status !== "approved") {
      return respond(403, "هذا المسجد في انتظار الموافقة");
    }

    // 4. تحقق أن الطفل غير مربوط بهذا المسجد
    const { data: existing } = await supabaseAdmin
      .from("mosque_children")
      .select("id")
      .eq("child_id", child_id)
      .eq("mosque_id", mosque.id)
      .maybeSingle();

    if (existing) {
      return respond(409, "هذا الطفل مرتبط بهذا المسجد بالفعل");
    }

    // 5. احسب local_number الجديد
    const { data: maxRow } = await supabaseAdmin
      .from("mosque_children")
      .select("local_number")
      .eq("mosque_id", mosque.id)
      .order("local_number", { ascending: false })
      .limit(1)
      .maybeSingle();

    const nextNumber = (maxRow?.local_number ?? 0) + 1;

    // 6. اربط الطفل بالمسجد
    await supabaseAdmin.from("mosque_children").insert({
      mosque_id: mosque.id,
      child_id: child_id,
      type: "primary",
      local_number: nextNumber,
    });

    return respond(200, {
      mosque_id: mosque.id,
      mosque_name: mosque.name,
      local_number: nextNumber,
    });

  } catch (e) {
    return respond(500, { error: String(e) });
  }
});
