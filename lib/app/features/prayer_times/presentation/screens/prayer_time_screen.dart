import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../injection_container.dart';

/// شاشة مواقيت الصلاة كاملة حسب الموقع (Aladhan API)
/// إذا lat أو lng null تُعرض رسالة طلب تفعيل الموقع.
class PrayerTimeScreen extends StatefulWidget {
  final double? lat;
  final double? lng;

  const PrayerTimeScreen({
    super.key,
    this.lat,
    this.lng,
  });

  @override
  State<PrayerTimeScreen> createState() => _PrayerTimeScreenState();
}

class _PrayerTimeScreenState extends State<PrayerTimeScreen> {
  bool _loading = true;
  Map<Prayer, DateTime>? _timings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }

  Future<void> _loadTimings() async {
    final lat = widget.lat;
    final lng = widget.lng;
    if (lat == null || lng == null) {
      if (mounted) setState(() { _loading = false; _error = null; });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await sl<PrayerTimesService>().loadTimingsFor(lat, lng);
    if (!mounted) return;
    final raw = ok ? sl<PrayerTimesService>().getTodayPrayerTimesRaw(lat, lng) : null;
    if (mounted) {
      setState(() {
        _timings = raw;
        _loading = false;
        if (!ok) _error = 'تحقق من الاتصال بالإنترنت';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('مواقيت الصلاة'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: widget.lat == null || widget.lng == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'الرجاء تشغيل الموقع حتى نعرف مواقيت الصلاة',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              )
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'تعذّر جلب المواقيت',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تأكد من الاتصال بالإنترنت وحاول مرة أخرى',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _loadTimings,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTimings,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        ...Prayer.values.map((p) => _buildPrayerRow(p)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    final lat = widget.lat!;
    final lng = widget.lng!;
    final next = sl<PrayerTimesService>().getNextPrayerOrNull(lat, lng);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text(
              'الصلاة القادمة: ${next.nameAr}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              next.timeFormatted,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFD54F),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerRow(Prayer prayer) {
    final time = _timings?[prayer];
    if (time == null) return const SizedBox.shrink();
    final formatted = DateFormat('hh:mm a', 'ar').format(time);
    final now = DateTime.now();
    final isPassed = now.isAfter(time);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              color: (isPassed ? Colors.grey : AppColors.primary).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: isPassed ? Colors.grey : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer.nameAr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isPassed ? Colors.grey : const Color(0xFF1A2B3C),
                  ),
                ),
                if (isPassed)
                  Text(
                    'مرّ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isPassed ? Colors.grey : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
