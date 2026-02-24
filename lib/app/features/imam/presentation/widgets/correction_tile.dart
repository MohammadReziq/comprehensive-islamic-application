import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';

/// ويدجت عرض طلب تصحيح واحد (معلق أو مُعالج)
class CorrectionTile extends StatelessWidget {
  const CorrectionTile({
    super.key,
    required this.correction,
    required this.isPending,
    required this.isLoading,
    this.onApprove,
    this.onReject,
  });

  /// البيانات من DB: children(name), prayer, prayer_date, note, status
  final Map<String, dynamic> correction;
  final bool isPending;
  final bool isLoading;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  String get _childName {
    final children = correction['children'];
    if (children is Map) return children['name'] as String? ?? 'ابن';
    return 'ابن';
  }

  String get _prayerName {
    final p = correction['prayer'] as String?;
    if (p == null) return '';
    return Prayer.fromString(p).nameAr;
  }

  String get _dateStr {
    final d = correction['prayer_date'] as String?;
    return d ?? '';
  }

  String get _note => correction['note'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: BorderSide(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Icon(
                    Icons.edit_calendar_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMD),
                // المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _childName,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_prayerName  •  $_dateStr',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _note,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // trailing
                _buildTrailing(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            tooltip: 'موافقة',
            onTap: onApprove,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            tooltip: 'رفض',
            onTap: onReject,
          ),
        ],
      );
    }

    // حالة مُعالجة
    final status = correction['status'] as String? ?? '';
    final isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: Text(
        isApproved ? 'مقبول ✅' : 'مرفوض ❌',
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isApproved ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}
