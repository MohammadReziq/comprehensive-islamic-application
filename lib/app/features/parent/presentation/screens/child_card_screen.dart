import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/competition_model.dart';
import '../../data/repositories/child_repository.dart';
import '../../../competitions/data/repositories/competition_repository.dart';
import '../widgets/child_qr_card.dart';
import '../widgets/child_stats_card.dart';
import '../widgets/child_linked_mosques_card.dart';
import '../widgets/child_link_mosque_card.dart';
import '../widgets/child_edit_dialog.dart';
import '../widgets/feature_gradient_header.dart';

/// شاشة بطاقة الابن
class ChildCardScreen extends StatefulWidget {
  const ChildCardScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ChildCardScreen> createState() => _ChildCardScreenState();
}

class _ChildCardScreenState extends State<ChildCardScreen> {
  ChildModel? _child;
  bool _loading = true;
  String? _error;
  List<MosqueLink> _linkedMosques = [];
  bool _competitionRunning = false;
  Set<String> _attendedDates = {};
  final _mosqueCodeCtrl = TextEditingController();
  bool _linkingMosque = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mosqueCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final child = await sl<ChildRepository>().getMyChild(widget.childId);

      final res = await supabase
          .from('mosque_children')
          .select('mosque_id, type, local_number, mosques(id, name)')
          .eq('child_id', widget.childId)
          .eq('is_active', true);

      final linked = (res as List).map((e) {
        final mosqueData = e['mosques'] as Map<String, dynamic>? ?? {};
        return MosqueLink(
          mosqueId: e['mosque_id'] as String,
          mosqueName: mosqueData['name'] as String? ?? '—',
          type: MosqueType.fromString(e['type'] as String? ?? 'primary'),
          localNumber: e['local_number'] as int? ?? 0,
        );
      }).toList();

      bool competitionRunning = false;
      for (final m in linked) {
        try {
          final result = await sl<CompetitionRepository>().getCompetitionStatus(m.mosqueId);
          if (result.status == CompetitionStatus.running) { competitionRunning = true; break; }
        } catch (_) {}
      }

      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 6));
      final attendRes = await supabase
          .from('attendance')
          .select('prayer_date')
          .eq('child_id', widget.childId)
          .gte('prayer_date', ChildStatsCard.dateStr(from))
          .lte('prayer_date', ChildStatsCard.dateStr(now));
      final attended = { for (final row in (attendRes as List)) row['prayer_date'] as String };

      if (mounted) {
        setState(() {
          _child = child;
          _linkedMosques = linked;
          _competitionRunning = competitionRunning;
          _attendedDates = attended;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _linkMosque() async {
    final code = _mosqueCodeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _linkingMosque = true);
    try {
      await sl<ChildRepository>().linkChildToMosque(childId: widget.childId, mosqueCode: code);
      if (mounted) {
        _mosqueCodeCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم ربط الابن بالمسجد'), behavior: SnackBarBehavior.floating),
        );
        _load();
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _linkingMosque = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _child == null
                    ? const Center(child: Text('الابن غير موجود'))
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: FeatureGradientHeader(
                              title: _child!.name,
                              subtitle: Text(
                                '${_child!.age} سنة · ${_child!.totalPoints} نقطة',
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.65)),
                              ),
                              trailing: GestureDetector(
                                onTap: () => ChildEditDialog.show(context: context, child: _child!, childId: widget.childId, onSaved: _load),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  ChildQrCard(child: _child!, linkedMosques: _linkedMosques),
                                  const SizedBox(height: 16),
                                  ChildStatsCard(child: _child!, attendedDates: _attendedDates),
                                  const SizedBox(height: 16),
                                  if (_linkedMosques.isEmpty)
                                    ChildLinkMosqueCard(
                                      controller: _mosqueCodeCtrl,
                                      isLinking: _linkingMosque,
                                      onLink: _linkMosque,
                                    )
                                  else
                                    ChildLinkedMosquesCard(
                                      linkedMosques: _linkedMosques,
                                      onAddMosque: () => ChildLinkMosqueCard.showAddMosqueSheet(
                                        context: context,
                                        controller: _mosqueCodeCtrl,
                                        isLinking: _linkingMosque,
                                        onLink: _linkMosque,
                                      ),
                                    ),
                                  if (_competitionRunning) ...[
                                    const SizedBox(height: 16),
                                    _buildActionsCard(context),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: GestureDetector(
        onTap: () => context.push('/parent/children/${widget.childId}/request-correction'),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: const Color(0xFF9C27B0).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF9C27B0), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('طلب تصحيح حضور', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C))),
            ),
            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
