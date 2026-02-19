import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/imam_repository.dart';
import '../../../corrections/data/repositories/correction_repository.dart';
import '../widgets/correction_tile.dart';

/// شاشة طلبات التصحيح للإمام — تبويبان: معلقة / مُعالجة
class ImamCorrectionsScreen extends StatefulWidget {
  const ImamCorrectionsScreen({super.key, required this.mosqueId});

  final String mosqueId;

  @override
  State<ImamCorrectionsScreen> createState() => _ImamCorrectionsScreenState();
}

class _ImamCorrectionsScreenState extends State<ImamCorrectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // قوائم البيانات
  List<Map<String, dynamic>>? _pending;
  List<Map<String, dynamic>>? _processed;

  // تتبع حالة التحميل لكل طلب
  final Map<String, bool> _loadingMap = {};

  // مفاتيح لإعادة بناء الـ FutureBuilders
  int _pendingKey = 0;
  int _processedKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPending();
    _loadProcessed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    try {
      final list = await sl<CorrectionRepository>().getPendingForMosque(
        widget.mosqueId,
      );
      if (mounted) {
        setState(() {
          _pending = list.map((e) => e.toJson()).toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pending = []);
    }
  }

  Future<void> _loadProcessed() async {
    try {
      final list = await sl<ImamRepository>().getProcessedCorrections(
        widget.mosqueId,
      );
      if (mounted) setState(() => _processed = list);
    } catch (_) {
      if (mounted) setState(() => _processed = []);
    }
  }

  Future<void> _approve(Map<String, dynamic> correction) async {
    final id = correction['id'] as String;
    setState(() => _loadingMap[id] = true);
    try {
      await sl<CorrectionRepository>().approveRequest(id);
      if (mounted) {
        setState(() {
          _loadingMap.remove(id);
          _pending?.removeWhere((c) => c['id'] == id);
        });
        _showSnack('تمت الموافقة ✅', AppColors.success);
        _loadProcessed();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMap.remove(id));
        _showSnack(
          'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
          AppColors.error,
        );
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> correction) async {
    final id = correction['id'] as String;

    // سؤال اختياري عن السبب
    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text('رفض الطلب', style: GoogleFonts.cairo()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هل تريد رفض طلب التصحيح؟',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'سبب الرفض (اختياري)',
                  hintStyle: GoogleFonts.cairo(fontSize: 13),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: GoogleFonts.cairo(fontSize: 14),
                onChanged: (v) => reason = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text('رفض', style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loadingMap[id] = true);
    try {
      await sl<CorrectionRepository>().rejectRequest(
        id,
        reason: reason?.isNotEmpty == true ? reason : null,
      );
      if (mounted) {
        setState(() {
          _loadingMap.remove(id);
          _pending?.removeWhere((c) => c['id'] == id);
        });
        _showSnack('تم الرفض ❌', AppColors.warning);
        _loadProcessed();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMap.remove(id));
        _showSnack(
          'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
          AppColors.error,
        );
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('طلبات التصحيح', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadPending();
                _loadProcessed();
              },
              tooltip: 'تحديث',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.cairo(),
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                text: _pending == null
                    ? 'معلقة'
                    : 'معلقة (${_pending!.length})',
              ),
              const Tab(text: 'مُعالجة'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildPendingTab(), _buildProcessedTab()],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pending == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pending!.isEmpty) {
      return _buildEmpty(
        'لا توجد طلبات تصحيح معلقة',
        Icons.check_circle_outline,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      itemCount: _pending!.length,
      itemBuilder: (_, i) {
        final c = _pending![i];
        final id = c['id'] as String;
        return CorrectionTile(
          correction: c,
          isPending: true,
          isLoading: _loadingMap[id] == true,
          onApprove: () => _approve(c),
          onReject: () => _reject(c),
        );
      },
    );
  }

  Widget _buildProcessedTab() {
    if (_processed == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_processed!.isEmpty) {
      return _buildEmpty('لا توجد طلبات مُعالجة بعد', Icons.history_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      itemCount: _processed!.length,
      itemBuilder: (_, i) {
        final c = _processed![i];
        return CorrectionTile(
          correction: c,
          isPending: false,
          isLoading: false,
        );
      },
    );
  }

  Widget _buildEmpty(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            msg,
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
