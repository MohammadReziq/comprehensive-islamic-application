import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/shared_dashboard_widgets.dart';
import '../../../../models/mosque_model.dart';
import '../../../../models/other_models.dart';

/// قسم الهيرو العلوي — كود المسجد، كود الدعوة، طلبات الانضمام.
class ImamHeroSection extends StatelessWidget {
  const ImamHeroSection({
    super.key,
    required this.mosque,
    required this.nextPrayer,
    required this.pendingCount,
    required this.onJoinRequestsTap,
  });

  final MosqueModel mosque;
  final dynamic nextPrayer;
  final int pendingCount;
  final VoidCallback onJoinRequestsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B4F80), Color(0xFF2D7DD2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Row ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لوحة مدير المسجد',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        mosque.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              DashboardPrayerCard(nextPrayer: nextPrayer),
              const SizedBox(height: 14),
              // ─── Info Row ───
              Row(
                children: [
                  Expanded(
                    child: DashboardHeroInfoChip(
                      icon: Icons.tag_rounded,
                      label: 'كود المسجد',
                      value: mosque.code,
                      trailingIcon: Icons.copy_rounded,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: mosque.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ كود المسجد'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DashboardHeroInfoChip(
                      icon: Icons.link_rounded,
                      label: 'كود الدعوة',
                      value: mosque.inviteCode,
                      trailingIcon: Icons.copy_rounded,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: mosque.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ كود الدعوة'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DashboardHeroInfoChip(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'طلبات الانضمام',
                      value:
                          pendingCount > 0 ? '$pendingCount طلب' : 'لا يوجد',
                      onTap: onJoinRequestsTap,
                      trailingIcon:
                          pendingCount > 0 ? Icons.circle : null,
                      accentColor: pendingCount > 0
                          ? const Color(0xFFFFB74D)
                          : null,
                      hasBadge: pendingCount > 0,
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
}
