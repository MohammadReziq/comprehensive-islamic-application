import 'package:flutter/material.dart';
import '../../../../core/constants/hadiths_prayer.dart';
import 'package:go_router/go_router.dart';

/// قسم Hero: مواقيت الصلاة + بطاقة الحديث
class HomeHeroSection extends StatelessWidget {
  final dynamic nextPrayer;
  final double? lat;
  final double? lng;
  final bool loadingPrayer;
  final bool prayerLoadError;
  final int hadithIndex;
  final VoidCallback onRetryPrayer;
  final VoidCallback onNextHadith;

  const HomeHeroSection({
    super.key,
    required this.nextPrayer,
    this.lat,
    this.lng,
    required this.loadingPrayer,
    required this.prayerLoadError,
    required this.hadithIndex,
    required this.onRetryPrayer,
    required this.onNextHadith,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrayerSection(context),
              const SizedBox(height: 14),
              _buildHadithCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerSection(BuildContext context) {
    if (loadingPrayer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'جاري جلب مواقيت الصلاة...',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    if (lat == null || lng == null) {
      return _buildMessageCard(
        icon: Icons.location_off_rounded,
        message: 'الرجاء تشغيل الموقع حتى نعرف مواقيت الصلاة',
        onTap: onRetryPrayer,
      );
    }
    if (prayerLoadError) {
      return _buildMessageCard(
        icon: Icons.wifi_off_rounded,
        message: 'تحقق من الاتصال بالإنترنت ثم أعد المحاولة',
        onTap: onRetryPrayer,
      );
    }
    if (nextPrayer != null) {
      return _buildPrayerCard(context, nextPrayer, lat!, lng!);
    }
    return _buildMessageCard(
      icon: Icons.refresh_rounded,
      message: 'لم تُحمّل المواقيت — اضغط للمحاولة',
      onTap: onRetryPrayer,
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String message,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCountdown(Duration? remaining) {
    if (remaining == null) return '—';
    if (remaining.isNegative) return 'الآن';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildPrayerCard(BuildContext context, dynamic nextPrayer, double lat, double lng) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    Duration? remaining = nextPrayer?.remaining;
    if (remaining != null && remaining.isNegative) remaining = Duration.zero;
    final countdownText = _formatCountdown(remaining);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/prayer-times', extra: {'lat': lat, 'lng': lng}),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text(
                      '$nameAr  $timeFormatted',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (countdownText != '—')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)),
                  ),
                  child: Text(
                    countdownText == 'الآن' ? countdownText : 'بعد $countdownText',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD54F)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHadithCard() {
    final list = HadithPrayer.list;
    if (list.isEmpty) return const SizedBox.shrink();
    final hadith = list[hadithIndex % list.length];
    return GestureDetector(
      onTap: onNextHadith,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    hadith.text,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, height: 1.45),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hadith.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.shuffle_on_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
