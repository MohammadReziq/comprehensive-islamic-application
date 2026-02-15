/// مسارات الأصول (صور، أيقونات، أنيميشن)
class AppAssets {
  AppAssets._();

  // ─── مسارات المجلدات ───
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _lottie = 'assets/lottie';

  // ─── صور ───
  static const String logo = '$_images/logo.png';
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String mosquePlaceholder = '$_images/mosque_placeholder.png';
  static const String childPlaceholder = '$_images/child_placeholder.png';
  static const String emptyState = '$_images/empty_state.png';
  static const String noInternet = '$_images/no_internet.png';

  // ─── أنيميشن Lottie ───
  static const String lottieSplash = '$_lottie/splash.json';
  static const String lottieSuccess = '$_lottie/success.json';
  static const String lottieLoading = '$_lottie/loading.json';
  static const String lottiePrayer = '$_lottie/prayer.json';
  static const String lottieCelebration = '$_lottie/celebration.json';
  static const String lottieBadge = '$_lottie/badge.json';
  static const String lottieEmpty = '$_lottie/empty.json';
  static const String lottieError = '$_lottie/error.json';
  static const String lottieMosque = '$_lottie/mosque.json';

  // ─── أيقونات SVG ───
  static const String iconMosque = '$_icons/mosque.svg';
  static const String iconPrayer = '$_icons/prayer.svg';
  static const String iconQR = '$_icons/qr_code.svg';
  static const String iconBadge = '$_icons/badge.svg';
  static const String iconTrophy = '$_icons/trophy.svg';
  static const String iconStreak = '$_icons/streak.svg';
}
