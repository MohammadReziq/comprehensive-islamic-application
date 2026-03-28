import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';

/// قسم حضور اليوم بالشاشة الرئيسية
class HomeTodaySection extends StatelessWidget {
  final List<ChildModel> children;
  final List<AttendanceModel> todayAttendance;
  final bool loadingAttendance;

  const HomeTodaySection({
    super.key,
    required this.children,
    required this.todayAttendance,
    required this.loadingAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'حضور اليوم',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C)),
            ),
            TextButton(
              onPressed: () async {
                await context.push('/parent/children');
                if (context.mounted) {
                  context.read<ChildrenBloc>().add(const ChildrenLoad());
                }
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (loadingAttendance)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (todayAttendance.isEmpty)
          _buildNoAttendanceCard()
        else
          ...todayAttendance.map((a) => _buildAttendanceCard(a)),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final child = children.firstWhere(
      (c) => c.id == attendance.childId,
      orElse: () => ChildModel(
        id: '', name: 'ابن', age: 0, parentId: '', qrCode: '',
        totalPoints: 0, currentStreak: 0, bestStreak: 0, createdAt: DateTime.now(),
      ),
    );

    const prayerNames = {
      'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر',
      'maghrib': 'المغرب', 'isha': 'العشاء',
    };
    const prayerColors = {
      'fajr': Color(0xFF5C8BFF), 'dhuhr': Color(0xFFFFB300),
      'asr': Color(0xFF4CAF50), 'maghrib': Color(0xFFFF7043),
      'isha': Color(0xFF9C27B0),
    };

    final prayerKey = attendance.prayer.value;
    final color = prayerColors[prayerKey] ?? AppColors.primary;
    final prayerAr = prayerNames[prayerKey] ?? attendance.prayer.nameAr;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C)),
                ),
                Text(
                  'صلاة $prayerAr · ${attendance.pointsEarned} نقطة',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'حاضر',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.calendar_today_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'لا يوجد حضور مسجل اليوم',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
