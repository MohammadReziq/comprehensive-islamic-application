import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة الترحيب الأولى — تظهر مرة واحدة فقط لـ parent جديد بدون أبناء
class FirstEntryScreen extends StatefulWidget {
  const FirstEntryScreen({super.key});

  @override
  State<FirstEntryScreen> createState() => _FirstEntryScreenState();
}

class _FirstEntryScreenState extends State<FirstEntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_entry_shown', true);
  }

  Future<void> _onStart() async {
    await _markSeen();
    if (mounted) context.push('/parent/children/add');
  }

  Future<void> _onLater() async {
    await _markSeen();
    if (mounted) context.go('/parent/home');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      // أيقونة التطبيق
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🌙',
                            style: TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'مرحباً بك في\nصلاتي حياتي!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ابدأ متابعة صلاة أبنائك في 3 خطوات بسيطة',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // الخطوات
                      _Step(
                        number: '١',
                        title: 'أضف ابنك الأول',
                        subtitle: 'باسمه وعمره فقط — بدون تعقيدات',
                      ),
                      const SizedBox(height: 20),
                      _Step(
                        number: '٢',
                        title: 'احصل على كود المسجد',
                        subtitle: 'يُعطيك إياه الإمام أو المشرف',
                      ),
                      const SizedBox(height: 20),
                      _Step(
                        number: '٣',
                        title: 'اربط ابنك بمسجده',
                        subtitle: 'يبدأ تسجيل الحضور تلقائياً!',
                      ),
                      const Spacer(flex: 2),
                      // زر البدء
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0D2137),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ابدأ الآن — إضافة الابن الأول',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_back_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // زر لاحقاً
                      Center(
                        child: TextButton(
                          onPressed: _onLater,
                          child: Text(
                            'لاحقاً',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
