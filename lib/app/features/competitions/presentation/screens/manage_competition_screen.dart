// lib/app/features/competitions/presentation/screens/manage_competition_screen.dart
// إدارة المسابقات — للإمام

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/competition_model.dart';
import '../bloc/competition_bloc.dart';
import '../bloc/competition_event.dart';
import '../bloc/competition_state.dart';

class ManageCompetitionScreen extends StatelessWidget {
  final String mosqueId;
  const ManageCompetitionScreen({super.key, required this.mosqueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompetitionBloc>()
        ..add(LoadAllCompetitions(mosqueId)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المسابقات'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'مسابقة جديدة',
                  onPressed: () => _showCreateDialog(ctx, mosqueId),
                ),
              ),
            ],
          ),
          body: BlocConsumer<CompetitionBloc, CompetitionState>(
            listener: (context, state) {
              if (state is CompetitionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is CompetitionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CompetitionListLoaded) {
                if (state.competitions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: 64, color: Colors.amber),
                        const SizedBox(height: 16),
                        const Text('لا توجد مسابقات بعد',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _showCreateDialog(context, mosqueId),
                          icon: const Icon(Icons.add),
                          label: const Text('إنشاء مسابقة'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<CompetitionBloc>()
                        .add(LoadAllCompetitions(mosqueId));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.competitions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final comp = state.competitions[i];
                      return _CompetitionCard(
                        competition: comp,
                        mosqueId: mosqueId,
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, String mosqueId) {
    final nameCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('مسابقة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المسابقة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(startDate == null
                      ? 'تاريخ البداية'
                      : DateFormat('yyyy/MM/dd').format(startDate!)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDialogState(() => startDate = d);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(endDate == null
                      ? 'تاريخ النهاية'
                      : DateFormat('yyyy/MM/dd').format(endDate!)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDialogState(() => endDate = d);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('أكمل جميع الحقول')),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                context.read<CompetitionBloc>().add(CreateCompetition(
                  mosqueId:  mosqueId,
                  nameAr:    nameCtrl.text.trim(),
                  startDate: startDate!,
                  endDate:   endDate!,
                ));
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final CompetitionModel competition;
  final String mosqueId;

  const _CompetitionCard({
    required this.competition,
    required this.mosqueId,
  });

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
                if (competition.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('نشطة',
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              competition.dateRangeAr,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!competition.isActive)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<CompetitionBloc>().add(
                          ActivateCompetition(competition.id, mosqueId),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('تفعيل'),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<CompetitionBloc>().add(
                          DeactivateCompetition(competition.id, mosqueId),
                        );
                      },
                      icon: const Icon(Icons.stop,
                          color: AppColors.error),
                      label: const Text('إيقاف',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _LeaderboardView(
                            competitionId: competition.id,
                            competitionName: competition.nameAr,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('الترتيب'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  final String competitionId;
  final String competitionName;

  const _LeaderboardView({
    required this.competitionId,
    required this.competitionName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompetitionBloc>()
        ..add(LoadLeaderboard(competitionId)),
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
                      child: Text('لا يوجد حضور في هذه المسابقة بعد'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.entries.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final entry = state.entries[i];
                    final medals = ['🥇', '🥈', '🥉'];
                    final medal = i < 3 ? medals[i] : '${i + 1}';
                    return ListTile(
                      leading: Text(medal,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(entry.childName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${entry.attendanceCount} صلاة'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
