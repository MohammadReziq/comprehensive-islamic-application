import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_storage_keys.dart';

/// شاشة تظهر للإمام عند أول تسجيل دخول
/// تشرح الخطوات المطلوبة: إضافة مشرف + إطلاق مسابقة
class ImamOnboardingScreen extends StatelessWidget {
  final String mosqueName;
  final VoidCallback onAddSupervisor;
  final VoidCallback onCreateCompetition;
  final VoidCallback onSkip;

  const ImamOnboardingScreen({
    super.key,
    required this.mosqueName,
    required this.onAddSupervisor,
    required this.onCreateCompetition,
    required this.onSkip,
  });

  static const _storageKey = 'imam_onboarding_shown';

  /// هل هذه أول مرة يدخل فيها الإمام؟
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_storageKey) ?? false);
  }

  /// حفظ أنه تم العرض
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

                // أيقونة + عنوان
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mosque, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'مرحباً بك في مسجد',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  mosqueName,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 40),

                // الخطوات
                _StepCard(
                  number: '1',
                  title: 'أضف مشرفاً',
                  subtitle: 'المشرف يسجّل حضور الأطفال في المسجد',
                  icon: Icons.supervisor_account,
                  actionLabel: 'إضافة الآن',
                  onAction: () async {
                    await markAsShown();
                    onAddSupervisor();
                  },
                ),
                const SizedBox(height: 12),
                _StepCard(
                  number: '2',
                  title: 'أطلق مسابقة',
                  subtitle: 'حفّز الأطفال على المحافظة على صلاة الجماعة',
                  icon: Icons.emoji_events,
                  actionLabel: 'إطلاق الآن',
                  onAction: () async {
                    await markAsShown();
                    onCreateCompetition();
                  },
                ),

                const Spacer(),

                // زر لاحقاً
                TextButton(
                  onPressed: () async {
                    await markAsShown();
                    onSkip();
                  },
                  child: Text('لاحقاً',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      )),
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

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;

  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // رقم الخطوة
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(number,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    )),
              ),
            ),
            const SizedBox(width: 12),
            // النص
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
            // زر الفعل
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
