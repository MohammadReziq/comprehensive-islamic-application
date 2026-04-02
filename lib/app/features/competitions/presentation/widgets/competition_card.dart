import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/competition_model.dart';
import '../bloc/competition_bloc.dart';
import '../bloc/competition_event.dart';
import '../screens/leaderboard_screen.dart';

/// بطاقة مسابقة واحدة — تعرض معلومات المسابقة مع أزرار التفعيل والترتيب.
class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    required this.mosqueId,
  });

  final CompetitionModel competition;
  final String mosqueId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: competition.isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: competition.isActive
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── العنوان ───
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: competition.isActive ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    competition.nameAr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (competition.isActive) _ActiveBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              competition.dateRangeAr,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            // ─── أزرار التفعيل/الإيقاف والترتيب ───
            Row(
              children: [
                Expanded(child: _buildToggleButton(context)),
                const SizedBox(width: 8),
                Expanded(child: _buildLeaderboardButton(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    if (!competition.isActive) {
      return FilledButton.icon(
        onPressed: () => context
            .read<CompetitionBloc>()
            .add(ActivateCompetition(competition.id, mosqueId)),
        icon: const Icon(Icons.play_arrow),
        label: const Text('تفعيل'),
        style: FilledButton.styleFrom(backgroundColor: Colors.green),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => context
          .read<CompetitionBloc>()
          .add(DeactivateCompetition(competition.id, mosqueId)),
      icon: const Icon(Icons.stop, color: AppColors.error),
      label:
          const Text('إيقاف', style: TextStyle(color: AppColors.error)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildLeaderboardButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LeaderboardScreen(
            competitionId: competition.id,
            competitionName: competition.nameAr,
          ),
        ),
      ),
      icon: const Icon(Icons.leaderboard),
      label: const Text('الترتيب'),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'نشطة',
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
