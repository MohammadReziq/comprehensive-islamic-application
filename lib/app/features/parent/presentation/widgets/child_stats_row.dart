import 'package:flutter/material.dart';
import '../../../../models/child_model.dart';

/// صف إحصائيات الابن: النقاط + السلسلة + الأفضل — تصميم محسّن مع أنيميشن
class ChildStatsRow extends StatefulWidget {
  final ChildModel child;

  const ChildStatsRow({super.key, required this.child});

  @override
  State<ChildStatsRow> createState() => _ChildStatsRowState();
}

class _ChildStatsRowState extends State<ChildStatsRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedStatCard(
              controller: _controller,
              delay: 0.0,
              label: 'النقاط',
              value: '${widget.child.totalPoints}',
              icon: Icons.star_rounded,
              gradient: const [Color(0xFFFFB300), Color(0xFFFFA000)],
              bgColor: const Color(0xFFFFF8E1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AnimatedStatCard(
              controller: _controller,
              delay: 0.15,
              label: 'السلسلة',
              value: '${widget.child.currentStreak}',
              suffix: ' يوم',
              icon: Icons.local_fire_department_rounded,
              gradient: const [Color(0xFFFF7043), Color(0xFFFF5722)],
              bgColor: const Color(0xFFFBE9E7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AnimatedStatCard(
              controller: _controller,
              delay: 0.3,
              label: 'الأفضل',
              value: '${widget.child.bestStreak}',
              suffix: ' يوم',
              icon: Icons.emoji_events_rounded,
              gradient: const [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              bgColor: const Color(0xFFF3E5F5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final String label;
  final String value;
  final String? suffix;
  final IconData icon;
  final List<Color> gradient;
  final Color bgColor;

  const _AnimatedStatCard({
    required this.controller,
    required this.delay,
    required this.label,
    required this.value,
    this.suffix,
    required this.icon,
    required this.gradient,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay, delay + 0.5, curve: Curves.easeOutBack),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + 0.5 * animation.value,
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: gradient[0].withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            // أيقونة مع خلفية gradient
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            // القيمة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: gradient[0],
                  ),
                ),
                if (suffix != null)
                  Text(
                    suffix!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: gradient[0].withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
