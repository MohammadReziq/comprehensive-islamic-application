// lib/app/features/corrections/presentation/screens/corrections_list_screen.dart
// شاشة طلبات التصحيح — للمشرف/الإمام

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/correction_bloc.dart';
import '../bloc/correction_event.dart';
import '../bloc/correction_state.dart';

class CorrectionsListScreen extends StatelessWidget {
  final String mosqueId;
  const CorrectionsListScreen({super.key, required this.mosqueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CorrectionBloc>()
        ..add(LoadPendingCorrections(mosqueId)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('طلبات التصحيح'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: BlocConsumer<CorrectionBloc, CorrectionState>(
            listener: (context, state) {
              if (state is CorrectionActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success,
                  ),
                );
                // إعادة تحميل القائمة
                context.read<CorrectionBloc>()
                    .add(LoadPendingCorrections(mosqueId));
              } else if (state is CorrectionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is CorrectionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CorrectionLoaded) {
                if (state.requests.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text('لا توجد طلبات معلقة',
                            style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<CorrectionBloc>()
                        .add(LoadPendingCorrections(mosqueId));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final req = state.requests[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.child_care,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    req.childName ?? req.childId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      req.prayer.nameAr,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'التاريخ: ${DateFormat('yyyy/MM/dd').format(req.prayerDate)}',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              if (req.note != null && req.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'ملاحظة: ${req.note}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showRejectDialog(context, req.id),
                                      icon: const Icon(Icons.close,
                                          color: AppColors.error),
                                      label: const Text('رفض',
                                          style: TextStyle(
                                              color: AppColors.error)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.error),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        context.read<CorrectionBloc>().add(
                                          ApproveCorrection(req.id),
                                        );
                                      },
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
                    },
                  ),
                );
              }
              if (state is CorrectionError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String requestId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (اختياري)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CorrectionBloc>().add(
                RejectCorrection(requestId,
                    reason: controller.text.trim().isEmpty
                        ? null
                        : controller.text.trim()),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
