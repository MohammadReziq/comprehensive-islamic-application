import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_storage_keys.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/child_repository.dart';

/// شاشة تعريفية لولي الأمر بعد أول تسجيل دخول
/// 3 صفحات: ترحيب → إضافة طفل → كود المسجد
class ParentOnboardingScreen extends StatefulWidget {
  const ParentOnboardingScreen({super.key});

  @override
  State<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
  final _pageController = PageController();
  final _formKey2 = GlobalKey<FormState>();
  int _currentPage = 0;
  bool _loading = false;

  final _childNameCtrl = TextEditingController();
  final _childAgeCtrl = TextEditingController();
  final _mosqueCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _childNameCtrl.dispose();
    _childAgeCtrl.dispose();
    _mosqueCodeCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    // validate page 2 (add child) if user filled something
    if (_currentPage == 1) {
      final name = _childNameCtrl.text.trim();
      final ageStr = _childAgeCtrl.text.trim();
      // Only validate if user started typing something
      if (name.isNotEmpty || ageStr.isNotEmpty) {
        if (!_formKey2.currentState!.validate()) return;
      }
    }
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // 1. حفظ علامة "شاف الـ onboarding"
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppStorageKeys.parentOnboardingSeen, true);

      // 2. حفظ بيانات الطفل إن وُجدت (اختياري — الـ onboarding لا يتوقف إن فشل)
      final name = _childNameCtrl.text.trim();
      final ageStr = _childAgeCtrl.text.trim();
      final code = _mosqueCodeCtrl.text.trim();

      if (name.isNotEmpty && ageStr.isNotEmpty) {
        final age = int.tryParse(ageStr);
        if (age != null && age > 0 && age <= 18) {
          try {
            final repo = sl<ChildRepository>();
            final result = await repo.addChild(name: name, age: age);
            if (code.isNotEmpty) {
              try {
                await repo.linkChildToMosque(
                  childId: result.child.id,
                  mosqueCode: code,
                );
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لم نتمكن من ربط الطفل بالمسجد. يمكنك المحاولة لاحقاً من الإعدادات.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لم نتمكن من إضافة الطفل. يمكنك إضافته لاحقاً من الإعدادات.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }

      if (mounted) context.go('/home');
    } catch (e) {
      // Fallback: even if something unexpected fails, mark as seen and navigate
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppStorageKeys.parentOnboardingSeen, true);
      } catch (_) {}
      if (mounted) context.go('/home');
    }
  }

  Future<void> _skip() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppStorageKeys.parentOnboardingSeen, true);
    } catch (_) {}
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) _prevPage();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2A5C), Color(0xFF2D5AA0), Color(0xFF4A8DD6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ─── مؤشر التقدم + زر رجوع ───
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        // زر رجوع
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _currentPage > 0 ? 1.0 : 0.0,
                          child: GestureDetector(
                            onTap: _currentPage > 0 ? _prevPage : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // شريط التقدم
                        ...List.generate(3, (i) {
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i <= _currentPage
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // ─── الصفحات ───
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: [
                        _buildWelcomePage(),
                        _buildAddChildPage(),
                        _buildMosqueCodePage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══ الصفحة 1: ترحيب ═══
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Colors.white,
              size: 40,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 500.ms),
          const SizedBox(height: 24),
          const Text(
            'مرحباً بك في\nصلاتي حياتي! 🌙',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut),
          const SizedBox(height: 14),
          Text(
            'تطبيق يساعدك على متابعة صلاة أطفالك وتحفيزهم من خلال نظام النقاط والمسابقات.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.6,
            ),
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 500.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut),
          const SizedBox(height: 24),
          _InfoCard(
            icon: Icons.child_care_rounded,
            text: 'أضف أطفالك وتابع صلاتهم يومياً',
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideX(begin: 0.1, curve: Curves.easeOut),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.emoji_events_rounded,
            text: 'شارك في المسابقات وحفّز أطفالك',
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideX(begin: 0.1, curve: Curves.easeOut),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.notifications_active_rounded,
            text: 'تلقَّ ملاحظات من مشرف المسجد',
          )
              .animate()
              .fadeIn(delay: 700.ms, duration: 400.ms)
              .slideX(begin: 0.1, curve: Curves.easeOut),
          const Spacer(),
          _buildNextButton('التالي', _nextPage)
              .animate()
              .fadeIn(delay: 800.ms, duration: 400.ms)
              .slideY(begin: 0.2),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══ الصفحة 2: إضافة طفل ═══
  Widget _buildAddChildPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'أضف طفلك الأول 👶',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك إضافة المزيد لاحقاً من الإعدادات. أو تخطي هذه الخطوة.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 28),
            _buildInputField(
              controller: _childNameCtrl,
              label: 'اسم الطفل',
              icon: Icons.person_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null; // optional
                if (value.trim().length < 2) return 'الاسم لازم يكون حرفين على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _childAgeCtrl,
              label: 'العمر',
              icon: Icons.cake_rounded,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null; // optional
                final age = int.tryParse(value.trim());
                if (age == null) return 'أدخل رقماً صحيحاً';
                if (age < 3 || age > 18) return 'العمر لازم يكون بين 3 و 18';
                return null;
              },
            ),
            const Spacer(),
            _buildNextButton('التالي', _nextPage),
            const SizedBox(height: 8),
            _buildSkipButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ═══ الصفحة 3: كود المسجد ═══
  Widget _buildMosqueCodePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'أدخل كود المسجد 🕌',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اطلب الكود من الإمام أو المشرف لربط طفلك بالمسجد. يمكنك تخطي هذه الخطوة وإدخاله لاحقاً.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 28),
          _buildInputField(
            controller: _mosqueCodeCtrl,
            label: 'كود المسجد',
            icon: Icons.tag_rounded,
            textDirection: TextDirection.ltr,
          ),
          const Spacer(),
          _buildNextButton(
            'ابدأ استخدام التطبيق',
            _loading ? null : _finish,
            loading: _loading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── مكوّنات مساعدة ───

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextDirection textDirection = TextDirection.rtl,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: textDirection,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        errorStyle: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildNextButton(
    String label,
    VoidCallback? onTap, {
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A2A5C),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1A2A5C),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _loading ? null : _skip,
        child: Text(
          'تخطي',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
