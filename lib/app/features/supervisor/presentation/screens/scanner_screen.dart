import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/attendance_validation_service.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../models/mosque_model.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';

/// شاشة التحضير: مسح QR، إدخال رقم، قائمة الطلاب
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  int _selectedTab = 0;
  final _numberController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadIfNeeded(BuildContext context) {
    final mosqueState = context.read<MosqueBloc>().state;
    if (mosqueState is! MosqueLoaded) return;
    final approved = mosqueState.mosques.where((m) => m.status == MosqueStatus.approved).firstOrNull;
    if (approved == null) return;

    final lat = approved.lat;
    final lng = approved.lng;
    if (lat == null || lng == null) return;

    sl<PrayerTimesService>().loadTimingsFor(lat, lng).then((_) {
      if (!context.mounted) return;
      final nextPrayer = sl<PrayerTimesService>().getNextPrayerOrNull(lat, lng);
      if (nextPrayer == null) return;
      final date = DateTime.now();
      context.read<ScannerBloc>().add(ScannerLoad(
            mosqueId: approved.id,
            prayer: nextPrayer.prayer,
            date: date,
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التحضير'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocConsumer<ScannerBloc, ScannerState>(
          listener: (context, state) {
            if (state is ScannerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is ScannerReady && state.scanMessage != null) {
              final isSuccess = state.scanMessage == 'تم تسجيل الحضور';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.scanMessage!),
                  backgroundColor: isSuccess ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ScannerInitial || state is ScannerLoading) {
              final mosqueState = context.read<MosqueBloc>().state;
              MosqueModel? approved;
              if (mosqueState is MosqueLoaded) {
                approved = mosqueState.mosques
                    .where((m) => m.status == MosqueStatus.approved)
                    .firstOrNull;
              }
              if (approved != null && (approved.lat == null || approved.lng == null)) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          'أضف إحداثيات المسجد لاستخدام التحضير',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is ScannerInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded(context));
              }
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ScannerError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: AppDimensions.paddingMD),
                      ElevatedButton(
                        onPressed: () => _loadIfNeeded(context),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is! ScannerReady) return const SizedBox.shrink();

            return Column(
              children: [
                _buildPrayerChip(state.prayer.nameAr),
                _buildRecordingWindowBanner(context, state),
                _TabBar(
                  currentIndex: _selectedTab,
                  tabs: const [
                    _Tab(icon: Icons.qr_code_scanner, label: 'QR'),
                    _Tab(icon: Icons.pin, label: 'رقم'),
                    _Tab(icon: Icons.list, label: 'قائمة'),
                  ],
                  onTap: (i) => setState(() => _selectedTab = i),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _buildQrTab(context, state),
                      _buildNumberTab(context, state),
                      _buildListTab(context, state),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrayerChip(String prayerName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSM),
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          'تحضير $prayerName',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingWindowBanner(BuildContext context, ScannerReady state) {
    final mosqueState = context.read<MosqueBloc>().state;
    if (mosqueState is! MosqueLoaded) return const SizedBox.shrink();
    final mosque = mosqueState.mosques.where((m) => m.status == MosqueStatus.approved).firstOrNull;
    if (mosque == null) return const SizedBox.shrink();

    final windowMin = mosque.attendanceWindowMinutes;
    return FutureBuilder<RecordingWindowStatus>(
      future: sl<AttendanceValidationService>().getRecordingWindowStatus(
        prayer: state.prayer,
        date: state.date,
        lat: mosque.lat,
        lng: mosque.lng,
        windowMinutes: windowMin,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final status = snapshot.data!;
        final isAllowed = status.allowed;
        final isExpired = status.remainingMinutes == 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: isAllowed
              ? AppColors.successLight
              : (isExpired ? AppColors.errorLight : AppColors.warningLight),
          child: Row(
            children: [
              Icon(
                isAllowed ? Icons.timer_outlined : (isExpired ? Icons.block : Icons.info_outline),
                size: 20,
                color: isAllowed ? AppColors.success : (isExpired ? AppColors.error : AppColors.warning),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isAllowed ? AppColors.success : (isExpired ? AppColors.error : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrTab(BuildContext context, ScannerReady state) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.paddingMD),
        Text(
          'امسح بطاقة الطالب',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              child: MobileScanner(
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  for (final b in barcodes) {
                    final code = b.rawValue;
                    if (code != null && code.isNotEmpty) {
                      context.read<ScannerBloc>().add(ScannerScanQr(code));
                      break;
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberTab(BuildContext context, ScannerReady state) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        children: [
          TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'رقم الطالب',
              hintText: 'أدخل الرقم المحلي',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final n = int.tryParse(_numberController.text.trim());
                if (n != null) {
                  context.read<ScannerBloc>().add(ScannerRecordByNumber(n));
                  _numberController.clear();
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('تسجيل الحضور'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(BuildContext context, ScannerReady state) {
    final search = _searchController.text.trim().toLowerCase();
    final list = search.isEmpty
        ? state.students
        : state.students.where((s) => s.child.name.toLowerCase().contains(search)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingSM),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'بحث بالاسم',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('لا يوجد طلاب'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final s = list[i];
                    final recorded = state.isRecorded(s.child.id);
                    return ListTile(
                      title: Text(s.child.name),
                      subtitle: Text('رقم ${s.localNumber}'),
                      trailing: recorded
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : TextButton(
                              onPressed: () {
                                context.read<ScannerBloc>().add(ScannerRecordAttendance(s.child.id));
                              },
                              child: const Text('حاضر'),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Tab {
  const _Tab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final t = tabs[i];
        final selected = i == currentIndex;
        return Expanded(
          child: InkWell(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 24, color: selected ? AppColors.primary : Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? AppColors.primary : Colors.grey,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
