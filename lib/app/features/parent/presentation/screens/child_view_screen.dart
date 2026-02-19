import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../data/repositories/child_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// شاشة عرض الابن (دور child) — قراءة فقط: الاسم، الباركود، حضور اليوم، النقاط
class ChildViewScreen extends StatefulWidget {
  const ChildViewScreen({super.key});

  @override
  State<ChildViewScreen> createState() => _ChildViewScreenState();
}

class _ChildViewScreenState extends State<ChildViewScreen> {
  ChildModel? _child;
  List<AttendanceModel> _todayAttendance = [];
  bool _loading = true;
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
      final user = await sl<AuthRepository>().getCurrentUserProfile();
      if (user == null) {
        setState(() {
          _error = 'لم يتم العثور على الجلسة';
          _loading = false;
        });
        return;
      }
      final child = await sl<ChildRepository>().getChildByLoginUserId(user.id);
      if (child == null) {
        setState(() {
          _error = 'لا يوجد طفل مرتبط بهذا الحساب';
          _loading = false;
        });
        return;
      }
      final today = await sl<ChildRepository>()
          .getAttendanceForChildOnDate(child.id, DateTime.now());
      setState(() {
        _child = child;
        _todayAttendance = today;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: AppDimensions.paddingMD),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _child == null
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimensions.paddingLG),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCard('الاسم', _child!.name, Icons.person),
                            const SizedBox(height: AppDimensions.paddingMD),
                            _buildQrCard(),
                            const SizedBox(height: AppDimensions.paddingMD),
                            _buildCard(
                              'النقاط الإجمالية',
                              '${_child!.totalPoints}',
                              Icons.star,
                            ),
                            const SizedBox(height: AppDimensions.paddingMD),
                            _buildTodayAttendance(),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2, color: AppColors.primary),
                const SizedBox(width: AppDimensions.paddingMD),
                Text(
                  'الباركود',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              _child!.qrCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _child!.qrCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ الباركود'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('نسخ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendance() {
    final dateStr = DateTime.now().toString().substring(0, 10);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: AppColors.primary),
                const SizedBox(width: AppDimensions.paddingMD),
                Text(
                  'حضور اليوم ($dateStr)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_todayAttendance.isEmpty)
              const Text('لا يوجد حضور مسجّل لليوم')
            else
              ..._todayAttendance.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(a.prayer.nameAr),
                        const SizedBox(width: 8),
                        Text(
                          '+${a.pointsEarned}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
