import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/competition_bloc.dart';
import '../bloc/competition_event.dart';

/// الحالة الفارغة لقائمة المسابقات.
class CompetitionEmptyState extends StatelessWidget {
  const CompetitionEmptyState({
    super.key,
    required this.mosqueId,
  });

  final String mosqueId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مسابقات بعد',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إنشاء مسابقة'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    // يُفوَّض الاستدعاء إلى شاشة الأب
    context.read<CompetitionBloc>().add(LoadAllCompetitions(mosqueId));
  }
}
