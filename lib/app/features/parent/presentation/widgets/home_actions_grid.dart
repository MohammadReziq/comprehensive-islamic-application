import 'package:flutter/material.dart';
import '../../../../models/competition_model.dart';
import '../../../../core/widgets/shared_dashboard_widgets.dart';

/// بيانات إجراء واحد بالشاشة الرئيسية
class HomeAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;
  const HomeAction(this.icon, this.label, this.color, this.onTap, {this.badge = 0});
}

/// شبكة الإجراءات + بانر المسابقة
class HomeActionsGrid extends StatelessWidget {
  final List<HomeAction> actions;
  final CompetitionStatus competitionStatus;
  final CompetitionModel? competition;
  final String? competitionMosqueName;

  const HomeActionsGrid({
    super.key,
    required this.actions,
    required this.competitionStatus,
    this.competition,
    this.competitionMosqueName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 14),
          child: Text(
            'الإجراءات',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
              letterSpacing: -0.2,
            ),
          ),
        ),
        Column(children: actions.map(_buildTile).toList()),
        if (competitionStatus != CompetitionStatus.noCompetition) ...[
          const SizedBox(height: 16),
          CompetitionStatusBanner(
            status: competitionStatus,
            competition: competition,
            mosqueName: competitionMosqueName,
          ),
        ],
      ],
    );
  }

  Widget _buildTile(HomeAction a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: a.color.withValues(alpha: 0.13),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(a.icon, color: a.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                a.label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C)),
              ),
            ),
            if (a.badge > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${a.badge}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
