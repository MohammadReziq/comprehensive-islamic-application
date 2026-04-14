import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/attendance_model.dart';

/// بطاقة حضور اليوم في شاشة الابن — تصميم بصري مع الصلوات الخمس
class ChildViewTodayAttendance extends StatelessWidget {
  final List<AttendanceModel> todayAttendance;
  const ChildViewTodayAttendance({super.key, required this.todayAttendance});

  static String dateStr(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  static const _allPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const _prayerNames = {
    'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر',
    'maghrib': 'المغرب', 'isha': 'العشاء',
  };
  static const _prayerIcons = {
    'fajr': Icons.nightlight_round,
    'dhuhr': Icons.wb_sunny_rounded,
    'asr': Icons.wb_twilight,
    'maghrib': Icons.nights_stay_rounded,
    'isha': Icons.dark_mode_rounded,
  };
  static const _prayerColors = {
    'fajr': Color(0xFF5C8BFF), 'dhuhr': Color(0xFFFFB300),
    'asr': Color(0xFF4CAF50), 'maghrib': Color(0xFFFF7043),
    'isha': Color(0xFF9C27B0),
  };

  @override
  Widget build(BuildContext context) {
    final attendedKeys = <String>{};
    final attendedMap = <String, AttendanceModel>{};
    for (final a in todayAttendance) {
      final key = a.prayer.toString().split('.').last.toLowerCase();
      attendedKeys.add(key);
      attendedMap[key] = a;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(attendedKeys.length),
          const SizedBox(height: 14),
          // عرض الصلوات الخمس بشكل دوائر
          _PrayerCirclesRow(
            attendedKeys: attendedKeys,
            prayerNames: _prayerNames,
            prayerIcons: _prayerIcons,
            prayerColors: _prayerColors,
          ),
          const SizedBox(height: 14),
          // شريط التقدم
          _ProgressBar(attended: attendedKeys.length, total: 5),
          if (todayAttendance.isNotEmpty) ...[
            const SizedBox(height: 12),
            // تفاصيل الحضور
            ...todayAttendance.map((a) => _buildPrayerDetail(a, attendedKeys)),
          ],
          if (todayAttendance.isEmpty) ...[
            const SizedBox(height: 14),
            _emptyState(),
          ],
        ],
      ),
    );
  }

  Widget _header(int count) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4CAF50).withValues(alpha: 0.15),
                const Color(0xFF4CAF50).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.today_rounded, color: Color(0xFF4CAF50), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حضور اليوم ✨',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2B3C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr(DateTime.now()),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: count > 0
                  ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                  : [const Color(0xFF9CA3AF), const Color(0xFFBDBDBD)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count/5',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Icon(Icons.mosque_rounded, size: 32, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'لم يُسجَّل حضور بعد — هيا إلى المسجد! 🕌',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerDetail(AttendanceModel a, Set<String> attendedKeys) {
    final key = a.prayer.toString().split('.').last.toLowerCase();
    final color = _prayerColors[key] ?? AppColors.primary;
    final name = _prayerNames[key] ?? a.prayer.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'صلاة $name',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: color, size: 14),
                const SizedBox(width: 3),
                Text(
                  '+${a.pointsEarned}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
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

/// صف الدوائر الخمس — كل صلاة دائرة ملونة
class _PrayerCirclesRow extends StatelessWidget {
  final Set<String> attendedKeys;
  final Map<String, String> prayerNames;
  final Map<String, IconData> prayerIcons;
  final Map<String, Color> prayerColors;

  const _PrayerCirclesRow({
    required this.attendedKeys,
    required this.prayerNames,
    required this.prayerIcons,
    required this.prayerColors,
  });

  static const _allPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _allPrayers.map((key) {
        final attended = attendedKeys.contains(key);
        final color = prayerColors[key] ?? AppColors.primary;
        final icon = prayerIcons[key] ?? Icons.access_time_rounded;
        final name = prayerNames[key] ?? key;
        return _PrayerCircle(
          name: name,
          icon: icon,
          color: color,
          attended: attended,
        );
      }).toList(),
    );
  }
}

class _PrayerCircle extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool attended;

  const _PrayerCircle({
    required this.name,
    required this.icon,
    required this.color,
    required this.attended,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: attended
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: attended ? null : const Color(0xFFF0F4F8),
            border: Border.all(
              color: attended ? color : const Color(0xFFE5E7EB),
              width: attended ? 2 : 1.5,
            ),
            boxShadow: attended
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Icon(
            attended ? Icons.check_rounded : icon,
            color: attended ? Colors.white : const Color(0xFFBDBDBD),
            size: attended ? 18 : 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: attended ? FontWeight.w700 : FontWeight.w500,
            color: attended ? color : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

/// شريط تقدم الحضور
class _ProgressBar extends StatelessWidget {
  final int attended;
  final int total;

  const _ProgressBar({required this.attended, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? attended / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تقدّمك اليوم',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '${(fraction * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fraction >= 1.0
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF1A2B3C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0F4F8),
            valueColor: AlwaysStoppedAnimation<Color>(
              fraction >= 1.0
                  ? const Color(0xFF4CAF50)
                  : fraction >= 0.6
                      ? const Color(0xFFFFB300)
                      : const Color(0xFF5C8BFF),
            ),
          ),
        ),
      ],
    );
  }
}
