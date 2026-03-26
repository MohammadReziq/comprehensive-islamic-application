import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';

/// شاشة Onboarding لولي الأمر عند أول تسجيل دخول
/// 3 صفحات: ترحيب → إضافة طفل → ربط بمسجد
class ParentOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onAddChild;
  final VoidCallback onLinkMosque;

  const ParentOnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onAddChild,
    required this.onLinkMosque,
  });

  static const _storageKey = 'parent_onboarding_shown';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_storageKey) ?? false);
  }

  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, true);
  }

  @override
  State<ParentOnboardingScreen> createState() =>
      _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // محتوى الصفحات
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _WelcomePage(),
                    _AddChildPage(onAddChild: widget.onAddChild),
                    _LinkMosquePage(onLinkMosque: widget.onLinkMosque),
                  ],
                ),
              ),

              // المؤشرات + الأزرار
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    // النقاط
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primaryDark
                                : AppColors.textHint.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // الأزرار
                    Row(
                      children: [
                        if (_currentPage < 2)
                          TextButton(
                            onPressed: () async {
                              await ParentOnboardingScreen.markAsShown();
                              widget.onComplete();
                            },
                            child: Text('تخطي',
                                style: GoogleFonts.cairo(
                                    color: AppColors.textSecondary)),
                          ),
                        const Spacer(),
                        if (_currentPage < 2)
                          FilledButton(
                            onPressed: _next,
                            child: const Text('التالي'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () async {
                              await ParentOnboardingScreen.markAsShown();
                              widget.onComplete();
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('ابدأ الآن'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// الصفحة 1: ترحيب
// ══════════════════════════════════════════════════════════════
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.family_restroom,
                color: Colors.white, size: 50),
          ),
          const SizedBox(height: 32),
          Text(
            'أهلاً بك في صلاتي حياتي',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'تابع حضور أطفالك لصلاة الجماعة\nوشجّعهم على المحافظة عليها',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// الصفحة 2: إضافة الطفل الأول
// ══════════════════════════════════════════════════════════════
class _AddChildPage extends StatelessWidget {
  final VoidCallback onAddChild;

  const _AddChildPage({required this.onAddChild});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.child_care,
                color: Colors.orange.shade700, size: 50),
          ),
          const SizedBox(height: 32),
          Text(
            'أضف طفلك الأول',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'أدخل اسم طفلك وعمره لتبدأ متابعته',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: onAddChild,
            icon: const Icon(Icons.add),
            label: Text('إضافة طفل',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// الصفحة 3: ربط بمسجد
// ══════════════════════════════════════════════════════════════
class _LinkMosquePage extends StatelessWidget {
  final VoidCallback onLinkMosque;

  const _LinkMosquePage({required this.onLinkMosque});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mosque, color: Colors.green.shade700, size: 50),
          ),
          const SizedBox(height: 32),
          Text(
            'اربط طفلك بمسجد',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'اطلب كود المسجد من الإمام وأدخله\nلربط طفلك بالمسجد وتفعيل المتابعة',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: onLinkMosque,
            icon: const Icon(Icons.qr_code),
            label: Text('إدخال كود المسجد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
