import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/models/competition_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../../competitions/data/repositories/competition_repository.dart';
import '../widgets/competition_card.dart';

/// شاشة إدارة المسابقات للإمام
class ImamCompetitionsScreen extends StatefulWidget {
  const ImamCompetitionsScreen({super.key, required this.mosqueId});

  final String mosqueId;

  @override
  State<ImamCompetitionsScreen> createState() => _ImamCompetitionsScreenState();
}

class _ImamCompetitionsScreenState extends State<ImamCompetitionsScreen> {
  List<CompetitionModel>? _competitions;
  bool _loading = true;
  final Map<String, bool> _loadingMap = {};
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() => _loading = true);
    try {
      final list = await sl<CompetitionRepository>().getAllForMosque(
        widget.mosqueId,
      );
      if (mounted)
        setState(() {
          _competitions = list;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _competitions = [];
          _loading = false;
        });
      _showSnack(
        'فشل التحميل: ${e.toString().replaceFirst('Exception: ', '')}',
        AppColors.error,
      );
    }
  }

  Future<void> _activate(CompetitionModel comp) async {
    setState(() => _loadingMap[comp.id] = true);
    try {
      await sl<CompetitionRepository>().activate(comp.id);
      if (mounted) {
        setState(() => _loadingMap.remove(comp.id));
        _showSnack('تم تفعيل المسابقة ✅', AppColors.success);
        _loadCompetitions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMap.remove(comp.id));
        _showSnack(
          'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
          AppColors.error,
        );
      }
    }
  }

  Future<void> _deactivate(CompetitionModel comp) async {
    setState(() => _loadingMap[comp.id] = true);
    try {
      await sl<CompetitionRepository>().deactivate(comp.id);
      if (mounted) {
        setState(() => _loadingMap.remove(comp.id));
        _showSnack('تم إيقاف المسابقة', AppColors.warning);
        _loadCompetitions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMap.remove(comp.id));
        _showSnack(
          'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
          AppColors.error,
        );
      }
    }
  }

  void _showLeaderboard(CompetitionModel comp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLG),
        ),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: Text(
                  'ترتيب — ${comp.nameAr}',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<LeaderboardEntry>>(
                  future: sl<CompetitionRepository>().getLeaderboard(comp.id),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'فشل تحميل الترتيب',
                          style: GoogleFonts.cairo(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    final entries = snapshot.data!;
                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد بيانات بعد',
                          style: GoogleFonts.cairo(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(AppDimensions.paddingMD),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimensions.spacingSM),
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        return _LeaderboardRow(entry: e);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'مسابقة جديدة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'اسم المسابقة',
                      labelStyle: GoogleFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    style: GoogleFonts.cairo(),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'أدخل اسماً' : null,
                  ),
                  const SizedBox(height: 12),
                  _DatePickerField(
                    label: 'تاريخ البداية',
                    value: startDate,
                    onPicked: (d) => setStateDialog(() => startDate = d),
                  ),
                  const SizedBox(height: 8),
                  _DatePickerField(
                    label: 'تاريخ النهاية',
                    value: endDate,
                    onPicked: (d) => setStateDialog(() => endDate = d),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (startDate == null || endDate == null) {
                    _showSnack(
                      'اختر تاريخ البداية والنهاية',
                      AppColors.warning,
                    );
                    return;
                  }
                  if (endDate!.isBefore(startDate!)) {
                    _showSnack('تاريخ النهاية قبل البداية', AppColors.error);
                    return;
                  }
                  Navigator.of(ctx).pop();
                  await _createCompetition(
                    nameCtrl.text.trim(),
                    startDate!,
                    endDate!,
                  );
                },
                child: Text('إنشاء', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(CompetitionModel comp) async {
    final nameCtrl = TextEditingController(text: comp.nameAr);
    DateTime? startDate = comp.startDate;
    DateTime? endDate = comp.endDate;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعديل المسابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'اسم المسابقة',
                      labelStyle: GoogleFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    style: GoogleFonts.cairo(),
                    validator: (v) => v == null || v.trim().isEmpty ? 'أدخل اسماً' : null,
                  ),
                  const SizedBox(height: 12),
                  _DatePickerField(
                    label: 'تاريخ البداية',
                    value: startDate,
                    onPicked: (d) => setStateDialog(() => startDate = d),
                  ),
                  const SizedBox(height: 8),
                  _DatePickerField(
                    label: 'تاريخ النهاية',
                    value: endDate,
                    onPicked: (d) => setStateDialog(() => endDate = d),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (endDate!.isBefore(startDate!)) {
                    _showSnack('تاريخ النهاية قبل البداية', AppColors.error);
                    return;
                  }
                  Navigator.of(ctx).pop();
                  await _editCompetition(comp.id, nameCtrl.text.trim(), startDate!, endDate!);
                },
                child: Text('حفظ', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCompetition(String id, String name, DateTime start, DateTime end) async {
    setState(() => _loadingMap[id] = true);
    try {
      await sl<CompetitionRepository>().update(id, nameAr: name, startDate: start, endDate: end);
      if (mounted) {
        setState(() => _loadingMap.remove(id));
        _showSnack('تم تحديث المسابقة ✅', AppColors.success);
        _loadCompetitions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMap.remove(id));
        _showSnack('فشل: ${e.toString().replaceFirst('Exception: ', '')}', AppColors.error);
      }
    }
  }

  Future<void> _confirmDelete(CompetitionModel comp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('حذف المسابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Text(
            'هل تريد حذف "${comp.nameAr}"؟\nلا يمكن التراجع عن هذا الإجراء.',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await _deleteCompetition(comp);
  }

  Future<void> _deleteCompetition(CompetitionModel comp) async {
    setState(() => _loadingMap[comp.id] = true);
    try {
      await sl<CompetitionRepository>().delete(comp.id);
      if (mounted) {
        setState(() => _loadingMap.remove(comp.id));
        _showSnack('تم حذف المسابقة', AppColors.warning);
        _loadCompetitions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMap.remove(comp.id));
        _showSnack('فشل: ${e.toString().replaceFirst('Exception: ', '')}', AppColors.error);
      }
    }
  }

  Future<void> _createCompetition(
    String name,
    DateTime start,
    DateTime end,
  ) async {
    setState(() => _creating = true);
    try {
      await sl<CompetitionRepository>().create(
        mosqueId: widget.mosqueId,
        nameAr: name,
        startDate: start,
        endDate: end,
      );
      if (mounted) {
        setState(() => _creating = false);
        _showSnack('تم إنشاء المسابقة ✅', AppColors.success);
        _loadCompetitions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        _showSnack(
          'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
          AppColors.error,
        );
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
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
          title: Text('المسابقات', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCompetitions,
              tooltip: 'تحديث',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _creating ? null : _showCreateDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: _creating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add),
          label: Text(
            'مسابقة جديدة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _competitions == null || _competitions!.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingMD,
                  AppDimensions.paddingMD,
                  AppDimensions.paddingMD,
                  100,
                ),
                itemCount: _competitions!.length,
                itemBuilder: (_, i) {
                  final comp = _competitions![i];
                  return CompetitionCard(
                    competition: comp.toJson(),
                    isLoading: _loadingMap[comp.id] == true,
                    onActivate: () => _activate(comp),
                    onDeactivate: () => _deactivate(comp),
                    onViewLeaderboard: () => _showLeaderboard(comp),
                    onEdit: () => _showEditDialog(comp),
                    onDelete: () => _confirmDelete(comp),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              'لا توجد مسابقات بعد',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أنشئ أولى مسابقاتك الآن!',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textHint),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: Text('إنشاء مسابقة', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ويدجتات مساعدة داخلية ───

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime) onPicked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null
                    ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
                    : label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final LeaderboardEntry entry;

  String get _medal {
    switch (entry.rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: entry.rank <= 3
            ? AppColors.gold.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(
          color: entry.rank <= 3
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: _medal.isNotEmpty
                ? Text(_medal, style: const TextStyle(fontSize: 20))
                : Text(
                    '${entry.rank}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.childName,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${entry.totalPoints} نقطة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
