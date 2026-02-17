import 'package:supabase_flutter/supabase_flutter.dart';

/// ─── Supabase Configuration ───
class SupabaseConfig {
  static const String url = 'https://nyiejilwpwhmednjqcho.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55aWVqaWx3cHdobWVkbmpxY2hvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNTQ2MTMsImV4cCI6MjA4NjczMDYxM30.6f76zarwrPoWX_21AxMOl_iglsUsa4a35Zbfa7Vn24s';

  /// رابط إعادة التوجيه بعد OAuth (للموبايل — يفتح التطبيق)
  static const String authRedirectScheme = 'salatihayati';
  static String get authRedirectUrl => '$authRedirectScheme://login-callback';

  /// رابط إعادة التوجيه بعد نقر "إعادة تعيين كلمة المرور" في البريد.
  static String get passwordResetRedirectUrl => authRedirectUrl;

  /// Web Client ID من Google Cloud Console (نوع "Web application").
  /// إذا وُضع هنا: تسجيل الدخول بـ Google يظهر داخل التطبيق (قائمة الحسابات) بدون فتح المتصفح.
  /// اتركه فارغاً لاستخدام المتصفح (الطريقة القديمة).
  static const String googleWebClientId =
      '629148760855-8q50vsk38gqd4jks2rg8nalj7g9e4bbg.apps.googleusercontent.com';

  /// iOS Client ID من Google (اختياري، لـ iOS فقط). إن تركت فارغاً يُستخدم googleWebClientId.
  static const String googleIosClientId = '';
}

/// Helper للوصول السريع لـ Supabase client
SupabaseClient get supabase => Supabase.instance.client;
