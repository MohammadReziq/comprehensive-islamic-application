import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';

/// شاشة تظهر للمشرف عند أول تسجيل دخول
/// تشرح طرق تسجيل الحضور الثلاث: QR / رقم / اسم
class SupervisorOnboardingScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const SupervisorOnboardingScreen({
    super.key,
    required this.onGetStarted,
  });

  static const _storageKey = 'supervisor_onboarding_shown';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_storageKey) ?? false);
  }

  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // أيقونة
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'أهلاً بك يا مشرف 👋',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مهمتك: تسجيل حضور الأطفال لصلاة الجماعة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // الطرق الثلاث
                _MethodCard(
                  icon: Icons.qr_code_scanner,
                  title: 'مسح QR',
                  subtitle: 'امسح كود الطالب من التطبيق — الأسرع',
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(height: 12),
                _MethodCard(
                  icon: Icons.numbers,
                  title: 'الرقم المحلي',
                  subtitle: 'أدخل رقم الطالب في المسجد مباشرة',
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 12),
                _MethodCard(
                  icon: Icons.search,
                  title: 'البحث بالاسم',
                  subtitle: 'ابحث عن الطالب بالاسم من القائمة',
                  color: const Color(0xFFE65100),
                ),

                const Spacer(),

                // زر البدء
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await markAsShown();
                      onGetStarted();
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('ابدأ الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      )),
                  Text(subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
