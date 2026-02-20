import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyCorrectionsScreen extends StatefulWidget {
  const MyCorrectionsScreen({super.key});

  @override
  State<MyCorrectionsScreen> createState() => _MyCorrectionsScreenState();
}

class _MyCorrectionsScreenState extends State<MyCorrectionsScreen> {
  // ⚠️ استبدل List<dynamic> بـ List<CorrectionRequestModel> بعد ربط CorrectionBloc
  List<dynamic> _corrections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // ⚠️ استدعي CorrectionRepository.getMyRequests() هنا
      // final list = await sl<CorrectionRepository>().getMyRequests();
      // if (mounted) setState(() => _corrections = list);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted)
        setState(() {
          _corrections = [];
          _loading = false;
        });
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
        body: CustomScrollView(
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
                    color: Colors.white.withOpacity(0.12),
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
              const Text(
                'طلبات التصحيح',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectionCard(dynamic correction) {
    // ⚠️ استبدل بـ CorrectionRequestModel
    final statusColors = {
      'pending': const Color(0xFFFFB300),
      'approved': const Color(0xFF4CAF50),
      'rejected': const Color(0xFFE53935),
    };
    final statusLabels = {
      'pending': 'معلق',
      'approved': 'مقبول',
      'rejected': 'مرفوض',
    };
    final status = correction['status'] as String? ?? 'pending';
    final color = statusColors[status] ?? const Color(0xFFFFB300);
    final label = statusLabels[status] ?? 'معلق';

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_note_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correction['child_name'] ?? 'طفل',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                Text(
                  '${correction['prayer'] ?? ''} · ${correction['prayer_date'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
