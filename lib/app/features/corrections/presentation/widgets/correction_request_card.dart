import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../models/correction_request_model.dart';
import '../bloc/correction_bloc.dart';
import '../bloc/correction_event.dart';
import '../bloc/correction_state.dart';
import 'reject_correction_dialog.dart';

/// بطاقة طلب تصحيح واحد — للإمام/المشرف — مع زرا الرفض/الموافقة.
class CorrectionRequestCard extends StatelessWidget {
  const CorrectionRequestCard({
    super.key,
    required this.request,
    required this.mosqueId,
  });

  final CorrectionRequestModel request;
  final String mosqueId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── اسم الطالب + الصلاة ───
            Row(
              children: [
                const Icon(Icons.child_care,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  request.childName ?? request.childId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _PrayerBadge(prayer: request.prayer.nameAr),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'التاريخ: ${DateFormat('yyyy/MM/dd').format(request.prayerDate)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'ملاحظة: ${request.note}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // ─── أزرار الرفض/الموافقة ───
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text(
                      'رفض',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context
                        .read<CorrectionBloc>()
                        .add(ApproveCorrection(request.id)),
                    icon: const Icon(Icons.check),
                    label: const Text('موافقة'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RejectCorrectionDialog(
        requestId: request.id,
        mosqueId: mosqueId,
      ),
    );
  }
}

class _PrayerBadge extends StatelessWidget {
  const _PrayerBadge({required this.prayer});
  final String prayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        prayer,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
