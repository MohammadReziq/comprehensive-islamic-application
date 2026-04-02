import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_storage_keys.dart';

/// شاشة تعريفية للمشرف بعد أول تسجيل دخول
class SupervisorOnboardingScreen extends StatelessWidget {
  const SupervisorOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A3A2E), Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // ─── أيقونة ───
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8), duration: 500.ms),
                  const SizedBox(height: 24),

                  // ─── العنوان ───
                  const Text(
                    'مرحباً بك كمشرف! 🌟',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 12),
                  Text(
                    'أنت مشرف في المسجد. مهمتك الأساسية هي تسجيل حضور الأطفال ومتابعة صلاتهم.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 36),

                  // ─── المهام ───
                  _TaskItem(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'تسجيل الحضور',
                    description:
                        'امسح QR الطفل أو ابحث عنه بالاسم لتسجيل حضوره',
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms)
                      .slideX(begin: 0.1, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _TaskItem(
                    icon: Icons.note_alt_outlined,
                    title: 'الملاحظات',
                    description:
                        'أرسل ملاحظات لأولياء الأمور عن سلوك أطفالهم',
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms)
                      .slideX(begin: 0.1, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _TaskItem(
                    icon: Icons.edit_note_rounded,
                    title: 'طلبات التصحيح',
                    description: 'راجع ووافق على طلبات تصحيح الحضور',
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 400.ms)
                      .slideX(begin: 0.1, curve: Curves.easeOut),

                  const Spacer(),

                  // ─── زر البدء ───
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await _markSeen();
                        if (context.mounted) context.go('/supervisor/dashboard');
                      },
                      child: const Text(
                        'ابدأ التحضير',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 400.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStorageKeys.supervisorOnboardingSeen, true);
  }
}

class _TaskItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TaskItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
