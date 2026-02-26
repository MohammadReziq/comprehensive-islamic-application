import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../injection_container.dart';
import '../../../../models/correction_request_model.dart';
import '../../../corrections/data/repositories/correction_repository.dart';

class MyCorrectionsScreen extends StatefulWidget {
  const MyCorrectionsScreen({super.key});

  @override
  State<MyCorrectionsScreen> createState() => _MyCorrectionsScreenState();
}

class _MyCorrectionsScreenState extends State<MyCorrectionsScreen> {
  List<CorrectionRequestModel> _corrections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await sl<CorrectionRepository>().getMyRequests();
      if (mounted) {
        setState(() {
          _corrections = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_corrections.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildCorrectionCard(_corrections[i]),
                      childCount: _corrections.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'طلبات التصحيح',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${_corrections.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha:0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectionCard(CorrectionRequestModel c) {
    const prayerNames = {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    };
    final statusColors = {
      CorrectionStatus.pending: const Color(0xFFFFB300),
      CorrectionStatus.approved: const Color(0xFF4CAF50),
      CorrectionStatus.rejected: const Color(0xFFE53935),
    };
    final statusLabels = {
      CorrectionStatus.pending: 'معلق',
      CorrectionStatus.approved: 'مقبول',
      CorrectionStatus.rejected: 'مرفوض',
    };
    final statusIcons = {
      CorrectionStatus.pending: Icons.hourglass_empty_rounded,
      CorrectionStatus.approved: Icons.check_circle_rounded,
      CorrectionStatus.rejected: Icons.cancel_rounded,
    };

    final color = statusColors[c.status] ?? const Color(0xFFFFB300);
    final label = statusLabels[c.status] ?? 'معلق';
    final icon = statusIcons[c.status] ?? Icons.edit_note_rounded;
    final prayerAr = prayerNames[c.prayer.value] ?? c.prayer.value;
    final dateStr =
        '${c.prayerDate.year}/${c.prayerDate.month.toString().padLeft(2, '0')}/${c.prayerDate.day.toString().padLeft(2, '0')}';
    final childName = c.childName ?? 'ابن';

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'صلاة $prayerAr · $dateStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (c.note != null && c.note!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    c.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text(
            'لا توجد طلبات تصحيح',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ستظهر هنا طلبات التصحيح التي ترسلها',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
