import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/competition_model.dart';

// ═══════════════════════════════════════════════════════════════════
/// 📁 lib/app/core/widgets/shared_dashboard_widgets.dart
///
/// مكونات مشتركة بين لوحة الإمام ولوحة المشرف
/// مستخرجة من imam_dashboard_screen.dart + supervisor_dashboard_screen.dart
// ═══════════════════════════════════════════════════════════════════

// ─── Data class for action items ───

class DashboardActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const DashboardActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}

// ─── Prayer Card ───

class DashboardPrayerCard extends StatelessWidget {
  final dynamic nextPrayer;
  const DashboardPrayerCard({super.key, required this.nextPrayer});

  @override
  Widget build(BuildContext context) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    final remaining = nextPrayer?.remaining;
    final remainingMin = remaining?.inMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصلاة القادمة',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$nameAr  $timeFormatted',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (remainingMin != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withOpacity(0.5),
                ),
              ),
              child: Text(
                'بعد ${remainingMin}د',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD54F),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Action Tile ───

class DashboardActionTile extends StatelessWidget {
  final DashboardActionItem item;
  const DashboardActionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.13),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(height: 9),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Info Chip ───

class DashboardHeroInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final Color? accentColor;
  final bool hasBadge;

  const DashboardHeroInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailingIcon,
    this.accentColor,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasBadge
                ? const Color(0xFFFFB74D).withOpacity(0.5)
                : Colors.white.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: accentColor ?? Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentColor ?? Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ───

class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String dashboardLabel;
  final IconData dashboardIcon;

  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.dashboardLabel,
    this.dashboardIcon = Icons.dashboard_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFFB0B8C4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(dashboardIcon),
            label: dashboardLabel,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}

// ─── Absence Alerts ───

class DashboardAbsenceAlerts extends StatelessWidget {
  final List<Map<String, dynamic>> absentStudents;
  const DashboardAbsenceAlerts({super.key, required this.absentStudents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF7043).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFF7043), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تنبيهات الغياب',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    Text(
                      '${absentStudents.length} طالب بدون حضور 3 أيام',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...absentStudents.take(5).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      (s['name'] as String).isNotEmpty
                          ? (s['name'] as String)[0]
                          : '؟',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF7043),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (absentStudents.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'و ${absentStudents.length - 5} طالب آخر...',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Competition Status Banner ───

/// بانر حالة المسابقة — مشترك بين HomeScreen و SupervisorDashboard
class CompetitionStatusBanner extends StatelessWidget {
  const CompetitionStatusBanner({
    super.key,
    required this.status,
    this.competition,
    this.mosqueName,
  });

  final CompetitionStatus status;
  final CompetitionModel? competition;
  final String? mosqueName;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String title;
    final List<String> subtitleParts = [];

    switch (status) {
      case CompetitionStatus.running:
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF4CAF50);
        iconColor = const Color(0xFF2E7D32);
        icon = Icons.emoji_events_rounded;
        title = 'المسابقة فعّالة الآن';
        if (mosqueName != null) subtitleParts.add(mosqueName!);
        if (competition != null) {
          subtitleParts.add('حتى ${competition!.dateRangeAr.split('—').last.trim()}');
        }
      case CompetitionStatus.upcoming:
        bgColor = const Color(0xFFFFFDE7);
        borderColor = const Color(0xFFFFC107);
        iconColor = const Color(0xFFF57F17);
        icon = Icons.upcoming_rounded;
        title = 'مسابقة قادمة';
        if (mosqueName != null) subtitleParts.add(mosqueName!);
        if (competition != null) {
          subtitleParts.add('تبدأ ${competition!.dateRangeAr.split('—').first.trim()}');
        }
      case CompetitionStatus.finished:
        bgColor = const Color(0xFFF5F5F5);
        borderColor = const Color(0xFF9E9E9E);
        iconColor = const Color(0xFF616161);
        icon = Icons.flag_rounded;
        title = 'انتهت المسابقة';
        subtitleParts.add('انتظر الموسم القادم');
      case CompetitionStatus.noCompetition:
        return const SizedBox.shrink();
    }

    final subtitle = subtitleParts.join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: iconColor.withValues(alpha: 0.75)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
