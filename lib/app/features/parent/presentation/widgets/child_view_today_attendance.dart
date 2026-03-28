import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/attendance_model.dart';

/// بطاقة حضور اليوم في شاشة الابن (child_view)
class ChildViewTodayAttendance extends StatelessWidget {
  final List<AttendanceModel> todayAttendance;
  const ChildViewTodayAttendance({super.key, required this.todayAttendance});

  static String dateStr(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  static const _prayerNames = {
    'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر',
    'maghrib': 'المغرب', 'isha': 'العشاء',
  };
  static const _prayerColors = {
    'fajr': Color(0xFF5C8BFF), 'dhuhr': Color(0xFFFFB300),
    'asr': Color(0xFF4CAF50), 'maghrib': Color(0xFFFF7043),
    'isha': Color(0xFF9C27B0),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          if (todayAttendance.isEmpty)
            _emptyState()
          else
            ...todayAttendance.map(_prayerRow),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.today_rounded, color: Color(0xFF4CAF50), size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حضور اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
            Text(dateStr(DateTime.now()), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('${todayAttendance.length} صلاة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('لا يوجد حضور مسجّل اليوم', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _prayerRow(AttendanceModel a) {
    final key = a.prayer.toString().split('.').last.toLowerCase();
    final color = _prayerColors[key] ?? AppColors.primary;
    final name = _prayerNames[key] ?? a.prayer.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.check_circle_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text('صلاة $name', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('+${a.pointsEarned} نقطة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
