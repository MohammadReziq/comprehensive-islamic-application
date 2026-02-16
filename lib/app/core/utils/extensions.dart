import 'package:flutter/material.dart';

/// Extensions مفيدة على أنواع Dart الأساسية

// ─── String Extensions ───

extension StringExtension on String {
  /// أول حرف كبير
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// هل النص فارغ أو مسافات فقط؟
  bool get isBlank => trim().isEmpty;

  /// هل النص ليس فارغاً؟
  bool get isNotBlank => !isBlank;
}

// ─── DateTime Extensions ───

extension DateTimeExtension on DateTime {
  /// تاريخ فقط (بدون وقت)
  DateTime get dateOnly => DateTime(year, month, day);

  /// هل نفس اليوم؟
  bool isSameDayAs(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// هل اليوم؟
  bool get isToday => isSameDayAs(DateTime.now());

  /// هل أمس؟
  bool get isYesterday =>
      isSameDayAs(DateTime.now().subtract(const Duration(days: 1)));
}

// ─── BuildContext Extensions ───

extension ContextExtension on BuildContext {
  /// حجم الشاشة
  Size get screenSize => MediaQuery.sizeOf(this);

  /// عرض الشاشة
  double get screenWidth => screenSize.width;

  /// ارتفاع الشاشة
  double get screenHeight => screenSize.height;

  /// الثيم الحالي
  ThemeData get theme => Theme.of(this);

  /// ألوان الثيم
  ColorScheme get colors => theme.colorScheme;

  /// نصوص الثيم
  TextTheme get textTheme => theme.textTheme;

  /// هل الشاشة صغيرة؟
  bool get isSmallScreen => screenWidth < 360;

  /// عرض SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Duration Extensions ───

extension DurationExtension on Duration {
  /// تنسيق كـ "1:30:00" أو "45:00"
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// تنسيق بالعربي "ساعة و 30 دقيقة"
  String get formattedArabic {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }
    if (hours > 0) {
      return '$hours ساعة';
    }
    return '$minutes دقيقة';
  }
}

// ─── Num Extensions ───

extension NumExtension on num {
  /// تحويل لنسبة مئوية (مع %)
  String get asPercent => '${(this * 100).toStringAsFixed(0)}%';

  /// تقييد القيمة
  num clampTo(num min, num max) => this < min ? min : (this > max ? max : this);
}
