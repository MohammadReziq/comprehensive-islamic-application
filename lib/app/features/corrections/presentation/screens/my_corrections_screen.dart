// شاشة "طلباتي" — طلبات التصحيح التي أرسلها ولي الأمر

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../../../models/correction_request_model.dart';
import '../../../../core/constants/app_enums.dart';
import '../bloc/correction_bloc.dart';
import '../bloc/correction_event.dart';
import '../bloc/correction_state.dart';

class MyCorrectionsScreen extends StatelessWidget {
  const MyCorrectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CorrectionBloc>()..add(const LoadMyCorrections()),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('طلبات التصحيح'),
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: BlocBuilder<CorrectionBloc, CorrectionState>(
            builder: (context, state) {
              if (state is CorrectionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CorrectionError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              if (state is CorrectionLoaded) {
                if (state.requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات تصحيح',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<CorrectionBloc>().add(const LoadMyCorrections());
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final req = state.requests[i];
                      return _RequestCard(request: req);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final CorrectionRequestModel request;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  request.childName ?? 'ابن',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.nameAr,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${request.prayer.nameAr} — ${DateFormat('yyyy/MM/dd').format(request.prayerDate)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                request.note!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(CorrectionStatus status) {
    switch (status) {
      case CorrectionStatus.pending:
        return Colors.orange;
      case CorrectionStatus.approved:
        return AppColors.success;
      case CorrectionStatus.rejected:
        return AppColors.error;
    }
  }
}
