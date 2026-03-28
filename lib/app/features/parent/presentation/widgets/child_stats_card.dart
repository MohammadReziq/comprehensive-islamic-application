import 'package:flutter/material.dart';
import '../../../../models/child_model.dart';

/// بطاقة الإحصائيات (نقاط + سلسلة + أفضل) + بطاقة آخر 7 أيام
class ChildStatsCard extends StatelessWidget {
  final ChildModel child;
  final Set<String> attendedDates;

  const ChildStatsCard({super.key, required this.child, required this.attendedDates});

  static String dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsRow(),
        const SizedBox(height: 16),
        _buildLast7DaysCard(),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          _statItem('النقاط', '${child.totalPoints}', Icons.star_rounded, const Color(0xFFFFB300)),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _statItem('السلسلة', '${child.currentStreak} يوم', Icons.local_fire_department_rounded, const Color(0xFFFF7043)),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _statItem('الأفضل', '${child.bestStreak} يوم', Icons.emoji_events_rounded, const Color(0xFF9C27B0)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildLast7DaysCard() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    const dayNames = ['س', 'أ', 'ث', 'ر', 'خ', 'ج', 'م'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E8A), size: 20),
              SizedBox(width: 8),
              Text('آخر 7 أيام', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = days[i];
              final dateKey = dateStr(day);
              final attended = attendedDates.contains(dateKey);
              final isToday = i == 6;
              return Column(
                children: [
                  Text(
                    dayNames[day.weekday % 7],
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isToday ? const Color(0xFF1B5E8A) : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: attended ? const Color(0xFF4CAF50) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday ? Border.all(color: const Color(0xFF1B5E8A), width: 2) : null,
                    ),
                    child: Center(
                      child: Icon(
                        attended ? Icons.check_rounded : Icons.close_rounded,
                        size: 16,
                        color: attended ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? const Color(0xFF1B5E8A) : Colors.grey.shade400,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
