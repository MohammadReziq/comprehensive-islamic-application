import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../../corrections/presentation/bloc/correction_bloc.dart';
import '../../../corrections/presentation/bloc/correction_event.dart';
import '../../../corrections/presentation/bloc/correction_state.dart';
import '../../../corrections/presentation/widgets/my_correction_card.dart';

/// شاشة "طلباتي" — طلبات التصحيح التي أرسلها ولي الأمر.
class MyCorrectionsScreen extends StatelessWidget {
  const MyCorrectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CorrectionBloc>()..add(const LoadMyCorrections()),
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
                        Icon(Icons.error_outline,
                            size: 56, color: Colors.red.shade300),
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
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات تصحيح',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<CorrectionBloc>()
                      .add(const LoadMyCorrections()),
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.all(AppDimensions.paddingLG),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        MyCorrectionCard(request: state.requests[i]),
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
