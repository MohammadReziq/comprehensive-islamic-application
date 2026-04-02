import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../corrections/presentation/bloc/correction_bloc.dart';
import '../../../corrections/presentation/bloc/correction_event.dart';
import '../../../corrections/presentation/bloc/correction_state.dart';
import '../../../corrections/presentation/widgets/correction_request_card.dart';

/// شاشة طلبات التصحيح — للمشرف/الإمام.
class CorrectionsListScreen extends StatelessWidget {
  const CorrectionsListScreen({
    super.key,
    required this.mosqueId,
    this.reviewerRole = 'imam',
  });

  final String mosqueId;
  final String reviewerRole;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CorrectionBloc>()..add(LoadPendingCorrections(mosqueId)),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ));
                context
                    .read<CorrectionBloc>()
                    .add(LoadPendingCorrections(mosqueId));
              } else if (state is CorrectionError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ));
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
                        Text(
                          'لا توجد طلبات معلقة',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<CorrectionBloc>()
                      .add(LoadPendingCorrections(mosqueId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => CorrectionRequestCard(
                      request: state.requests[i],
                      mosqueId: mosqueId,
                    ),
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
}
