import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../competitions/presentation/bloc/competition_bloc.dart';
import '../../../competitions/presentation/bloc/competition_event.dart';
import '../../../competitions/presentation/bloc/competition_state.dart';
import '../../../competitions/presentation/widgets/competition_card.dart';
import '../../../competitions/presentation/widgets/competition_empty_state.dart';
import '../../../competitions/presentation/widgets/create_competition_dialog.dart';

/// شاشة إدارة المسابقات — للإمام.
class ManageCompetitionScreen extends StatelessWidget {
  final String mosqueId;
  const ManageCompetitionScreen({super.key, required this.mosqueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CompetitionBloc>()..add(LoadAllCompetitions(mosqueId)),
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
                  onPressed: () => showDialog(
                    context: ctx,
                    builder: (_) =>
                        CreateCompetitionDialog(mosqueId: mosqueId),
                  ),
                ),
              ),
            ],
          ),
          body: BlocConsumer<CompetitionBloc, CompetitionState>(
            listener: (context, state) {
              if (state is CompetitionError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ));
              }
            },
            builder: (context, state) {
              if (state is CompetitionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CompetitionListLoaded) {
                if (state.competitions.isEmpty) {
                  return CompetitionEmptyState(mosqueId: mosqueId);
                }
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<CompetitionBloc>()
                      .add(LoadAllCompetitions(mosqueId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.competitions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => CompetitionCard(
                      competition: state.competitions[i],
                      mosqueId: mosqueId,
                    ),
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
}
