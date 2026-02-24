import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_responsive.dart';
import '../../../../core/constants/app_storage_keys.dart';

/// صفحة الـ Onboarding — تظهر مرة واحدة فقط للمستخدم الجديد
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ─── بيانات الصفحات ───
  late final _pages = [
    const _OnboardingPageData(
      lottieAsset: AppAssets.lottieMosque,
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
    ),
    const _OnboardingPageData(
      lottieAsset: AppAssets.lottieDadPrayer,
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
    ),
    _OnboardingPageData(
      lottieAsset: AppAssets.lottieStartUpRocket,
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      lottieDelegates: LottieDelegates(
        values: [
          ValueDelegate.color(
            // الجزء الأول هو المسار داخل الطبقات (Layers) في الملف
            // يمكنك استخدام ['**'] لتغيير كل الألوان، أو تحديد اسم طبقة معينة
            const ['Shape Layer 26', 'Shape 1', 'Stroke 1'],
            value: Colors.red, // اللون الجديد الذي تريده
          ),
          ValueDelegate.color(
            // الجزء الأول هو المسار داخل الطبقات (Layers) في الملف
            // يمكنك استخدام ['**'] لتغيير كل الألوان، أو تحديد اسم طبقة معينة
            const ['Shape Layer 26', 'Shape 1', 'Stroke 1'],
            value: Colors.red, // اللون الجديد الذي تريده
          ),
        ],
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStorageKeys.onboardingSeen, true);
    if (mounted) context.go('/register');
  }

  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStorageKeys.onboardingSeen, true);
    if (mounted) context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
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
              children: [
                // ─── زر تخطي ───
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: r.sm, top: r.vxs),
                    child: AnimatedOpacity(
                      opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _currentPage < _pages.length - 1
                            ? _completeOnboarding
                            : null,
                        child: Text(
                          AppStrings.skip,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: r.textSM,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── PageView ───
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        data: _pages[index],
                        isLastPage: index == _pages.length - 1,
                      );
                    },
                  ),
                ),

                // ─── Dot indicators ───
                Padding(
                  padding: EdgeInsets.only(bottom: r.vmd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.symmetric(horizontal: r.xs / 2),
                        width: _currentPage == i ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: _currentPage == i
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── زر التالي / ابدأ ───
                Padding(
                      padding: EdgeInsets.symmetric(horizontal: r.lg),
                      child: SizedBox(
                        width: double.infinity,
                        height: r.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r.radiusMD),
                            ),
                            elevation: 4,
                            shadowColor: AppColors.accent.withOpacity(0.4),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? AppStrings.getStarted
                                : AppStrings.next,
                            style: TextStyle(
                              fontSize: r.textLG,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideY(begin: 0.3),

                // ─── تملك حساب؟ سجل دخولك ───
                Padding(
                  padding: EdgeInsets.only(top: r.vsm, bottom: r.vmd),
                  child: TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      AppStrings.alreadyHaveAccountQuestion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: r.textSM,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Data class لبيانات كل صفحة
// ══════════════════════════════════════════════════════════════

class _OnboardingPageData {
  final String lottieAsset;
  final String title;
  final String description;
  final LottieDelegates? lottieDelegates;
  const _OnboardingPageData({
    required this.lottieAsset,
    required this.title,
    required this.description,
    this.lottieDelegates,
  });
}

// ══════════════════════════════════════════════════════════════
// Widget لصفحة واحدة من الـ Onboarding
// ══════════════════════════════════════════════════════════════

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isLastPage;

  const _OnboardingPage({required this.data, required this.isLastPage});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // ─── Lottie / Icon ───
          Container(
                height: r.isShortPhone ? r.hp(28) : r.hp(35),
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r.radiusXL),
                ),
                child: Lottie.asset(
                  data.lottieAsset,
                  fit: BoxFit.contain,
                  repeat: true,
                  delegates: data.lottieDelegates,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOut,
                duration: 700.ms,
              ),

          SizedBox(height: r.vxl),

          // ─── العنوان ───
          Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.textXXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                  height: 1.4,
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),

          SizedBox(height: r.vmd),

          // ─── الوصف ───
          Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.textMD,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.7,
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
