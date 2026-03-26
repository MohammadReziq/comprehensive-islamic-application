import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/competition_model.dart';

/// حالة عرض بانر المسابقة
enum CompetitionDisplayState {
  active,   // مسابقة نشطة الآن
  upcoming, // ستبدأ قريباً
  ended,    // انتهت مؤخراً (آخر 7 أيام)
  none,     // لا توجد مسابقات
}

/// بانر المسابقة — 4 حالات مختلفة حسب حالة المسابقة
class CompetitionBannerWidget extends StatelessWidget {
  final CompetitionModel? competition;
  final String? mosqueName;
  final VoidCallback? onViewResults;
  final VoidCallback? onViewDetails;

  const CompetitionBannerWidget({
    super.key,
    this.competition,
    this.mosqueName,
    this.onViewResults,
    this.onViewDetails,
  });

  CompetitionDisplayState get _state {
    if (competition == null) return CompetitionDisplayState.none;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (competition!.isActive) {
      final endDate = competition!.endDate;
      if (endDate.isBefore(today)) {
        return CompetitionDisplayState.ended;
      }
      return CompetitionDisplayState.active;
    }

    // غير نشطة: هل هي قادمة أم منتهية؟
    final startDate = competition!.startDate;
    if (startDate.isAfter(today)) {
      return CompetitionDisplayState.upcoming;
    }

    final endDate = competition!.endDate;
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    if (endDate.isAfter(sevenDaysAgo)) {
      return CompetitionDisplayState.ended;
    }

    return CompetitionDisplayState.none;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      CompetitionDisplayState.active => _buildActiveBanner(context),
      CompetitionDisplayState.upcoming => _buildUpcomingBanner(context),
      CompetitionDisplayState.ended => _buildEndedBanner(context),
      CompetitionDisplayState.none => _buildNoBanner(context),
    };
  }

  // ═══ الحالة 1: مسابقة نشطة ═══
  Widget _buildActiveBanner(BuildContext context) {
    final daysLeft = competition!.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  competition!.nameAr,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (mosqueName != null) ...[
            const SizedBox(height: 4),
            Text('مسجد $mosqueName',
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(
                daysLeft > 0
                    ? 'باقي $daysLeft ${daysLeft == 1 ? "يوم" : "أيام"}'
                    : 'آخر يوم اليوم!',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight:
                      daysLeft <= 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewDetails,
                child: Text('التفاصيل',
                    style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══ الحالة 2: مسابقة قادمة ═══
  Widget _buildUpcomingBanner(BuildContext context) {
    final daysUntil = competition!.startDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(competition!.nameAr,
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(
                  'تبدأ بعد $daysUntil ${daysUntil == 1 ? "يوم" : "أيام"}',
                  style:
                      GoogleFonts.cairo(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══ الحالة 3: مسابقة منتهية ═══
  Widget _buildEndedBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('انتهت ${competition!.nameAr}',
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.grey.shade700)),
                Text('اطلع على النتائج والترتيب',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onViewResults,
            icon: const Icon(Icons.leaderboard, size: 18),
            label: const Text('النتائج'),
          ),
        ],
      ),
    );
  }

  // ═══ الحالة 4: لا توجد مسابقات ═══
  Widget _buildNoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.mosque_outlined, color: AppColors.primaryLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text('تابع حضور أطفالك للصلاة',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
