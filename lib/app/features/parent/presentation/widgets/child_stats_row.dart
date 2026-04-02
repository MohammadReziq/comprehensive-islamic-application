import 'package:flutter/material.dart';
import '../../../../models/child_model.dart';

/// صف إحصائيات الابن: النقاط + السلسلة + الأفضل
class ChildStatsRow extends StatelessWidget {
  final ChildModel child;

  const ChildStatsRow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Expanded(child: _StatItem(label: 'النقاط', value: '${child.totalPoints}', icon: Icons.star_rounded, color: const Color(0xFFFFB300))),
          const SizedBox(width: 10),
          Expanded(child: _StatItem(label: 'السلسلة', value: '${child.currentStreak} يوم', icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF7043))),
          const SizedBox(width: 10),
          Expanded(child: _StatItem(label: 'الأفضل', value: '${child.bestStreak} يوم', icon: Icons.emoji_events_rounded, color: const Color(0xFF9C27B0))),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
