import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/imam_repository.dart';
import '../../../supervisor/data/repositories/supervisor_repository.dart';
import '../widgets/imam_stat_card.dart';
import '../widgets/supervisor_performance_tile.dart';

/// شاشة أداء المشرفين — عدد سجلات الحضور اليوم لكل مشرف
class ImamSupervisorsPerformanceScreen extends StatefulWidget {
  const ImamSupervisorsPerformanceScreen({super.key, required this.mosqueId});

  final String mosqueId;

  @override
  State<ImamSupervisorsPerformanceScreen> createState() =>
      _ImamSupervisorsPerformanceScreenState();
}

class _ImamSupervisorsPerformanceScreenState
    extends State<ImamSupervisorsPerformanceScreen> {
  List<Map<String, dynamic>>? _supervisors;
  int? _totalStudents;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        sl<ImamRepository>().getSupervisorsPerformance(widget.mosqueId),
        sl<SupervisorRepository>().getMosqueStudents(widget.mosqueId),
      ]);

      final supervisors = results[0] as List<Map<String, dynamic>>;
      final students = results[1] as List;

      // ترتيب تنازلي حسب عدد التسجيلات
      supervisors.sort(
        (a, b) =>
            (b['today_records'] as int).compareTo(a['today_records'] as int),
      );

      if (mounted) {
        setState(() {
          _supervisors = supervisors;
          _totalStudents = students.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  int get _totalRecordsToday =>
      _supervisors?.fold<int>(
        0,
        (sum, s) => sum + (s['today_records'] as int),
      ) ??
      0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('أداء المشرفين', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
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
              onPressed: _load,
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final supervisors = _supervisors ?? [];

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      children: [
        // ملاحظة التاريخ
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
          child: Text(
            'اليوم — $_todayStr',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // بطاقات الإحصاء
        Row(
          children: [
            Expanded(
              child: ImamStatCard(
                title: 'إجمالي المشرفين',
                value: '${supervisors.length}',
                icon: Icons.people_outline,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMD),
            Expanded(
              child: ImamStatCard(
                title: 'تسجيلات اليوم',
                value: '$_totalRecordsToday',
                icon: Icons.how_to_reg_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingLG),

        // القائمة
        if (supervisors.isEmpty)
          _buildEmpty()
        else
          ...supervisors.map(
            (s) => SupervisorPerformanceTile(
              name: s['name'] as String? ?? 'مشرف',
              email: null,
              todayRecords: s['today_records'] as int? ?? 0,
              totalStudents: _totalStudents ?? 0,
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 56, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'لا يوجد مشرفون في هذا المسجد',
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
