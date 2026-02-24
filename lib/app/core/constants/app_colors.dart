import 'package:flutter/material.dart';

/// ألوان تطبيق صلاتي حياتي
/// تصميم ملائم للأبناء - ألوان مبهجة ودافئة
class AppColors {
  AppColors._();

  // ─── اللون الأساسي (أزرق إسلامي) ───
  static const Color primary = Color(0xFF1A3A5C);
  static const Color primaryLight = Color(0xFF4A90D9);
  static const Color primaryLighter = Color(0xFF87CEEB);
  static const Color primaryDark = Color(0xFF0F2440);
  static const Color primarySurface = Color(0xFFE8F4FD);

  // ─── الألوان الثانوية ───
  static const Color secondary = Color(0xFF2D5F8A);
  static const Color accent = Color(0xFFF1C40F); // ذهبي للنقاط

  // ─── ألوان الحالات ───
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color warning = Color(0xFFE67E22);
  static const Color warningLight = Color(0xFFFEF3E5);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDE8E6);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFE8F4FD);

  // ─── ألوان النقاط والتحفيز ───
  static const Color gold = Color(0xFFF1C40F);
  static const Color goldDark = Color(0xFFD4AC0D);
  static const Color silver = Color(0xFFBDC3C7);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color streak = Color(0xFFFF6B35); // لون النار 🔥

  // ─── ألوان الخلفيات ───
  static const Color background = Color(0xFFF8FAFE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ─── ألوان النصوص ───
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ─── ألوان الحدود ───
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // ─── ألوان الصلوات ───
  static const Color fajr = Color(0xFF1B2838);      // فجر - كحلي غامق
  static const Color dhuhr = Color(0xFFF39C12);      // ظهر - ذهبي
  static const Color asr = Color(0xFFE67E22);        // عصر - برتقالي
  static const Color maghrib = Color(0xFFE74C3C);    // مغرب - أحمر غروب
  static const Color isha = Color(0xFF2C3E50);       // عشاء - كحلي

  // ─── ألوان الشارات ───
  static const Color badgeGold = Color(0xFFFFD700);
  static const Color badgeSilver = Color(0xFFC0C0C0);
  static const Color badgeBronze = Color(0xFFCD7F32);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
