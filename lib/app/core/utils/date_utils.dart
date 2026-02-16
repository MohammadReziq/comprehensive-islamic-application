import 'package:intl/intl.dart';

/// دوال مساعدة للتواريخ
class AppDateUtils {
  AppDateUtils._();

  /// تنسيق تاريخ (1 محرم 1446)
  static String formatDateArabic(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  /// تنسيق تاريخ مختصر (1/1/2025)
  static String formatDateShort(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }

  /// تنسيق وقت (02:30 م)
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a', 'ar').format(time);
  }

  /// تنسيق تاريخ + وقت
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(dateTime);
  }

  /// هل نفس اليوم؟
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// هل اليوم؟
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// هل أمس؟
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// تنسيق نسبي ("اليوم", "أمس", "قبل 3 أيام")
  static String formatRelative(DateTime date) {
    if (isToday(date)) return 'اليوم';
    if (isYesterday(date)) return 'أمس';

    final diff = DateTime.now().difference(date);
    if (diff.inDays < 7) return 'قبل ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'قبل ${diff.inDays ~/ 7} أسابيع';
    return formatDateShort(date);
  }

  /// أول يوم في الأسبوع (السبت)
  static DateTime startOfWeek(DateTime date) {
    // السبت = يوم 6 في Dart (Monday = 1)
    final daysToSubtract = (date.weekday % 7);
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  /// أول يوم في الشهر
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// آخر يوم في الشهر
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// قائمة أيام الأسبوع الحالي
  static List<DateTime> currentWeekDays() {
    final start = startOfWeek(DateTime.now());
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// اسم اليوم بالعربي
  static String dayNameArabic(DateTime date) {
    return DateFormat('EEEE', 'ar').format(date);
  }

  /// اسم اليوم مختصر
  static String dayNameShort(DateTime date) {
    return DateFormat('E', 'ar').format(date);
  }

  /// اسم الشهر بالعربي
  static String monthNameArabic(DateTime date) {
    return DateFormat('MMMM', 'ar').format(date);
  }
}
