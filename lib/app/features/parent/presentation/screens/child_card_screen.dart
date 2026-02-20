import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../data/repositories/child_repository.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final child = await sl<ChildRepository>().getMyChild(widget.childId);
      if (mounted)
        setState(() {
          _child = child;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _linkMosque() async {
    final code = _mosqueCodeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _linkingMosque = true);
    try {
      await sl<ChildRepository>().linkChildToMosque(
        childId: widget.childId,
        mosqueCode: code,
      );
      if (mounted) {
        _mosqueCodeCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط الطفل بالمسجد'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
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
            ? const Center(child: Text('الطفل غير موجود'))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildQrCard(),
                          const SizedBox(height: 16),
                          _buildStatsCard(),
                          const SizedBox(height: 16),
                          _buildLinkMosqueCard(),
                          const SizedBox(height: 16),
                          _buildActionsCard(context),
                        ],
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _child!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_child!.age} سنة · ${_child!.totalPoints} نقطة',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'بطاقة الطفل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يمكن للمشرف مسح هذا الكود لتسجيل الحضور',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          // ⚠️ QrImageView من qr_flutter package
          QrImageView(
            data: _child!.qrCode,
            version: QrVersions.auto,
            size: 180,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          // كود نصي قابل للنسخ
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _child!.qrCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ الكود'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _child!.qrCode,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem(
            'النقاط',
            '${_child!.totalPoints}',
            Icons.star_rounded,
            const Color(0xFFFFB300),
          ),
          _divider(),
          _statItem(
            'السلسلة',
            '${_child!.currentStreak} يوم',
            Icons.local_fire_department_rounded,
            const Color(0xFFFF7043),
          ),
          _divider(),
          _statItem(
            'الأفضل',
            '${_child!.bestStreak} يوم',
            Icons.emoji_events_rounded,
            const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade200);

  Widget _buildLinkMosqueCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mosque_rounded, color: Color(0xFF2E8B57), size: 22),
              SizedBox(width: 8),
              Text(
                'ربط بمسجد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2B3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'أدخل كود المسجد الذي أعطاك إياه الإمام',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mosqueCodeCtrl,
                  decoration: InputDecoration(
                    hintText: 'كود المسجد',
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _linkingMosque ? null : _linkMosque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _linkingMosque
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ربط',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _actionRow(
            icon: Icons.edit_note_rounded,
            color: const Color(0xFF9C27B0),
            label: 'طلب تصحيح حضور',
            onTap: () => context.push(
              '/parent/children/${widget.childId}/request-correction',
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2B3C),
              ),
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
        ],
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
