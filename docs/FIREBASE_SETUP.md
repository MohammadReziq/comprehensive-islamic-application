# إعداد Firebase (مفاتيح محلية فقط)

## لماذا هذا الملف؟

ملف `lib/firebase_options.dart` يحتوي على مفاتيح Firebase/Google API. **لا يجب رفع هذا الملف إلى مستودع عام** حتى لا تُكشف المفاتيح.

## بعد استنساخ المشروع (Clone)

1. ثبّت FlutterFire CLI إن لم يكن مثبتاً:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. ولّد ملف المفاتيح محلياً:
   ```bash
   dart run flutterfire_cli:flutterfire configure
   ```
3. سيُنشأ `lib/firebase_options.dart` بمفاتيح مشروعك ولن يُرفع إلى Git (الملف في `.gitignore`).

## إذا ظهر تنبيه أمني من Google

إذا تسرّب مفتاح سابقاً (مثلاً من commit قديم):

1. ادخل إلى [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. اعثر على المفتاح المتسرّب واختر **Regenerate Key** (أو احذفه وأنشئ مفتاحاً جديداً).
3. نفّذ من المشروع: `dart run flutterfire_cli:flutterfire configure` لملف محلي جديد بمفاتيح محدّثة.
4. (موصى به) فعّل **تقييدات المفتاح** (تطبيقات Android/iOS، أو عناوين IP) من نفس صفحة Credentials.
