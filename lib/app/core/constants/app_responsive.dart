import 'package:flutter/material.dart';

/// 📁 lib/app/core/constants/app_responsive.dart
///
/// نظام responsive كامل — بدون packages — يعتمد على العرض والطول معاً
///
/// الاستخدام داخل build():
///   final r = AppResponsive(context);
///   padding: EdgeInsets.all(r.md)
///   fontSize: r.textLG
///   height: r.hp(8)   ← 8% من ارتفاع الشاشة
///   width: r.wp(90)   ← 90% من عرض الشاشة
class AppResponsive {
  AppResponsive(BuildContext context) {
    final mq = MediaQuery.of(context);
    screenWidth = mq.size.width;
    screenHeight = mq.size.height;
    topPadding = mq.padding.top;
    bottomPadding = mq.padding.bottom;
    safeHeight = screenHeight - topPadding - bottomPadding;
    pixelRatio = mq.devicePixelRatio;
  }

  late final double screenWidth;
  late final double screenHeight;
  late final double safeHeight;
  late final double topPadding;
  late final double bottomPadding;
  late final double pixelRatio;

  // ─── تصنيف العرض ───
  bool get isPhone => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  // ─── تصنيف الارتفاع ───
  // قصير  : iPhone SE, Galaxy A05 ونحوها        < 700px
  // متوسط : iPhone 14, Galaxy S23               700-850px
  // طويل  : iPhone 14 Pro Max, Galaxy S23 Ultra  > 850px
  bool get isShortPhone => screenHeight < 700;
  bool get isMediumPhone => screenHeight >= 700 && screenHeight < 850;
  bool get isTallPhone => screenHeight >= 850;

  // ══════════════════════════════════════════
  // نسب مئوية — الأساس في الـ Responsive
  // ══════════════════════════════════════════

  /// نسبة من العرض   مثال: wp(90) = 90% من العرض
  double wp(double percent) => screenWidth * percent / 100;

  /// نسبة من الارتفاع الكامل
  double hp(double percent) => screenHeight * percent / 100;

  /// نسبة من الارتفاع الآمن (بدون notch/navbar)
  double shp(double percent) => safeHeight * percent / 100;

  // ══════════════════════════════════════════
  // Padding / Margin الأفقي — يعتمد العرض
  // ══════════════════════════════════════════
  double get xs => _w(4, 6, 8);
  double get sm => _w(8, 12, 14);
  double get md => _w(16, 20, 24);
  double get lg => _w(24, 28, 32);
  double get xl => _w(32, 40, 48);
  double get xxl => _w(48, 56, 64);

  // ══════════════════════════════════════════
  // Spacing الرأسي — يعتمد الارتفاع (مهم جداً)
  // ══════════════════════════════════════════
  double get vxs => _h(4, 5, 6);
  double get vsm => _h(8, 10, 12);
  double get vmd => _h(12, 16, 20);
  double get vlg => _h(20, 24, 28);
  double get vxl => _h(28, 36, 44);
  double get vxxl => _h(40, 52, 64);

  // ══════════════════════════════════════════
  // Border Radius
  // ══════════════════════════════════════════
  double get radiusSM => _w(8, 10, 12);
  double get radiusMD => _w(12, 14, 16);
  double get radiusLG => _w(16, 20, 24);
  double get radiusXL => _w(20, 24, 28);
  double get radiusRound => 100;

  // ══════════════════════════════════════════
  // Font Sizes — يعتمد العرض
  // ══════════════════════════════════════════
  double get textXS => _w(10, 11, 12);
  double get textSM => _w(12, 13, 14);
  double get textMD => _w(14, 15, 16);
  double get textLG => _w(16, 18, 20);
  double get textXL => _w(20, 22, 24);
  double get textXXL => _w(24, 28, 32);
  double get textHero => _w(26, 30, 36);

  // ══════════════════════════════════════════
  // Icon Sizes
  // ══════════════════════════════════════════
  double get iconSM => _w(18, 20, 22);
  double get iconMD => _w(22, 24, 26);
  double get iconLG => _w(28, 32, 36);
  double get iconXL => _w(40, 48, 56);

  // ══════════════════════════════════════════
  // Heights للمكونات — يعتمد الارتفاع
  // ══════════════════════════════════════════
  double get buttonHeight => _h(44, 50, 54);
  double get textFieldHeight => _h(44, 50, 54);
  double get appBarHeight => _h(52, 56, 60);

  // ══════════════════════════════════════════
  // Avatar / QR
  // ══════════════════════════════════════════
  double get avatarSM => _w(36, 40, 44);
  double get avatarMD => _w(48, 54, 60);
  double get avatarLG => _w(72, 80, 88);
  double get avatarHero => _w(80, 96, 110);
  double get qrSize => _w(170, 200, 230);

  // ══════════════════════════════════════════
  // Grid
  // ══════════════════════════════════════════
  int get gridColumns => isPhone ? 3 : (isTablet ? 4 : 5);
  double get gridAspectRatio => isPhone ? 1.05 : (isTablet ? 1.1 : 1.15);

  // ══════════════════════════════════════════
  // SizedBox helpers
  // ══════════════════════════════════════════
  Widget vXS() => SizedBox(height: vxs);
  Widget vSM() => SizedBox(height: vsm);
  Widget vMD() => SizedBox(height: vmd);
  Widget vLG() => SizedBox(height: vlg);
  Widget vXL() => SizedBox(height: vxl);
  Widget vXXL() => SizedBox(height: vxxl);
  Widget hXS() => SizedBox(width: xs);
  Widget hSM() => SizedBox(width: sm);
  Widget hMD() => SizedBox(width: md);
  Widget hLG() => SizedBox(width: lg);

  // ══════════════════════════════════════════
  // Helpers داخلية
  // ══════════════════════════════════════════
  double _w(double phone, double tablet, double desktop) {
    if (isPhone) return phone;
    if (isTablet) return tablet;
    return desktop;
  }

  double _h(double small, double medium, double large) {
    if (isShortPhone) return small;
    if (isMediumPhone) return medium;
    return large;
  }
}

/// Extension سريع على BuildContext — بدون إنشاء instance يدوي
extension ResponsiveContext on BuildContext {
  AppResponsive get r => AppResponsive(this);
  bool get isPhone => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= 600 &&
      MediaQuery.sizeOf(this).width < 900;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 900;
  bool get isShortPhone => MediaQuery.sizeOf(this).height < 700;
}
