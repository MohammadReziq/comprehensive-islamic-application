# إعداد دومين Resend — salatihayati.com

لتستطيع إرسال الإيميلات من بريد مثل `noreply@salatihayati.com` (بدل الإيميل الافتراضي من Resend)، تحتاج إضافة الدومين والتحقق منه في Resend ثم إضافة سجلات DNS.

---

## الخطوة 1: إضافة الدومين في Resend

1. ادخل على **[Resend Dashboard](https://resend.com/domains)**.
2. اضغط **Add Domain**.
3. اكتب الدومين:
   - **للجذر:** `salatihayati.com`
   - **أو نطاق فرعي (مفضل):** `mail.salatihayati.com` أو `send.salatihayati.com`
4. احفظ. Resend راح يعطيك سجلات DNS مطلوبة (SPF + DKIM).

---

## الخطوة 2: إضافة سجلات DNS عند مزود الدومين

روح لمزود الدومين (Cloudflare / Namecheap / GoDaddy / غيرهم) → **DNS** أو **DNS Records**.

### أ) سجل SPF (TXT)

| النوع | الاسم (Host) | القيمة (Value) | TTL |
|--------|--------------|----------------|-----|
| TXT | `@` أو `salatihayati.com` | `v=spf1 include:_spf.resend.com ~all` | 3600 |

(لو استخدمت subdomain مثل `mail.salatihayati.com`، الاسم يكون `mail` فقط.)

### ب) سجل DKIM (القيمة من Resend)

Resend يعطيك سجل CNAME أو TXT خاص بالـ DKIM. شكلها تقريباً:

| النوع | الاسم (Host) | القيمة (Value) |
|--------|--------------|----------------|
| CNAME | `resend._domainkey` (أو اللي يظهر في Resend) | القيمة اللي ينسخها لك Resend |

**مهم:** انسخ القيم من صفحة الدومين في Resend كما هي (كل دومين له قيم مختلفة).

---

## الخطوة 3: التحقق في Resend

1. بعد إضافة السجلات، انتظر 5–15 دقيقة (أو حتى 24 ساعة أحياناً).
2. في Resend → **Domains** → اختر دومينك → اضغط **Verify DNS Records**.
3. لو ظهرت الحالة **Verified** → الدومين جاهز للإرسال.

---

## الخطوة 4: استخدام الإيميل في التطبيق

بعد التحقق، استخدم عنوان إيميل من نفس الدومين، مثلاً:

- `noreply@salatihayati.com`
- أو `noreply@mail.salatihayati.com` لو سجّلت subdomain

في Edge Function `send-emails` يجب أن يكون الحقل `from` بهذا الشكل:

```ts
from: 'صلاتي حياتي <noreply@salatihayati.com>'
```

(أو من الـ subdomain إذا استخدمته.)

---

## ملخص

| الخطوة | أين | ماذا |
|--------|-----|------|
| 1 | Resend → Domains → Add Domain | أضف `salatihayati.com` أو `mail.salatihayati.com` |
| 2 | مزود الدومين → DNS | أضف SPF (TXT) و DKIM (القيمة من Resend) |
| 3 | Resend → Verify DNS Records | تحقق حتى تصبح الحالة Verified |
| 4 | كود send-emails | غيّر `from` إلى `noreply@دومينك` |

لو الدومين ما تحقق، راجع: [Domain not verifying?](https://resend.com/knowledge-base/what-if-my-domain-is-not-verifying)
