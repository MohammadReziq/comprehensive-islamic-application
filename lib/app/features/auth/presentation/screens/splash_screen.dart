import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_responsive.dart';

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
    final random = Random();
    _randomQuote =
        AppStrings.prayerQuotes[random.nextInt(AppStrings.prayerQuotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive(context);

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

                // أيقونة المسجد
                Container(
                      width: r.avatarHero,
                      height: r.avatarHero,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '🕌',
                          style: TextStyle(fontSize: r.isShortPhone ? 40 : 52),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.elasticOut,
                      duration: 1000.ms,
                    ),

                SizedBox(height: r.vlg),

                Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: r.textHero,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                        letterSpacing: 1.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                SizedBox(height: r.vxs),

                Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontSize: r.textMD,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

                const Spacer(flex: 2),

                // آية / حديث
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.xl),
                  child: Container(
                    padding: EdgeInsets.all(r.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(r.radiusLG),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      _randomQuote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: r.isShortPhone ? r.textXS : r.textSM,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.8,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms, duration: 800.ms),

                const Spacer(),

                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ).animate().fadeIn(delay: 1200.ms),

                SizedBox(height: r.vlg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
