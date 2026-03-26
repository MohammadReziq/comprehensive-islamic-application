import 'package:flutter/material.dart';
import '../../../../models/competition_model.dart';

/// [C5] بانر المسابقة — 4 حالات
/// يُدمج في home_screen.dart عند وجود مسابقة
class CompetitionBannerWidget extends StatelessWidget {
  final CompetitionStatus status;
  final CompetitionModel? competition;
  final String? mosqueName;
  final VoidCallback? onTap;

  const CompetitionBannerWidget({
    super.key,
    required this.status,
    this.competition,
    this.mosqueName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case CompetitionStatus.running:
        return _buildActiveBanner(context);
      case CompetitionStatus.upcoming:
        return _buildUpcomingBanner(context);
      case CompetitionStatus.finished:
        return _buildEndedBanner(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 1. مسابقة نشطة ──
  Widget _buildActiveBanner(BuildContext context) {
    final name = competition?.nameAr ?? 'مسابقة الصلاة';
    final mosque = mosqueName ?? 'المسجد';
    final end = competition?.endDate;
    final remaining = end != null ? end.difference(DateTime.now()) : null;

    return _BannerCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      mosque,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF69F0AE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.4)),
                ),
                child: const Text(
                  '● نشطة',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF69F0AE),
                  ),
                ),
              ),
            ],
          ),
          if (remaining != null && !remaining.isNegative) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'تنتهي خلال ${_formatRemaining(remaining)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 2. مسابقة قادمة ──
  Widget _buildUpcomingBanner(BuildContext context) {
    final name = competition?.nameAr ?? 'مسابقة قادمة';
    final mosque = mosqueName ?? 'المسجد';
    final start = competition?.startDate;
    final remaining = start != null ? start.difference(DateTime.now()) : null;

    return _BannerCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
      ),
      onTap: onTap,
      child: Row(
        children: [
          const Text('📅', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  remaining != null
                      ? 'تبدأ خلال ${_formatRemaining(remaining)} — $mosque'
                      : mosque,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'قادمة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. مسابقة منتهية ──
  Widget _buildEndedBanner(BuildContext context) {
    final name = competition?.nameAr ?? 'المسابقة';
    return _BannerCard(
      gradient: LinearGradient(
        colors: [Colors.grey.shade800, Colors.grey.shade700],
      ),
      onTap: onTap,
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'انتهت المسابقة — اطّلع على النتائج',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 20),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inDays >= 1) return '${d.inDays} يوم';
    if (d.inHours >= 1) return '${d.inHours} ساعة';
    return '${d.inMinutes} دقيقة';
  }
}

// ─── Card Container مشترك ───
class _BannerCard extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  final VoidCallback? onTap;

  const _BannerCard({
    required this.gradient,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
