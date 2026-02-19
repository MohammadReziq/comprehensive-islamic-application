import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../injection_container.dart';
import '../../presentation/bloc/imam_bloc.dart';
import '../../presentation/bloc/imam_event.dart';
import '../../presentation/bloc/imam_state.dart';
import '../widgets/imam_stat_card.dart';

/// شاشة تقرير الحضور للإمام — فلتر تواريخ + ملخص + قائمة مجمّعة
class ImamAttendanceReportScreen extends StatefulWidget {
  const ImamAttendanceReportScreen({super.key, required this.mosqueId});

  final String mosqueId;

  @override
  State<ImamAttendanceReportScreen> createState() =>
      _ImamAttendanceReportScreenState();
}

class _ImamAttendanceReportScreenState
    extends State<ImamAttendanceReportScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  List<Map<String, dynamic>>? _records;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    _fetchReport();
  }

  void _fetchReport() {
    context.read<ImamBloc>().add(
      LoadAttendanceReport(
        mosqueId: widget.mosqueId,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }

  // ─── حسابات الملخص ───

  int get _totalRecords => _records?.length ?? 0;

  int get _distinctChildren {
    if (_records == null) return 0;
    return _records!.map((r) => r['child_id']).toSet().length;
  }

  String get _topDay {
    if (_records == null || _records!.isEmpty) return '—';
    final counts = <String, int>{};
    for (final r in _records!) {
      final d = r['prayer_date'] as String? ?? '';
      counts[d] = (counts[d] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ─── تجميع حسب prayer_date ───
  Map<String, List<Map<String, dynamic>>> get _groupedByDate {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in (_records ?? [])) {
      final d = r['prayer_date'] as String? ?? '';
      map.putIfAbsent(d, () => []).add(r);
    }
    // ترتيب تنازلي
    final sorted = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showFilterSheet() {
    DateTime tempFrom = _fromDate;
    DateTime tempTo = _toDate;

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
        child: StatefulBuilder(
          builder: (ctx, setStateSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.paddingLG,
              AppDimensions.paddingMD,
              AppDimensions.paddingLG,
              MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.paddingXL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                Text(
                  'تصفية التقرير',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                _DateRow(
                  label: 'من',
                  value: tempFrom,
                  onPicked: (d) => setStateSheet(() => tempFrom = d),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                _DateRow(
                  label: 'إلى',
                  value: tempTo,
                  onPicked: (d) => setStateSheet(() => tempTo = d),
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                ElevatedButton(
                  onPressed: () {
                    if (tempTo.isBefore(tempFrom)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تاريخ النهاية قبل البداية',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _fromDate = tempFrom;
                      _toDate = tempTo;
                    });
                    Navigator.of(ctx).pop();
                    _fetchReport();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'تطبيق',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الـ BlocProvider يأتي من الـ Router — لا تنشئ واحداً جديداً هنا وإلا يستمع BlocConsumer لبلوك لم يُرسَل له الحدث
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تقرير الحضور', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
              tooltip: 'تصفية',
            ),
          ],
        ),
        body: BlocConsumer<ImamBloc, ImamState>(
          listener: (context, state) {
            if (state is ImamLoading) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
            if (state is AttendanceReportLoaded) {
              setState(() {
                _records = state.records;
                _loading = false;
              });
            }
            if (state is ImamError) {
              setState(() {
                _error = state.message;
                _loading = false;
              });
            }
          },
          builder: (context, state) {
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_error != null) {
              return _buildError(context);
            }
            return _buildContent(context);
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              _error!,
              style: GoogleFonts.cairo(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            ElevatedButton(
              onPressed: _fetchReport,
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_records == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final grouped = _groupedByDate;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      children: [
        // نطاق التاريخ
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMD,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${_dateStr(_fromDate)}  ←  ${_dateStr(_toDate)}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Text(
                  'تغيير',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMD),

        // بطاقات الملخص
        Row(
          children: [
            Expanded(
              child: ImamStatCard(
                title: 'إجمالي السجلات',
                value: '$_totalRecords',
                icon: Icons.list_alt_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSM),
            Expanded(
              child: ImamStatCard(
                title: 'أطفال مختلفون',
                value: '$_distinctChildren',
                icon: Icons.child_care_outlined,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSM),
            Expanded(
              child: ImamStatCard(
                title: 'أعلى يوم',
                value: _totalRecords > 0 ? _topDay.split('-').last : '—',
                icon: Icons.star_outline,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingLG),

        // القائمة المجمّعة أو حالة فارغة
        if (grouped.isEmpty)
          _buildEmpty()
        else
          ...grouped.entries.map(
            (entry) => _buildDateGroup(entry.key, entry.value),
          ),
      ],
    );
  }

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusRound,
                  ),
                ),
                child: Text(
                  date,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${records.length} سجل',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        ...records.map((r) => _buildRecordRow(r)),
        const SizedBox(height: AppDimensions.spacingMD),
      ],
    );
  }

  Widget _buildRecordRow(Map<String, dynamic> r) {
    final childName = (r['children'] as Map?)?['name'] as String? ?? 'طفل';
    final prayer = r['prayer'] as String? ?? '';
    final prayerName = prayer.isNotEmpty
        ? Prayer.fromString(prayer).nameAr
        : '';
    final points = r['points_earned'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              childName,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: Text(
              prayerName,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$points نقطة',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'لا توجد سجلات للفترة المحددة',
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

// ─── ويدجت مساعد لاختيار التاريخ ───

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime value;
  final void Function(DateTime) onPicked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) onPicked(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
