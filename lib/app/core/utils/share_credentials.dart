import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// مشاركة بيانات حسابات الأئمة والمشرفين عبر واتساب أو النسخ
class ShareCredentials {
  /// رسالة بيانات دخول الإمام
  static String buildImamMessage({
    required String name,
    required String email,
    required String password,
  }) {
    return '''بسم الله الرحمن الرحيم

السلام عليكم ورحمة الله وبركاته
أخي $name، تم إنشاء حسابك في تطبيق "صلاتي حياتي" 🕌

━━━━━━━━━━━━━━━━━━━━
📧 البريد: $email
🔑 كلمة السر: $password
━━━━━━━━━━━━━━━━━━━━

⚠ يُرجى تغيير كلمة السر بعد أول تسجيل دخول.''';
  }

  /// رسالة بيانات دخول المشرف
  static String buildSupervisorMessage({
    required String name,
    required String email,
    required String password,
    required String mosqueName,
  }) {
    return '''بسم الله الرحمن الرحيم

السلام عليكم ورحمة الله وبركاته
أخي $name، تم إنشاء حسابك كمشرف في مسجد "$mosqueName" 🕌
على تطبيق "صلاتي حياتي"

━━━━━━━━━━━━━━━━━━━━
📧 البريد: $email
🔑 كلمة السر: $password
━━━━━━━━━━━━━━━━━━━━

مهمتك: تسجيل حضور الأطفال عبر مسح QR أو البحث.
⚠ يُرجى تغيير كلمة السر بعد أول تسجيل دخول.''';
  }

  /// مشاركة عبر واتساب
  static Future<void> shareViaWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// نسخ للحافظة
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
