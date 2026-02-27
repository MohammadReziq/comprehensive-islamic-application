import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/competition_model.dart';
import '../../data/repositories/child_repository.dart';
import '../../../competitions/data/repositories/competition_repository.dart';

/// بيانات مسجد مرتبط بالابن (محلية للشاشة)
class _MosqueLink {
  const _MosqueLink({
    required this.mosqueId,
    required this.mosqueName,
    required this.type,
    required this.localNumber,
  });

  final String mosqueId;
  final String mosqueName;
  final MosqueType type;
  final int localNumber;
}

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

  List<_MosqueLink> _linkedMosques = [];
  bool _competitionRunning = false;

  /// آخر 7 أيام — Set من تواريخ حضر فيها الابن
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final child = await sl<ChildRepository>().getMyChild(widget.childId);

      // جلب المساجد المرتبطة مع أسمائها والرقم المحلي في استعلام واحد
      final res = await supabase
          .from('mosque_children')
          .select('mosque_id, type, local_number, mosques(id, name)')
          .eq('child_id', widget.childId)
          .eq('is_active', true);

      final linked = (res as List).map((e) {
        final mosqueData = e['mosques'] as Map<String, dynamic>? ?? {};
        return _MosqueLink(
          mosqueId: e['mosque_id'] as String,
          mosqueName: mosqueData['name'] as String? ?? '—',
          type: MosqueType.fromString(e['type'] as String? ?? 'primary'),
          localNumber: e['local_number'] as int? ?? 0,
        );
      }).toList();

      // التحقق من وجود مسابقة جارية في أي مسجد مرتبط
      bool competitionRunning = false;
      for (final m in linked) {
        try {
          final result = await sl<CompetitionRepository>().getCompetitionStatus(
            m.mosqueId,
          );
          if (result.status == CompetitionStatus.running) {
            competitionRunning = true;
            break;
          }
        } catch (_) {}
      }

      // جلب آخر 7 أيام — استعلام واحد
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 6));
      final attendRes = await supabase
          .from('attendance')
          .select('prayer_date')
          .eq('child_id', widget.childId)
          .gte('prayer_date', _dateStr(from))
          .lte('prayer_date', _dateStr(now));
      final attended = {
        for (final row in (attendRes as List)) row['prayer_date'] as String,
      };

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
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// dialog تعديل اسم وعمر الابن
  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _child!.name);
    int age = _child!.age;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'تعديل بيانات الابن',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'العمر',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // ناقص
                    GestureDetector(
                      onTap: age > 3
                          ? () => setDlg(() => age--)
                          : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: age > 3
                              ? const Color(0xFFF5F6FA)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          color: age > 3
                              ? const Color(0xFF1A2B3C)
                              : Colors.grey.shade300,
                          size: 18,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '$age',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // زائد
                    GestureDetector(
                      onTap: age < 18
                          ? () => setDlg(() => age++)
                          : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: age < 18
                              ? const Color(0xFFF5F6FA)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: age < 18
                              ? const Color(0xFF1A2B3C)
                              : Colors.grey.shade300,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        setDlg(() => saving = true);
                        try {
                          await sl<ChildRepository>().updateChild(
                            childId: widget.childId,
                            name: name,
                            age: age,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        } catch (e) {
                          setDlg(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
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
            content: Text('تم ربط الابن بالمسجد'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // إعادة تحميل لتحديث قائمة المساجد
        _load();
        return;
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
            ? const Center(child: Text('الابن غير موجود'))
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
                          _buildLast7DaysCard(),
                          const SizedBox(height: 16),
                          // ─── منطق المساجد الشرطي ───
                          if (_linkedMosques.isEmpty)
                            _buildLinkMosqueCard()
                          else
                            _buildLinkedMosquesCard(),
                          // ─── طلب التصحيح — مشروط بوجود مسابقة جارية ───
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
              // زر تعديل بيانات الابن
              GestureDetector(
                onTap: _showEditDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    // المسجد الأساسي لعرض الرقم المحلي
    final primaryMosque = _linkedMosques.isNotEmpty
        ? _linkedMosques.firstWhere(
            (m) => m.type == MosqueType.primary,
            orElse: () => _linkedMosques.first,
          )
        : null;

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
            'بطاقة الابن',
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
          QrImageView(
            data: _child!.qrCode,
            version: QrVersions.auto,
            size: 180,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          // كود QR النصي قابل للنسخ
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
          const SizedBox(height: 10),
          // زر مشاركة بطاقة الابن مع المشرف
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final primary = primaryMosque;
                final numberLine = (primary != null && primary.localNumber > 0)
                    ? '\nرقمه في ${primary.mosqueName}: ${primary.localNumber.toString().padLeft(3, '0')}'
                    : '';
                Share.share(
                  'بطاقة ${_child!.name} — صلاتي حياتي\n'
                  'كود QR: ${_child!.qrCode}'
                  '$numberLine\n\n'
                  'أعطِ هذا الكود للمشرف لتسجيل الحضور.',
                  subject: 'بطاقة ${_child!.name}',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('مشاركة البطاقة مع المشرف'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          // رقم الطالب في المسجد الأساسي
          if (primaryMosque != null && primaryMosque.localNumber > 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: '${primaryMosque.localNumber}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ الرقم'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF2E8B57).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 16,
                      color: Color(0xFF2E8B57),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'رقمه في ${primaryMosque.mosqueName}: ${primaryMosque.localNumber.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E8B57),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Color(0xFF2E8B57),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  // ─── آخر 7 أيام ───
  Widget _buildLast7DaysCard() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    const dayNames = ['س', 'أ', 'ث', 'ر', 'خ', 'ج', 'م'];

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
              Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF1B5E8A), size: 20),
              SizedBox(width: 8),
              Text(
                'آخر 7 أيام',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2B3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = days[i];
              final dateKey = _dateStr(day);
              final attended = _attendedDates.contains(dateKey);
              final isToday = i == 6;
              return Column(
                children: [
                  Text(
                    dayNames[day.weekday % 7],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? const Color(0xFF1B5E8A)
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: attended
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(
                              color: const Color(0xFF1B5E8A), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        attended
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 16,
                        color: attended
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? const Color(0xFF1B5E8A)
                          : Colors.grey.shade400,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── المساجد المرتبطة (عندما يوجد مسجد واحد على الأقل) ───
  Widget _buildLinkedMosquesCard() {
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
                'المساجد المرتبطة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2B3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._linkedMosques.map((m) => _mosqueRow(m)),
          const Divider(height: 20),
          // زر إضافة مسجد إضافي
          GestureDetector(
            onTap: _showAddMosqueSheet,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF2E8B57),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ربط بمسجد إضافي',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mosqueRow(_MosqueLink m) {
    final isPrimary = m.type == MosqueType.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                m.mosqueName.isNotEmpty ? m.mosqueName[0] : 'م',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E8B57),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.mosqueName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                Text(
                  'رقم ${m.localNumber.toString().padLeft(3, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPrimary
                  ? const Color(0xFF2E8B57).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPrimary ? 'أساسي' : 'إضافي',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary ? const Color(0xFF2E8B57) : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMosqueSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ربط بمسجد إضافي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'أدخل كود المسجد الذي أعطاك إياه الإمام',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
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
                    onTap: _linkingMosque
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _linkMosque();
                          },
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
        ),
      ),
    );
  }

  // ─── نموذج الربط الأول (عندما لا يوجد مسجد مرتبط بعد) ───
  Widget _buildLinkMosqueCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ربط بمسجد',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    Text(
                      'الابن غير مرتبط بأي مسجد بعد',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

  // ─── طلب تصحيح الحضور — يظهر فقط عند وجود مسابقة جارية ───
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
      child: _actionRow(
        icon: Icons.edit_note_rounded,
        color: const Color(0xFF9C27B0),
        label: 'طلب تصحيح حضور',
        onTap: () => context.push(
          '/parent/children/${widget.childId}/request-correction',
        ),
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
