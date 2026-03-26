import 'dart:math';

/// توليد كلمات سر مؤقتة للأئمة والمشرفين
///
/// الأحرف المستبعدة: O, 0, I, l, 1 — لتجنب الالتباس عند المشاركة يدوياً
class PasswordGenerator {
  static final Random _random = Random.secure();

  // أحرف واضحة لا تُشبه بعضها
  static const String _chars =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';

  /// للإمام: imam_XXXXXX (11 حرف مجموعاً)
  static String generateImamPassword() => 'imam_${_generate(6)}';

  /// للمشرف: sup_XXXXXX (9 أحرف مجموعاً)
  static String generateSupervisorPassword() => 'sup_${_generate(6)}';

  static String _generate(int length) {
    return List.generate(
      length,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }
}
