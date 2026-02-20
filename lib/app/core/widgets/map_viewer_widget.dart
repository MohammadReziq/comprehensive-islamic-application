// عرض نقاط (مساجد) على خريطة — للقراءة فقط

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_colors.dart';

/// نقطة للعرض على الخريطة (مسجد أو غيره)
class MapViewerPoint {
  const MapViewerPoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.status,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  /// للحصول على لون مختلف: 'approved' | 'pending' | 'rejected'
  final String? status;

  LatLng get position => LatLng(lat, lng);
}

/// ويدجت خريطة يعرض قائمة نقاط (مساجد) مع تسميات.
/// المساجد بدون إحداثيات لا تُمرَّر هنا — تُعرض في قائمة منفصلة إن أردت.
class MapViewerWidget extends StatelessWidget {
  const MapViewerWidget({
    super.key,
    required this.points,
    this.height,
    this.initialZoom = 10,
    this.onTapPoint,
  });

  final List<MapViewerPoint> points;
  final double? height;
  final double initialZoom;
  final void Function(MapViewerPoint)? onTapPoint;

  static const _defaultCenter = LatLng(31.9454, 35.9284); // عمان

  LatLng get _center {
    if (points.isEmpty) return _defaultCenter;
    double sumLat = 0, sumLng = 0;
    for (final p in points) {
      sumLat += p.lat;
      sumLng += p.lng;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  Color _colorForStatus(String? status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = FlutterMap(
      options: MapOptions(
        initialCenter: _center,
        initialZoom: initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.salati_hayati.app',
        ),
        if (points.isNotEmpty)
          MarkerLayer(
            markers: points.map((p) {
              return Marker(
                point: p.position,
                width: 36,
                height: 36,
                child: GestureDetector(
                  onTap: () => onTapPoint?.call(p),
                  child: Icon(
                    Icons.location_on,
                    color: _colorForStatus(p.status),
                    size: 36,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: child);
    }
    return child;
  }
}
