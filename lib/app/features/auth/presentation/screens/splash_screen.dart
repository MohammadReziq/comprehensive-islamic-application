import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';

/// شاشة البداية - Splash Screen
/// تعرض شعار التطبيق + آية عن الصلاة ثم توجّه المستخدم
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final String _randomQuote;

  @override
  void initState() {
    super.initState();
    // اختيار آية/حديث عشوائي
    final random = Random();
    _randomQuote = AppStrings.prayerQuotes[
        random.nextInt(AppStrings.prayerQuotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.secondary,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ─── أيقونة المسجد ───
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🕌',
                      style: TextStyle(fontSize: 56),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 1000.ms),

                const SizedBox(height: AppDimensions.spacingXL),

                // ─── اسم التطبيق ───
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: AppDimensions.spacingSM),

                // ─── الشعار ───
                Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 500.ms),

                const Spacer(flex: 2),

                // ─── آية/حديث ───
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingMD),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      _randomQuote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.8,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 800.ms),

                const Spacer(),

                // ─── مؤشر التحميل ───
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1200.ms),

                const SizedBox(height: AppDimensions.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
