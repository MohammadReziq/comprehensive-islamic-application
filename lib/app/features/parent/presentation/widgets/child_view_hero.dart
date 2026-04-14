import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../models/child_model.dart';

/// قسم Hero لشاشة الابن — مع أيقونات الرسائل وتسجيل الخروج
class ChildViewHero extends StatelessWidget {
  final ChildModel child;
  final int unreadNotesCount;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onLogoutTap;

  const ChildViewHero({
    super.key,
    required this.child,
    this.unreadNotesCount = 0,
    this.onMessagesTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = (child.totalPoints ~/ 100) + 1;
    final progressToNext = (child.totalPoints % 100) / 100.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A1628),
            Color(0xFF132D5A),
            Color(0xFF1B5E8A),
            Color(0xFF1E7A5F),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // زخرفات
          Positioned(
            top: 20, left: 20,
            child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.06), size: 80),
          ),
          Positioned(
            bottom: 10, right: -10,
            child: Icon(Icons.mosque_rounded, color: Colors.white.withValues(alpha: 0.04), size: 120),
          ),
          Positioned(top: 60, right: 30, child: _dot(6, Colors.white.withValues(alpha: 0.3))),
          Positioned(top: 40, right: 80, child: _dot(4, Colors.white.withValues(alpha: 0.2))),
          Positioned(top: 80, left: 50, child: _dot(5, Colors.white.withValues(alpha: 0.25))),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                children: [
                  // ─── الشريط العلوي: خروج (يسار) + رسائل (يمين) ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // زر تسجيل الخروج
                      _HeroIconButton(
                        icon: Icons.logout_rounded,
                        onTap: onLogoutTap,
                      ),
                      // زر الرسائل مع badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _HeroIconButton(
                            icon: Icons.mail_rounded,
                            onTap: onMessagesTap,
                          ),
                          if (unreadNotesCount > 0)
                            Positioned(
                              top: -4, left: -4,
                              child: Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF132D5A), width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '$unreadNotesCount',
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _QuickStatsRow(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

/// زر أيقونة شفاف في الهيرو
class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _HeroIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

/// الأفاتار مع حلقة
class _AnimatedAvatar extends StatefulWidget {
  final String name;
  final double progress;
  const _AnimatedAvatar({required this.name, required this.progress});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.elasticOut));
    _ring = Tween<double>(begin: 0.0, end: widget.progress).animate(
        CurvedAnimation(parent: _c, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: SizedBox(
          width: 96, height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96, height: 96,
                child: CustomPaint(painter: _RingPainter(
                  progress: _ring.value,
                  trackColor: Colors.white.withValues(alpha: 0.15),
                  progressColor: const Color(0xFFFFD54F),
                  strokeWidth: 3.5,
                )),
              ),
              Container(
                width: 78, height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.1),
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.name.isNotEmpty ? widget.name[0] : '؟',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress, strokeWidth;
  final Color trackColor, progressColor;
  _RingPainter({required this.progress, required this.trackColor, required this.progressColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - strokeWidth) / 2;
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..color = trackColor);
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * progress, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round..color = progressColor);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.progress != progress;
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final double progress;
  const _LevelBadge({required this.level, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.3),
          const Color(0xFFFFA726).withValues(alpha: 0.2),
        ]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 18),
          const SizedBox(width: 6),
          Text('المستوى $level', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFD54F))),
          const SizedBox(width: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart, widthFactor: progress,
              child: Container(decoration: BoxDecoration(color: const Color(0xFFFFD54F), borderRadius: BorderRadius.circular(2))),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final ChildModel child;
  const _QuickStatsRow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MiniStat(icon: Icons.star_rounded, value: '${child.totalPoints}', label: 'نقطة', color: const Color(0xFFFFD54F)),
        Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withValues(alpha: 0.2)),
        _MiniStat(icon: Icons.local_fire_department_rounded, value: '${child.currentStreak}', label: 'يوم', color: const Color(0xFFFF7043)),
        Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withValues(alpha: 0.2)),
        _MiniStat(icon: Icons.emoji_events_rounded, value: '${child.bestStreak}', label: 'أفضل', color: const Color(0xFF81C784)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }
}
