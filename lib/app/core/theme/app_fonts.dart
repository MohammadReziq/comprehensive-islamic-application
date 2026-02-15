import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// خطوط التطبيق - خط Cairo العربي
class AppFonts {
  AppFonts._();

  /// الخط الأساسي
  static String get fontFamily => GoogleFonts.cairo().fontFamily!;

  /// TextTheme كامل بالخط العربي
  static TextTheme get textTheme => GoogleFonts.cairoTextTheme();

  // ─── أحجام محددة ───

  /// عنوان كبير جداً (أرقام النقاط، العد التنازلي)
  static TextStyle displayLarge({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 36,
        fontWeight: weight ?? FontWeight.w700,
        color: color,
        height: 1.2,
      );

  /// عنوان كبير
  static TextStyle displayMedium({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: weight ?? FontWeight.w700,
        color: color,
        height: 1.3,
      );

  /// عنوان
  static TextStyle headlineLarge({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: weight ?? FontWeight.w700,
        color: color,
        height: 1.3,
      );

  /// عنوان متوسط
  static TextStyle headlineMedium({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: weight ?? FontWeight.w600,
        color: color,
        height: 1.4,
      );

  /// عنوان صغير
  static TextStyle headlineSmall({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: weight ?? FontWeight.w600,
        color: color,
        height: 1.4,
      );

  /// عنوان فرعي
  static TextStyle titleLarge({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: weight ?? FontWeight.w600,
        color: color,
        height: 1.5,
      );

  /// عنوان فرعي متوسط
  static TextStyle titleMedium({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w600,
        color: color,
        height: 1.5,
      );

  /// نص أساسي
  static TextStyle bodyLarge({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        height: 1.6,
      );

  /// نص أساسي متوسط
  static TextStyle bodyMedium({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        height: 1.6,
      );

  /// نص صغير
  static TextStyle bodySmall({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        height: 1.5,
      );

  /// تسمية (أزرار، tabs)
  static TextStyle labelLarge({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w600,
        color: color,
        height: 1.4,
        letterSpacing: 0.5,
      );

  /// تسمية صغيرة
  static TextStyle labelSmall({Color? color, FontWeight? weight}) =>
      GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: weight ?? FontWeight.w500,
        color: color,
        height: 1.4,
      );

  /// نص التلميح
  static TextStyle caption({Color? color}) => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? Colors.grey,
        height: 1.4,
      );
}
