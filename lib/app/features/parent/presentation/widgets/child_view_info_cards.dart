import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/child_model.dart';
import '../../../../models/competition_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../screens/child_notes_screen.dart';

/// بطاقات: الملاحظات + المسابقات النشطة + زر تسجيل الخروج
class ChildViewInfoCards extends StatelessWidget {
  final ChildModel child;
  final int unreadNotesCount;
  final List<CompetitionModel> activeCompetitions;
  final VoidCallback onNotesViewed;

  const ChildViewInfoCards({
    super.key,
    required this.child,
    required this.unreadNotesCount,
    required this.activeCompetitions,
    required this.onNotesViewed,
  });

  String _dateStr(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (activeCompetitions.isNotEmpty) ...[
          _buildCompetitionsCard(),
          const SizedBox(height: 16),
        ],
        _buildNotesCard(context),
        const SizedBox(height: 16),
        _buildLogoutButton(context),
      ],
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChildNotesScreen(childId: child.id, childName: child.name),
        ));
        onNotesViewed();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.mail_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رسائلي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
                  Text('ملاحظات المشرف', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (unreadNotesCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('$unreadNotesCount', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_left_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: const Color(0xFFFFB300).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB300), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('مسابقات نشطة 🏆', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C)))),
            ],
          ),
          const SizedBox(height: 12),
          ...activeCompetitions.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nameAr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C))),
                      Text('${_dateStr(c.startDate)} → ${_dateStr(c.endDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            Text('تسجيل الخروج', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.red.shade400)),
          ],
        ),
      ),
    );
  }
}
