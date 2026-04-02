import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/correction_bloc.dart';
import '../bloc/correction_event.dart';

/// Dialog إدخال سبب الرفض لطلب التصحيح.
class RejectCorrectionDialog extends StatefulWidget {
  const RejectCorrectionDialog({
    super.key,
    required this.requestId,
    required this.mosqueId,
  });

  final String requestId;
  final String mosqueId;

  @override
  State<RejectCorrectionDialog> createState() =>
      _RejectCorrectionDialogState();
}

class _RejectCorrectionDialogState extends State<RejectCorrectionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رفض الطلب'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(
          hintText: 'سبب الرفض (اختياري)',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<CorrectionBloc>().add(
                  RejectCorrection(
                    widget.requestId,
                    reason: _ctrl.text.trim().isEmpty
                        ? null
                        : _ctrl.text.trim(),
                  ),
                );
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('رفض'),
        ),
      ],
    );
  }
}
