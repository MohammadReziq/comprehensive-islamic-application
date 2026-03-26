import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../models/attendance_model.dart';

/// بطاقة حضور اليوم لطفل واحد — الصلوات الخمس
class DailyAttendanceRow extends StatelessWidget {
  final String childName;
  final List<AttendanceModel> todayAttendance;

  const DailyAttendanceRow({
    super.key,
    required this.childName,
    required this.todayAttendance,
  });

  bool _isAttended(Prayer prayer) {
    return todayAttendance.any((a) => a.prayer == prayer);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اسم الطفل
            Text('حضور اليوم — $childName',
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // الصلوات الخمس
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: Prayer.values.map((prayer) {
                final attended = _isAttended(prayer);
                return _PrayerIndicator(
                  prayer: prayer,
                  attended: attended,
                );
              }).toList(),
            ),

            // إحصائية سريعة
            const SizedBox(height: 8),
            _buildSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final attendedCount = Prayer.values.where(_isAttended).length;
    final text = '$attendedCount من 5 صلوات';
    final color = attendedCount >= 4
        ? AppColors.success
        : attendedCount >= 2
            ? Colors.orange
            : Colors.red;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.cairo(fontSize: 12, color: color)),
      ],
    );
  }
}

class _PrayerIndicator extends StatelessWidget {
  final Prayer prayer;
  final bool attended;

  const _PrayerIndicator({
    required this.prayer,
    required this.attended,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: attended
                ? AppColors.success.withOpacity(0.15)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: attended ? AppColors.success : Colors.grey.shade300,
              width: attended ? 2 : 1,
            ),
          ),
          child: Center(
            child: attended
                ? Icon(Icons.check, color: AppColors.success, size: 22)
                : Text('─',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
          ),
        ),
        const SizedBox(height: 4),
        Text(prayer.nameAr,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: attended ? AppColors.success : Colors.grey,
              fontWeight: attended ? FontWeight.bold : FontWeight.normal,
            )),
      ],
    );
  }
}
