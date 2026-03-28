import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../models/child_model.dart';

/// بيانات مسجد مرتبط بالابن
class MosqueLink {
  const MosqueLink({
    required this.mosqueId,
    required this.mosqueName,
    required this.type,
    required this.localNumber,
  });
  final String mosqueId;
  final String mosqueName;
  final MosqueType type;
  final int localNumber;
}

/// بطاقة QR + كود النص + زر المشاركة + الرقم المحلي
class ChildQrCard extends StatelessWidget {
  final ChildModel child;
  final List<MosqueLink> linkedMosques;

  const ChildQrCard({super.key, required this.child, required this.linkedMosques});

  @override
  Widget build(BuildContext context) {
    final primaryMosque = linkedMosques.isNotEmpty
        ? linkedMosques.firstWhere(
            (m) => m.type == MosqueType.primary,
            orElse: () => linkedMosques.first,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          const Text('بطاقة الابن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
          const SizedBox(height: 4),
          Text('يمكن للمشرف مسح هذا الكود لتسجيل الحضور', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          QrImageView(data: child.qrCode, version: QrVersions.auto, size: 180, backgroundColor: Colors.white),
          const SizedBox(height: 16),
          _buildCopyableCode(context),
          const SizedBox(height: 10),
          _buildShareButton(primaryMosque),
          if (primaryMosque != null && primaryMosque.localNumber > 0) ...[
            const SizedBox(height: 10),
            _buildLocalNumber(context, primaryMosque),
          ],
        ],
      ),
    );
  }

  Widget _buildCopyableCode(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: child.qrCode));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ الكود'), behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(child.qrCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(width: 8),
            const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(MosqueLink? primaryMosque) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final numberLine = (primaryMosque != null && primaryMosque.localNumber > 0)
              ? '\nرقمه في ${primaryMosque.mosqueName}: ${primaryMosque.localNumber.toString().padLeft(3, '0')}'
              : '';
          Share.share(
            'بطاقة ${child.name} — صلاتي حياتي\n'
            'كود QR: ${child.qrCode}'
            '$numberLine\n\n'
            'أعطِ هذا الكود للمشرف لتسجيل الحضور.',
            subject: 'بطاقة ${child.name}',
          );
        },
        icon: const Icon(Icons.share_rounded, size: 18),
        label: const Text('مشاركة البطاقة مع المشرف'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _buildLocalNumber(BuildContext context, MosqueLink mosque) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: '${mosque.localNumber}'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ الرقم'), behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2E8B57).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tag_rounded, size: 16, color: Color(0xFF2E8B57)),
            const SizedBox(width: 6),
            Text(
              'رقمه في ${mosque.mosqueName}: ${mosque.localNumber.toString().padLeft(3, '0')}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E8B57)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2E8B57)),
          ],
        ),
      ),
    );
  }
}
