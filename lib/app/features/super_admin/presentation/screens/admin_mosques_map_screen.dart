import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/map_viewer_widget.dart';
import '../../../../models/mosque_model.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

/// شاشة خريطة مساجد السوبر أدمن — تعرض كل المساجد التي لديها إحداثيات.
class AdminMosquesMapScreen extends StatelessWidget {
  const AdminMosquesMapScreen({super.key});

  static List<MapViewerPoint> _mosquesToPoints(List<MosqueModel> mosques) {
    return mosques
        .where((m) => m.lat != null && m.lng != null)
        .map((m) => MapViewerPoint(
              id: m.id,
              name: m.name,
              lat: m.lat!,
              lng: m.lng!,
              status: m.status.value,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة المساجد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is! MosquesLoaded) {
            context.read<AdminBloc>().add(const LoadAllMosques());
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final points = _mosquesToPoints(state.mosques);
          if (points.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد مساجد ذات موقع على الخريطة.\nحدّث مواقع المساجد من قائمة المساجد.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return MapViewerWidget(
            points: points,
            initialZoom: 9,
            onTapPoint: (p) {
              // يمكن لاحقاً فتح bottom sheet أو تفاصيل المسجد
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(p.name)),
              );
            },
          );
        },
      ),
    );
  }
}
