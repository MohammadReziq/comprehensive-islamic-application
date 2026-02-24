import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
    status,
  })
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS, status: 204 })
  }

  try {
    const body = await req.json()
    const { email, userName, subject, message, verificationCode } = body as {
      email?: string
      userName?: string
      subject?: string
      message?: string
      verificationCode?: string
    }

    if (!email?.trim()) {
      return jsonResponse({ error: 'email is required' }, 400)
    }

    if (!RESEND_API_KEY) {
      return jsonResponse({ error: 'RESEND_API_KEY not configured' }, 500)
    }

    const name = (userName ?? '').trim() || 'المستخدم'
    let mailSubject: string
    let mailHtml: string

    if (verificationCode?.trim()) {
      // قالب رمز تفعيل الحساب (تسجيل جديد)
      mailSubject = subject ?? 'رمز تفعيل حسابك — صلاتي حياتي'
      mailHtml = `
        <div style="direction: rtl; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; text-align: right; padding: 24px; border-right: 5px solid #2E7D32; background-color: #f9f9f9;">
          <h2 style="color: #2E7D32;">أهلاً بك يا ${name}</h2>
          <p style="font-size: 16px; color: #333;">استخدم الرمز التالي لتفعيل حسابك في تطبيق صلاتي حياتي:</p>
          <p style="font-size: 28px; font-weight: 700; letter-spacing: 8px; color: #1B5E20; margin: 20px 0;">${verificationCode.trim()}</p>
          <p style="font-size: 14px; color: #666;">الرمز صالح لاستخدام واحد ولمدة محدودة. إن لم تطلب إنشاء حساب، يمكنك تجاهل هذه الرسالة.</p>
          <p style="font-size: 12px; color: #777;">تم إرسال هذه الرسالة عبر تطبيق صلاتي حياتي.</p>
        </div>
      `
    } else {
      // قالب عام (السلوك السابق)
      mailSubject = subject ?? 'تحية من تطبيق قُرب 🌙'
      mailHtml = `
        <div style="direction: rtl; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; text-align: right; padding: 20px; border-right: 5px solid #2E7D32; background-color: #f9f9f9;">
          <h2 style="color: #2E7D32;">أهلاً بك يا ${name}</h2>
          <p style="font-size: 16px; color: #333;">${message ?? ''}</p>
          <br />
          <p style="font-size: 12px; color: #777;">تم إرسال هذه الرسالة عبر نظام تطبيق قُرب الذكي.</p>
        </div>
      `
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'Salati Hayati App salatihayati.com',
        to: [email.trim()],
        subject: mailSubject,
        html: mailHtml,
      }),
    })

    const result = await response.json()
    if (!response.ok) {
      return jsonResponse(result ?? { error: 'Resend API error' }, response.status)
    }
    return jsonResponse(result, 200)
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Bad request' },
      400
    )
  }
})