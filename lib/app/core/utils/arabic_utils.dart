/// [I6] أدوات تطبيع النصوص العربية
/// يُستخدم في البحث بالاسم — تسجيل الحضور والبحث العام
class ArabicUtils {
  ArabicUtils._();

  /// تطبيع النص العربي: يُزيل التشكيل، يُوحّد الهمزات، يُوحّد التاء والياء
  static String normalize(String input) {
    var text = input.trim();

    // إزالة التشكيل (حركات + تنوين + شدة + سكون)
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // توحيد الألفات: آ أ إ → ا
    text = text.replaceAll(RegExp(r'[آأإٱ]'), 'ا');

    // توحيد التاء المربوطة: ة → ه
    text = text.replaceAll('ة', 'ه');

    // توحيد الياء: ى → ي
    text = text.replaceAll('ى', 'ي');

    // إزالة المسافات الزائدة
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.toLowerCase();
  }

  /// تحقق ما إذا كان [text] يحتوي على [query] بعد التطبيع
  static bool containsNormalized(String text, String query) {
    return normalize(text).contains(normalize(query));
  }

  /// مقارنة متساوية بعد التطبيع
  static bool equalsNormalized(String a, String b) {
    return normalize(a) == normalize(b);
  }

  /// تطبيع المسافات
  static String normalizeSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// بحث ذكي: يجمع بين normalize + normalizeSpaces
  static bool smartContains(String text, String query) {
    final normalizedText = normalizeSpaces(normalize(text));
    final normalizedQuery = normalizeSpaces(normalize(query));
    return normalizedText.contains(normalizedQuery);
  }

  /// بحث بالكلمات: كل كلمة في query يجب أن تتطابق
  /// smartSearch("عبد الرحمن أحمد", "احمد عبد") → true
  static bool smartSearch(String text, String query) {
    final normalizedText = normalizeSpaces(normalize(text));
    final words = normalizeSpaces(normalize(query)).split(' ');
    return words.every((word) => normalizedText.contains(word));
  }
}
