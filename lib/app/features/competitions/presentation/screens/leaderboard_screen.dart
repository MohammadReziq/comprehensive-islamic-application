import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/competition_bloc.dart';
import '../bloc/competition_event.dart';
import '../bloc/competition_state.dart';

/// شاشة لوحة الترتيب لمسابقة معينة.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  final String competitionId;
  final String competitionName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CompetitionBloc>()..add(LoadLeaderboard(competitionId)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text('ترتيب: $competitionName'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: BlocBuilder<CompetitionBloc, CompetitionState>(
            builder: (context, state) {
              if (state is CompetitionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is LeaderboardLoaded) {
                if (state.entries.isEmpty) {
                  return const Center(
                    child: Text('لا يوجد حضور في هذه المسابقة بعد'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.entries.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final entry = state.entries[i];
                    const medals = ['🥇', '🥈', '🥉'];
                    final medal = i < 3 ? medals[i] : '${i + 1}';
                    return ListTile(
                      leading: Text(
                        medal,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        entry.childName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${entry.attendanceCount} صلاة'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.totalPoints} نقطة',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              if (state is CompetitionError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
