import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/smart_location_manager.dart';
import '../../../../injection_container.dart';

/// بطاقة الصلاة القادمة — تصميم مضغوط (صف واحد) مع نقر لعرض كل المواقيت
class ChildViewPrayerCard extends StatefulWidget {
  const ChildViewPrayerCard({super.key});

  @override
  State<ChildViewPrayerCard> createState() => _ChildViewPrayerCardState();
}

class _ChildViewPrayerCardState extends State<ChildViewPrayerCard> {
  PrayerInfo? _nextPrayer;
  Timer? _timer;
  double? _lat;
  double? _lng;
  bool _loading = true;
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    final saved = await SmartLocationManager.getSavedLocation();
    if (saved.lat == null || saved.lng == null) {
      if (mounted) setState(() { _loading = false; _locationError = true; });
      return;
    }
    _lat = saved.lat;
    _lng = saved.lng;

    final service = sl<PrayerTimesService>();
    final ok = await service.loadTimingsFor(_lat!, _lng!);
    if (!mounted) return;

    if (ok) {
      _updateNextPrayer();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) _updateNextPrayer();
      });
    }
    setState(() => _loading = false);
  }

  void _updateNextPrayer() {
    if (_lat == null || _lng == null) return;
    final info = sl<PrayerTimesService>().getNextPrayerOrNull(_lat!, _lng!);
    if (mounted) setState(() => _nextPrayer = info);
  }

  IconData _iconFor(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return Icons.nightlight_round;
      case Prayer.dhuhr: return Icons.wb_sunny_rounded;
      case Prayer.asr: return Icons.wb_twilight;
      case Prayer.maghrib: return Icons.nights_stay_rounded;
      case Prayer.isha: return Icons.dark_mode_rounded;
    }
  }

  List<Color> _gradientFor(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return [const Color(0xFF1B2838), const Color(0xFF5C8BFF)];
      case Prayer.dhuhr: return [const Color(0xFFE8A317), const Color(0xFFFFD54F)];
      case Prayer.asr: return [const Color(0xFFD35400), const Color(0xFFF0A04B)];
      case Prayer.maghrib: return [const Color(0xFF922B21), const Color(0xFFE74C3C)];
      case Prayer.isha: return [const Color(0xFF0A1628), const Color(0xFF2C3E50)];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildShimmer();
    if (_locationError || _nextPrayer == null) return const SizedBox.shrink();

    final prayer = _nextPrayer!;
    final remaining = prayer.time != null
        ? prayer.time!.difference(DateTime.now())
        : null;
    final remainingText = remaining != null && !remaining.isNegative
        ? PrayerTimesService.formatRemaining(remaining)
        : null;
    final gradient = _gradientFor(prayer.prayer);

    return GestureDetector(
      onTap: () {
        context.push('/prayer-times', extra: {'lat': _lat!, 'lng': _lng!});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة الصلاة
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(prayer.prayer),
                color: const Color(0xFFFFD54F),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // اسم الصلاة والوقت
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${prayer.nameAr}  ${prayer.timeFormatted}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (remainingText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '⏳ باقي $remainingText',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // سهم للدلالة على إمكانية الضغط
            Icon(
              Icons.chevron_left_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade100, Colors.grey.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
